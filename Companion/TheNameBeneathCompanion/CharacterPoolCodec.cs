using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;

namespace TheNameBeneath.Companion;

// Independent, bounded UE3 tagged-property reader. Character records are copied
// verbatim, not re-created from a subset of cosmetic fields. No utility code/dependency.
internal static class CharacterPoolCodec
{
    internal const int MaxCharacters = 10_000;
    internal sealed record ExtraData(ReadOnlyMemory<byte> Bytes, string CharacterKey, string ContentKey, int ObjectIdOffset);
    internal sealed record Pool(IReadOnlyList<ReadOnlyMemory<byte>> Characters, IReadOnlyList<ExtraData> Extras);
    private sealed record Tag(string Name, string Type, int Size, int Data, int End,
        int ArrayIndex = 0, string Structure = "", IReadOnlyList<Tag>? Fields = null, int Start = 0);

    private sealed class Reader(byte[] bytes, CancellationToken cancel)
    {
        internal int Position;
        private int properties;
        internal int Int()
        {
            Need(4);
            int value = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(Position, 4));
            Position += 4;
            return value;
        }
        private void Need(int count)
        {
            if (count < 0 || count > bytes.Length - Position) throw new BridgeError("pool_file_invalid");
        }
        private string String(bool identifier)
        {
            int length = Int();
            if (length == 0) return "";
            if (length == int.MinValue || Math.Abs(length) > (identifier ? 256 : 1_048_576)) throw new BridgeError("pool_file_invalid");
            int count = checked(Math.Abs(length) * (length < 0 ? 2 : 1));
            Need(count);
            if (bytes[Position + count - 1] != 0 || (length < 0 && bytes[Position + count - 2] != 0)) throw new BridgeError("pool_file_invalid");
            string result = length < 0
                ? new UnicodeEncoding(false, false, true).GetString(bytes, Position, count - 2)
                : Encoding.Latin1.GetString(bytes, Position, count - 1);
            Position += count;
            if (identifier && (result.Length == 0 || result.Any(c => !(char.IsAsciiLetterOrDigit(c) || c == '_')))) throw new BridgeError("pool_file_invalid");
            return result;
        }
        private string Name()
        {
            string name = String(true);
            if (Int() != 0) throw new BridgeError("pool_format_unsupported"); // numbered property tags are not standard pool data
            return name;
        }
        internal Tag ReadTag()
        {
            cancel.ThrowIfCancellationRequested();
            if (++properties > 500_000) throw new BridgeError("pool_file_invalid");
            int start = Position;
            string name = Name();
            if (name == "None") return new Tag(name, "", 0, Position, Position);
            string type = Name();
            int size = Int(), arrayIndex = Int();
            if (size < 0 || arrayIndex < 0) throw new BridgeError("pool_file_invalid");
            string structure = "";
            if (type is "StructProperty" or "ByteProperty") structure = Name(); // type/enum name is outside payload size
            else if (type is not ("IntProperty" or "FloatProperty" or "StrProperty" or "NameProperty" or "ArrayProperty" or "ObjectProperty" or "BoolProperty"))
                throw new BridgeError("pool_format_unsupported");
            int actualSize = type == "BoolProperty" ? 1 : size;
            if (type == "BoolProperty" && size != 0) throw new BridgeError("pool_format_unsupported");
            Need(actualSize);
            int data = Position;
            Position += actualSize;
            int end = Position;
            if (type is "StrProperty" or "NameProperty")
            {
                Position = data;
                _ = String(false);
                if (type == "NameProperty" && Int() < 0) throw new BridgeError("pool_file_invalid");
                if (Position != end) throw new BridgeError("pool_file_invalid");
            }
            if ((type is "IntProperty" or "FloatProperty") && size != 4) throw new BridgeError("pool_file_invalid");
            if (type == "BoolProperty" && bytes[data] > 1) throw new BridgeError("pool_file_invalid");
            if (type == "ByteProperty")
            {
                if (structure == "None") { if (size != 1) throw new BridgeError("pool_file_invalid"); }
                else
                {
                    Position = data; _ = String(false);
                    if (Int() < 0 || Position != end) throw new BridgeError("pool_file_invalid");
                }
            }
            return new Tag(name, type, size, data, Position, arrayIndex, structure, Start: start);
        }
        internal IReadOnlyList<Tag> Bag(int depth = 0)
        {
            if (depth > 24) throw new BridgeError("pool_file_invalid");
            var fields = new List<Tag>();
            var names = new HashSet<(string, int)>();
            for (int count = 0; count < 4096; count++)
            {
                var tag = ReadTag();
                if (tag.Name == "None") return fields;
                if (!names.Add((tag.Name.ToUpperInvariant(), tag.ArrayIndex))) throw new BridgeError("pool_file_invalid");
                if (tag.Type == "StructProperty")
                {
                    Position = tag.Data;
                    tag = tag with { Fields = Bag(depth + 1) };
                    if (Position != tag.End) throw new BridgeError("pool_format_unsupported");
                }
                fields.Add(tag);
            }
            throw new BridgeError("pool_file_invalid");
        }

        // CharacterPoolDataElement and TAppearance have zero/None/empty defaults
        // in the SDK. Native full records explicitly write defaults which the
        // mod's tagged CharPoolData snapshot omits. Match their values, not bytes,
        // field order, name casing or ANSI versus UTF-16 string representation.
        // This key is only for metadata association/conflict checks, NEVER soldier dedup.
        internal byte[] Canonical(IReadOnlyList<Tag> fields)
        {
            using var output = new MemoryStream(); using var writer = new BinaryWriter(output, Encoding.UTF8, true);
            foreach (var tag in fields.OrderBy(t => t.Name, StringComparer.OrdinalIgnoreCase).ThenBy(t => t.ArrayIndex))
            {
                cancel.ThrowIfCancellationRequested();
                byte[] value;
                if (tag.Type == "StructProperty") value = Canonical(tag.Fields!);
                else if (tag.Type is "StrProperty" or "NameProperty")
                {
                    int saved = Position; Position = tag.Data;
                    string text = String(false);
                    if (tag.Type == "NameProperty")
                    {
                        int number = Int(); text = text.ToUpperInvariant();
                        value = text == "NONE" && number == 0 ? [] : Encoding.UTF8.GetBytes(text + ":" + number);
                    }
                    else value = Encoding.UTF8.GetBytes(text);
                    Position = saved;
                }
                else
                {
                    value = bytes.AsSpan(tag.Data, tag.End - tag.Data).ToArray();
                    if ((tag.Type is "IntProperty" or "BoolProperty" || tag.Type == "ArrayProperty" && tag.Size == 4) && value.All(b => b == 0)) value = [];
                    if (tag.Type == "FloatProperty" && BitConverter.ToSingle(value) == 0) value = [];
                }
                if (value.Length == 0) continue;
                writer.Write(tag.Name.ToUpperInvariant()); writer.Write(tag.Type); writer.Write(tag.ArrayIndex);
                writer.Write(tag.Structure.ToUpperInvariant()); writer.Write(value.Length); writer.Write(value);
            }
            return output.ToArray();
        }

        private string ExtraContentKey(IReadOnlyList<Tag> fields)
        {
            // Metadata payloads are opaque and must stay byte-identical. Only the
            // runtime ID and separately compared character snapshot are excluded.
            // Do not guess defaults or semantics of future metadata fields.
            using var output = new MemoryStream(); using var writer = new BinaryWriter(output);
            foreach (var field in fields.Where(t => t.Name is not ("ObjectID" or "CharPoolData")))
            {
                writer.Write(field.End - field.Start);
                writer.Write(bytes.AsSpan(field.Start, field.End - field.Start));
            }
            return Convert.ToHexString(SHA256.HashData(output.ToArray()));
        }

        internal IReadOnlyList<ExtraData> ExtraDatas(Tag tag)
        {
            Position = tag.Data;
            int count = Int();
            if (count < 0 || count > MaxCharacters) throw new BridgeError("pool_file_invalid");
            var entries = new List<ExtraData>(count);
            for (int index = 0; index < count; index++)
            {
                int start = Position;
                var fields = Bag();
                int end = Position;
                var snapshot = fields.SingleOrDefault(t => t.Name == "CharPoolData");
                var id = fields.SingleOrDefault(t => t.Name == "ObjectID");
                if (snapshot is not { Type: "StructProperty", Structure: "CharacterPoolDataElement", ArrayIndex: 0 } ||
                    id != null && (id.Type != "IntProperty" || id.ArrayIndex != 0)) throw new BridgeError("pool_format_unsupported");
                entries.Add(new(bytes.AsMemory(start, end - start),
                    Convert.ToHexString(SHA256.HashData(Canonical(snapshot.Fields!))),
                    ExtraContentKey(fields), id == null ? -1 : id.Data - start));
            }
            if (Position != tag.End) throw new BridgeError("pool_file_invalid");
            return entries;
        }
        internal void Finished()
        {
            if (Position != bytes.Length) throw new BridgeError("pool_format_unsupported");
        }
    }

    internal static Pool Read(byte[] bytes, CancellationToken cancel = default)
    {
        if (bytes.Length is < 8 or > CharacterPoolArchive.MaxFileBytes) throw new BridgeError("pool_file_invalid");
        var reader = new Reader(bytes, cancel);
        if (reader.Int() != -1) throw new BridgeError("pool_format_unsupported");
        int count = 0;
        bool hasCount = false, hasName = false, ended = false;
        var headerNames = new HashSet<string>(StringComparer.Ordinal);
        IReadOnlyList<ExtraData> extras = [];
        for (int index = 0; index < 32; index++)
        {
            var tag = reader.ReadTag();
            if (tag.Name == "None") { ended = true; break; }
            if (!headerNames.Add(tag.Name)) throw new BridgeError("pool_file_invalid");
            if (tag.ArrayIndex != 0) throw new BridgeError("pool_format_unsupported");
            switch (tag.Name)
            {
                case "CharacterPool" when tag.Type == "ArrayProperty" && tag.Size == 4:
                    count = BinaryPrimitives.ReadInt32LittleEndian(bytes.AsSpan(tag.Data, 4)); hasCount = true;
                    break;
                case "PoolFileName" when tag.Type == "StrProperty": hasName = true; break;
                case "ExtraDatas" when tag.Type == "ArrayProperty" && tag.Size >= 4:
                    extras = reader.ExtraDatas(tag);
                    break;
                // SDK CharacterPoolManager identifies this as temporary gender
                // comparison storage, not roster/appearance data. Fresh output
                // safely uses the manager default rather than another file's cache.
                case "GenderHelper" when tag.Type == "IntProperty" && tag.Size == 4: break;
                // Native serializer's redundant last-record helper is not part of
                // the pool roster. Like native fresh exports, output needs no cache.
                case "CharacterPoolSerializeHelper" when tag.Type == "StructProperty":
                    reader.Position = tag.Data; reader.Bag();
                    if (reader.Position != tag.End) throw new BridgeError("pool_format_unsupported");
                    break;
                default:
                    // Unknown header collections still require their own merge rules.
                    throw new BridgeError("pool_format_unsupported");
            }
        }
        if (!ended || !hasName || count < 0 || count > MaxCharacters) throw new BridgeError("pool_file_invalid");
        int serializedCount = reader.Int();
        if (serializedCount != count || (!hasCount && serializedCount != 0)) throw new BridgeError("pool_file_invalid");
        var records = new List<ReadOnlyMemory<byte>>(count);
        var characterKeys = new HashSet<string>(StringComparer.Ordinal);
        for (int index = 0; index < count; index++)
        {
            int start = reader.Position;
            var fields = reader.Bag();
            int end = reader.Position;
            characterKeys.Add(Convert.ToHexString(SHA256.HashData(reader.Canonical(fields))));
            records.Add(bytes.AsMemory(start, end - start));
        }
        reader.Finished();
        // A stale/unmatched snapshot cannot be silently reassigned to a same-name
        // soldier or discarded. Valid Appearance Manager exports include this match.
        if (extras.Any(e => !characterKeys.Contains(e.CharacterKey))) throw new BridgeError("pool_metadata_unmatched");
        return new Pool(records, extras);
    }

    internal static (byte[] Bytes, int Characters, int Duplicates) Merge(IReadOnlyList<Pool> pools, string title, CancellationToken cancel = default)
    {
        var unique = new List<ReadOnlyMemory<byte>>();
        var hashes = new HashSet<string>(StringComparer.Ordinal);
        int duplicates = 0;
        var extras = new Dictionary<string, ExtraData>(StringComparer.Ordinal);
        foreach (var pool in pools)
        {
            foreach (var extra in pool.Extras)
            {
                cancel.ThrowIfCancellationRequested();
                if (extras.TryGetValue(extra.CharacterKey, out var previous))
                {
                    // IAM loads the FIRST matching CharPoolData. Do not hide an
                    // alternate appearance/loadout by arbitrarily choosing one.
                    if (previous.ContentKey != extra.ContentKey) throw new BridgeError("pool_metadata_conflict");
                }
                else extras.Add(extra.CharacterKey, extra);
                if (extras.Count > MaxCharacters) throw new BridgeError("pool_character_limit");
            }
            foreach (var character in pool.Characters)
            {
                cancel.ThrowIfCancellationRequested();
                if (!hashes.Add(Convert.ToHexString(SHA256.HashData(character.Span)))) { duplicates++; continue; }
                unique.Add(character);
                if (unique.Count > MaxCharacters) throw new BridgeError("pool_character_limit");
            }
        }
        if (unique.Count == 0) throw new BridgeError("pool_no_characters");
        using var output = new MemoryStream();
        using var writer = new BinaryWriter(output, Encoding.UTF8, true);
        writer.Write(-1);
        if (extras.Count != 0)
        {
            // Serialized ObjectID IntProperty tag + value occupies 49 bytes.
            NameArrayHeader(writer, "ExtraDatas", checked(4 + extras.Values.Sum(e => e.Bytes.Length + (e.ObjectIdOffset < 0 ? 49 : 0))));
            writer.Write(extras.Count);
            int id = 0;
            foreach (var extra in extras.Values)
            {
                cancel.ThrowIfCancellationRequested();
                if (extra.ObjectIdOffset < 0)
                {
                    WriteName(writer, "ObjectID"); WriteName(writer, "IntProperty"); writer.Write(4); writer.Write(0); writer.Write(id);
                    writer.Write(extra.Bytes.Span);
                }
                else
                {
                    writer.Write(extra.Bytes.Span[..extra.ObjectIdOffset]); writer.Write(id);
                    writer.Write(extra.Bytes.Span[(extra.ObjectIdOffset + 4)..]);
                }
                id++;
            }
        }
        WriteName(writer, "CharacterPool"); WriteName(writer, "ArrayProperty");
        writer.Write(4); writer.Write(0); writer.Write(unique.Count);
        WriteName(writer, "PoolFileName"); WriteName(writer, "StrProperty");
        string label = JourneyProjection.SingleLine(title);
        if (label.Length > 200) label = label[..200];
        byte[] nameBytes = Encoding.Unicode.GetBytes(label + '\0');
        writer.Write(4 + nameBytes.Length); writer.Write(0); writer.Write(-(label.Length + 1)); writer.Write(nameBytes);
        WriteName(writer, "None"); writer.Write(unique.Count);
        foreach (var character in unique)
        {
            cancel.ThrowIfCancellationRequested();
            writer.Write(character.Span);
            if (output.Length > CharacterPoolArchive.MaxSourceBytes + 65536L) throw new BridgeError("pool_character_limit");
        }
        return (output.ToArray(), unique.Count, duplicates);
    }

    private static void WriteName(BinaryWriter writer, string name)
    {
        byte[] bytes = Encoding.ASCII.GetBytes(name + '\0');
        writer.Write(bytes.Length); writer.Write(bytes); writer.Write(0);
    }

    private static void NameArrayHeader(BinaryWriter writer, string name, int size)
    {
        WriteName(writer, name); WriteName(writer, "ArrayProperty"); writer.Write(size); writer.Write(0);
    }
}
