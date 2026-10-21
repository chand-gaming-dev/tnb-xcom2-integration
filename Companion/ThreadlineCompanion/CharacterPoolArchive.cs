using System.Buffers.Binary;
using System.IO.Compression;
using System.Text;

namespace ThreadlineCompanion;

internal sealed record CharacterPoolDownload(byte[] OriginalZip, int Files, long SourceBytes,
    byte[]? MergedPool, int Characters, int Duplicates, string? MergeProblem);

internal static class CharacterPoolArchive
{
    internal const int MaxFileBytes = 10 * 1024 * 1024;
    internal const int MaxSourceBytes = 100 * 1024 * 1024;
    internal const int MaxZipBytes = MaxSourceBytes + 1024 * 1024;
    internal const int MaxFiles = 200;

    internal static CharacterPoolDownload Inspect(byte[] bytes, string title, CancellationToken cancel = default)
    {
        Preflight(bytes);
        using var source = new MemoryStream(bytes, false);
        using var zip = new ZipArchive(source, ZipArchiveMode.Read, false);
        if (zip.Entries.Count is < 1 or > MaxFiles) throw new BridgeError("pool_zip_invalid");
        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var pools = new List<CharacterPoolCodec.Pool>();
        long total = 0;
        string? problem = null;
        foreach (var entry in zip.Entries)
        {
            cancel.ThrowIfCancellationRequested();
            string name = entry.FullName;
            if (name.Length is < 5 or > 240 || name.Any(c => char.IsControl(c) || c is '/' or '\\' or ':' or '<' or '>' or '"' or '|' or '?' or '*') ||
                !name.EndsWith(".bin", StringComparison.OrdinalIgnoreCase) || name.Contains("..", StringComparison.Ordinal) ||
                !names.Add(name.Normalize()) || ((entry.ExternalAttributes >> 16) & 0xf000) == 0xa000)
                throw new BridgeError("pool_zip_invalid");
            if (entry.Length is < 1 or > MaxFileBytes || (total += entry.Length) > MaxSourceBytes) throw new BridgeError("pool_zip_too_large");
            using var stream = entry.Open();
            var file = new byte[(int)entry.Length];
            int position = 0;
            while (position < file.Length)
            {
                cancel.ThrowIfCancellationRequested();
                int read = stream.Read(file, position, Math.Min(81920, file.Length - position));
                if (read == 0) throw new BridgeError("pool_zip_invalid");
                position += read;
            }
            if (stream.ReadByte() != -1 || Crc32(file) != entry.Crc32) throw new BridgeError("pool_zip_invalid");
            try { pools.Add(CharacterPoolCodec.Read(file, cancel)); }
            catch (BridgeError error) when (error.Code is "pool_format_unsupported" or "pool_file_invalid" or "pool_metadata_unmatched")
            {
                problem ??= $"Cannot merge {name}: " + (error.Code switch
                {
                    "pool_format_unsupported" => "unsupported pool layout. Appearance Manager ExtraDatas is supported, but this layout needs additional handling.",
                    "pool_metadata_unmatched" => "saved appearance metadata does not match a character snapshot in this file.",
                    _ => "the binary pool structure could not be validated."
                }) + " The original ZIP is available unchanged.";
            }
            catch (DecoderFallbackException) { problem ??= $"Cannot merge {name}: invalid text encoding. The original ZIP is available unchanged."; }
        }
        if (problem != null) return new(bytes, zip.Entries.Count, total, null, 0, 0, problem);
        try
        {
            var merged = CharacterPoolCodec.Merge(pools, title, cancel);
            return new(bytes, zip.Entries.Count, total, merged.Bytes, merged.Characters, merged.Duplicates, null);
        }
        catch (BridgeError error) when (error.Code is "pool_no_characters" or "pool_character_limit" or "pool_metadata_conflict")
        {
            return new(bytes, zip.Entries.Count, total, null, 0, 0, error.Code == "pool_no_characters"
                ? "The attached pools contain no characters. The original ZIP is available unchanged."
                : error.Code == "pool_metadata_conflict"
                    ? "Two exports have different saved appearance/loadout metadata for the same character snapshot. No version was selected or discarded. Save the original ZIP to keep both exports."
                    : "The merged pool exceeds the supported character/size limit. The original ZIP is available unchanged.");
        }
    }

    // Check the central directory BEFORE ZipArchive materializes entry objects.
    // No ZIP64, multidisk, encryption, unsafe paths or unbounded entry allocation.
    private static void Preflight(byte[] bytes)
    {
        if (bytes.Length is < 22 or > MaxZipBytes) throw new BridgeError("pool_zip_invalid");
        int end = -1;
        for (int p = bytes.Length - 22; p >= Math.Max(0, bytes.Length - 65557); p--)
            if (U32(bytes, p) == 0x06054b50 && p + 22 + U16(bytes, p + 20) == bytes.Length) { end = p; break; }
        if (end < 0 || U16(bytes, end + 4) != 0 || U16(bytes, end + 6) != 0) throw new BridgeError("pool_zip_invalid");
        int count = U16(bytes, end + 10);
        uint length = U32(bytes, end + 12), start = U32(bytes, end + 16);
        if (count is < 1 or > MaxFiles || U16(bytes, end + 8) != count || (ulong)start + length != (ulong)end) throw new BridgeError("pool_zip_invalid");
        int cursor = checked((int)start);
        for (int index = 0; index < count; index++)
        {
            if (cursor > end - 46 || U32(bytes, cursor) != 0x02014b50) throw new BridgeError("pool_zip_invalid");
            int flags = U16(bytes, cursor + 8), method = U16(bytes, cursor + 10);
            uint compressed = U32(bytes, cursor + 20), uncompressed = U32(bytes, cursor + 24), local = U32(bytes, cursor + 42);
            if ((flags & 0x41) != 0 || method is not (0 or 8) || uncompressed > MaxFileBytes || compressed > MaxZipBytes ||
                U16(bytes, cursor + 34) != 0 || local > start || start - local < 30 || U32(bytes, (int)local) != 0x04034b50)
                throw new BridgeError("pool_zip_invalid");
            cursor = checked(cursor + 46 + U16(bytes, cursor + 28) + U16(bytes, cursor + 30) + U16(bytes, cursor + 32));
            if (cursor > end) throw new BridgeError("pool_zip_invalid");
        }
        if (cursor != end) throw new BridgeError("pool_zip_invalid");
    }
    private static ushort U16(byte[] bytes, int p) => BinaryPrimitives.ReadUInt16LittleEndian(bytes.AsSpan(p, 2));
    private static uint U32(byte[] bytes, int p) => BinaryPrimitives.ReadUInt32LittleEndian(bytes.AsSpan(p, 4));
    internal static uint Crc32(ReadOnlySpan<byte> bytes)
    {
        uint crc = uint.MaxValue;
        foreach (byte value in bytes)
        {
            crc ^= value;
            for (int bit = 0; bit < 8; bit++) crc = (crc >> 1) ^ (0xedb88320u & (uint)-(int)(crc & 1));
        }
        return ~crc;
    }
}
