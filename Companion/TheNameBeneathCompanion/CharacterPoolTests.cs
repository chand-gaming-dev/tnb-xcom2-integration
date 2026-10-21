using System.IO.Compression;
using System.Net;
using System.Text;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal static class CharacterPoolTests
{
    private static void Check(bool condition, string label) { if (!condition) throw new BridgeError("pool_test_" + label); }
    private static void Reject(Action action, params string[] codes)
    {
        try { action(); throw new Exception("Invalid pool/archive accepted"); }
        catch (BridgeError error) { Check(codes.Contains(error.Code), "reject_" + error.Code); }
    }
    private static async Task RejectAsync(Func<Task> action, params string[] codes)
    {
        try { await action(); throw new Exception("Invalid transfer accepted"); }
        catch (BridgeError error) { Check(codes.Contains(error.Code), "reject_" + error.Code); }
    }
    private static void Name(BinaryWriter writer, string value)
    {
        var encoded = Encoding.ASCII.GetBytes(value + '\0');
        writer.Write(encoded.Length); writer.Write(encoded); writer.Write(0);
    }
    private static void Property(BinaryWriter writer, string name, string type, byte[] data, string? structure = null)
    {
        Name(writer, name); Name(writer, type);
        writer.Write(type == "BoolProperty" ? 0 : data.Length); writer.Write(0);
        if (structure != null) Name(writer, structure);
        writer.Write(data);
    }
    private static byte[] StringData(string value, bool wide = false)
    {
        using var buffer = new MemoryStream(); using var writer = new BinaryWriter(buffer);
        writer.Write(wide ? -(value.Length + 1) : value.Length + 1);
        writer.Write((wide ? Encoding.Unicode : Encoding.Latin1).GetBytes(value + '\0'));
        return buffer.ToArray();
    }
    internal static byte[] Fixture(string name = "René 雪", int characters = 1, bool extended = false)
    {
        using var buffer = new MemoryStream(); using var writer = new BinaryWriter(buffer);
        writer.Write(-1);
        if (extended) Property(writer, "UnknownModDatas", "ArrayProperty", BitConverter.GetBytes(0));
        Property(writer, "CharacterPool", "ArrayProperty", BitConverter.GetBytes(characters));
        Property(writer, "PoolFileName", "StrProperty", StringData("Original"));
        Name(writer, "None"); writer.Write(characters);
        for (int i = 0; i < characters; i++)
        {
            Property(writer, "strFirstName", "StrProperty", StringData(name, true));
            Property(writer, "PoolTimestamp", "StrProperty", StringData("2026-10-21:" + i));
            Property(writer, "AllowedTypeSoldier", "BoolProperty", [1]);
            Property(writer, "BackgroundText", "StrProperty", StringData("Bio: <literal> & café 雪", true));
            using var appearance = new MemoryStream();
            using (var nested = new BinaryWriter(appearance, Encoding.UTF8, true))
            {
                Property(nested, "iGender", "IntProperty", BitConverter.GetBytes(0));
                using var item = new MemoryStream();
                using (var field = new BinaryWriter(item, Encoding.UTF8, true)) Name(field, "CustomMod_Arms");
                Property(nested, "nmArms", "NameProperty", item.ToArray());
                Name(nested, "None");
            }
            Property(writer, "kAppearance", "StructProperty", appearance.ToArray(), "TAppearance");
            Name(writer, "None");
        }
        return buffer.ToArray();
    }

    internal static byte[] WithExtras(byte[] original, params (byte[] Snapshot, int? Id, string Armor)[] extras)
    {
        var records = CharacterPoolCodec.Read(original).Characters;
        using var payload = new MemoryStream();
        using (var data = new BinaryWriter(payload, Encoding.UTF8, true))
        {
            data.Write(extras.Length);
            foreach (var extra in extras)
            {
                if (extra.Id.HasValue) Property(data, "ObjectID", "IntProperty", BitConverter.GetBytes(extra.Id.Value));
                Property(data, "CharPoolData", "StructProperty", extra.Snapshot, "CharacterPoolDataElement");
                using var store = new MemoryStream();
                using (var appearance = new BinaryWriter(store, Encoding.UTF8, true))
                {
                    appearance.Write(1);
                    Property(appearance, "GenderArmorTemplate", "StrProperty", StringData(extra.Armor));
                    using var parts = new MemoryStream();
                    using (var part = new BinaryWriter(parts, Encoding.UTF8, true))
                    {
                        using var cosmetic = new MemoryStream();
                        using (var name = new BinaryWriter(cosmetic, Encoding.UTF8, true)) Name(name, "MissingMod_Helmet");
                        Property(part, "nmHelmet", "NameProperty", cosmetic.ToArray()); Name(part, "None");
                    }
                    Property(appearance, "Appearance", "StructProperty", parts.ToArray(), "TAppearance"); Name(appearance, "None");
                }
                Property(data, "AppearanceStore", "ArrayProperty", store.ToArray());
                using var loadout = new MemoryStream();
                using (var item = new BinaryWriter(loadout, Encoding.UTF8, true))
                {
                    item.Write(1);
                    using var enumValue = new MemoryStream();
                    using (var value = new BinaryWriter(enumValue, Encoding.UTF8, true)) Name(value, "eInvSlot_Armor");
                    Property(item, "InventorySlot", "ByteProperty", enumValue.ToArray(), "EInventorySlot"); Name(item, "None");
                }
                Property(data, "CharacterPoolLoadout", "ArrayProperty", loadout.ToArray());
                Property(data, "FutureMetadata", "StrProperty", StringData("preserved, not interpreted"));
                Name(data, "None");
            }
        }
        using var output = new MemoryStream(); using var writer = new BinaryWriter(output);
        writer.Write(-1); Property(writer, "ExtraDatas", "ArrayProperty", payload.ToArray());
        Property(writer, "CharacterPool", "ArrayProperty", BitConverter.GetBytes(records.Count));
        Property(writer, "PoolFileName", "StrProperty", StringData("Extended")); Name(writer, "None"); writer.Write(records.Count);
        foreach (var record in records) writer.Write(record.Span);
        return output.ToArray();
    }

    private static void MetadataTests(byte[] first, byte[] second)
    {
        byte[] snapshot = CharacterPoolCodec.Read(first).Characters[0].ToArray();
        byte[] otherSnapshot = CharacterPoolCodec.Read(second).Characters[0].ToArray();
        byte[] extended = WithExtras(first, (snapshot, 8, "KevlarArmor1"));
        var input = CharacterPoolCodec.Read(extended);
        var result = CharacterPoolArchive.Inspect(Zip(("plain.bin", first), ("modded.bin", extended),
            ("second.bin", WithExtras(second, (otherSnapshot, 8, "PoweredArmor1"))), ("duplicate.bin", extended)), "Metadata");
        Check(result.MergedPool != null && result.Characters == 3 && result.Duplicates == 2, "metadata_merge_counts");
        var merged = CharacterPoolCodec.Read(result.MergedPool!);
        Check(merged.Extras.Count == 2 && merged.Extras[0].ContentKey == input.Extras[0].ContentKey &&
            merged.Extras[0].CharacterKey == input.Extras[0].CharacterKey, "metadata_snapshot_and_content_preserved");
        for (int index = 0; index < merged.Extras.Count; index++)
            Check(BitConverter.ToInt32(merged.Extras[index].Bytes.Span.Slice(merged.Extras[index].ObjectIdOffset, 4)) == index, "metadata_ids_rebased");
        var sourceExtra = input.Extras[0]; var targetExtra = merged.Extras[0];
        Check(sourceExtra.Bytes.Span[..sourceExtra.ObjectIdOffset].SequenceEqual(targetExtra.Bytes.Span[..targetExtra.ObjectIdOffset]) &&
            sourceExtra.Bytes.Span[(sourceExtra.ObjectIdOffset + 4)..].SequenceEqual(targetExtra.Bytes.Span[(targetExtra.ObjectIdOffset + 4)..]), "metadata_raw_bytes_except_runtime_id");
        var absentId = CharacterPoolArchive.Inspect(Zip(("omitted-id.bin", WithExtras(first, (snapshot, null, "KevlarArmor1")))), "No ID");
        Check(absentId.MergedPool != null && CharacterPoolCodec.Read(absentId.MergedPool).Extras[0].ContentKey == sourceExtra.ContentKey, "metadata_default_id_added");
        var duplicates = CharacterPoolArchive.Inspect(Zip(("a.bin", extended), ("b.bin", WithExtras(first, (snapshot, 900, "KevlarArmor1")))), "IDs differ");
        Check(duplicates.MergedPool != null && duplicates.Characters == 1 && CharacterPoolCodec.Read(duplicates.MergedPool).Extras.Count == 1, "metadata_runtime_id_not_identity");
        var conflicting = CharacterPoolArchive.Inspect(Zip(("a.bin", extended), ("b.bin", WithExtras(first, (snapshot, 8, "DifferentArmor1")))), "Conflict");
        Check(conflicting.MergedPool == null && conflicting.MergeProblem!.Contains("different saved", StringComparison.Ordinal), "metadata_conflict_no_partial");
        Reject(() => CharacterPoolCodec.Read(WithExtras(first, (otherSnapshot, 8, "KevlarArmor1"))), "pool_metadata_unmatched");
        var unmatched = CharacterPoolArchive.Inspect(Zip(("unmatched.bin", WithExtras(first, (otherSnapshot, 8, "KevlarArmor1")))), "Unmatched");
        Check(unmatched.MergedPool == null && unmatched.MergeProblem!.Contains("unmatched.bin", StringComparison.Ordinal), "metadata_unmatched_zip_retained");
        using var defaultSnapshot = new MemoryStream();
        using (var writer = new BinaryWriter(defaultSnapshot, Encoding.UTF8, true))
        {
            // Native records can explicitly serialize zeros omitted by the mod snapshot.
            Property(writer, "AllowedTypeVIP", "BoolProperty", [0]);
            writer.Write(snapshot);
        }
        var defaults = CharacterPoolArchive.Inspect(Zip(("defaults.bin", WithExtras(first, (defaultSnapshot.ToArray(), 0, "KevlarArmor1")))), "Defaults");
        Check(defaults.MergedPool != null, "metadata_omitted_defaults_match");
        var defaultDuplicate = CharacterPoolArchive.Inspect(Zip(("full.bin", WithExtras(first, (defaultSnapshot.ToArray(), 0, "KevlarArmor1"))), ("sparse.bin", extended)), "Defaults duplicate");
        Check(defaultDuplicate.MergedPool != null && CharacterPoolCodec.Read(defaultDuplicate.MergedPool).Extras.Count == 1, "metadata_semantic_snapshot_dedup");
        var sameNames = CharacterPoolArchive.Inspect(Zip(("one.bin", WithExtras(Fixture("Same", 1), (CharacterPoolCodec.Read(Fixture("Same", 1)).Characters[0].ToArray(), 1, "Armor1"))),
            ("two.bin", WithExtras(Fixture("Same", 2), (CharacterPoolCodec.Read(Fixture("Same", 2)).Characters[1].ToArray(), 1, "Armor2")))), "Same names");
        Check(sameNames.MergedPool != null && sameNames.Characters == 2 && CharacterPoolCodec.Read(sameNames.MergedPool).Extras.Count == 2, "metadata_not_name_matched");
        byte[] truncatedExtras = (byte[])extended.Clone();
        // First array's payload begins immediately after -1 and the 49-byte tag.
        BitConverter.GetBytes(2).CopyTo(truncatedExtras, 53);
        Reject(() => CharacterPoolCodec.Read(truncatedExtras), "pool_file_invalid", "pool_format_unsupported");
        var roundtrip = CharacterPoolCodec.Merge([merged], "Roundtrip");
        Check(CharacterPoolCodec.Read(roundtrip.Bytes).Extras.Select(e => e.ContentKey).SequenceEqual(merged.Extras.Select(e => e.ContentKey)), "metadata_repeat_roundtrip");
    }
    internal static byte[] Zip(params (string Name, byte[] Bytes)[] entries)
    {
        using var buffer = new MemoryStream();
        using (var zip = new ZipArchive(buffer, ZipArchiveMode.Create, true))
            foreach (var entry in entries)
            {
                using var target = zip.CreateEntry(entry.Name, CompressionLevel.NoCompression).Open();
                target.Write(entry.Bytes);
            }
        return buffer.ToArray();
    }
    internal static async Task<int> Run(string? fixtureDirectory)
    {
        string testRoot = Path.Combine(Path.GetTempPath(), "TNB-PoolTests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(testRoot);
        try
        {
            byte[] first = Fixture(), two = Fixture("Second", 2);
            MetadataTests(first, two);
            byte[] original = Zip(("one.bin", first), ("two.bin", two), ("duplicate.bin", first));
            var result = CharacterPoolArchive.Inspect(original, "The Name Beneath - Résistance 雪");
            Check(result.OriginalZip.SequenceEqual(original) && result.Files == 3 && result.Characters == 3 && result.Duplicates == 1 && result.MergedPool != null, "merge_counts");
            var parsed = CharacterPoolCodec.Read(result.MergedPool!);
            var originalRecords = CharacterPoolCodec.Read(first).Characters.Concat(CharacterPoolCodec.Read(two).Characters).ToArray();
            Check(parsed.Characters.Count == originalRecords.Length && parsed.Characters.Zip(originalRecords).All(pair => pair.First.Span.SequenceEqual(pair.Second.Span)), "raw_records_preserved");
            byte[] sameNameDifferent = Fixture("René 雪", 2);
            Check(CharacterPoolArchive.Inspect(Zip(("a.bin", sameNameDifferent)), "Same names").Characters == 2, "not_name_dedup");
            var unsupported = CharacterPoolArchive.Inspect(Zip(("standard.bin", first), ("modded.bin", Fixture(extended: true))), "Unsupported");
            Check(unsupported.MergedPool == null && unsupported.MergeProblem!.Contains("modded.bin", StringComparison.Ordinal) && unsupported.Files == 2, "no_partial_merge");
            Check(CharacterPoolArchive.Inspect(Zip(("empty.bin", Fixture(characters: 0))), "Empty").MergedPool == null, "empty_pool");
            Check(CharacterPoolArchive.Inspect(Zip(("broken.bin", first[..^2])), "Bad").MergedPool == null, "truncated_pool");
            Reject(() => CharacterPoolArchive.Inspect([1, 2, 3], "Bad"), "pool_zip_invalid");
            foreach (string name in new[] { "../unsafe.bin", "nested/file.bin", "C:\\file.bin", "not-a-pool.txt", "control\n.bin" })
                Reject(() => CharacterPoolArchive.Inspect(Zip((name, first)), "Unsafe"), "pool_zip_invalid");
            Reject(() => CharacterPoolArchive.Inspect(Zip(("a.bin", first), ("A.bin", first)), "Duplicates"), "pool_zip_invalid");
            Reject(() => CharacterPoolArchive.Inspect(Zip(Enumerable.Range(0, 201).Select(i => ($"{i}.bin", first)).ToArray()), "Many"), "pool_zip_invalid");
            Reject(() => CharacterPoolArchive.Inspect(Zip(("oversized.bin", new byte[CharacterPoolArchive.MaxFileBytes + 1])), "Large"), "pool_zip_invalid", "pool_zip_too_large");
            var corrupt = (byte[])original.Clone();
            // Mutate the first STORED payload without updating its central-directory CRC.
            int dataStart = 30 + BitConverter.ToUInt16(corrupt, 26) + BitConverter.ToUInt16(corrupt, 28);
            corrupt[dataStart + 10] ^= 1;
            Reject(() => CharacterPoolArchive.Inspect(corrupt, "CRC"), "pool_zip_invalid");
            using (var cancelled = new CancellationTokenSource())
            {
                cancelled.Cancel();
                try { CharacterPoolArchive.Inspect(original, "Cancelled", cancelled.Token); throw new Exception("Cancellation ignored"); }
                catch (OperationCanceledException) { }
            }
            string saved = Path.Combine(testRoot, "Merged.bin");
            CharacterPoolFiles.SaveNew(saved, result.MergedPool!, ".bin", CancellationToken.None);
            Check(File.ReadAllBytes(saved).SequenceEqual(result.MergedPool!), "saved_bytes");
            Reject(() => CharacterPoolFiles.SaveNew(saved, first, ".bin", CancellationToken.None), "pool_output_exists");
            Check(File.ReadAllBytes(saved).SequenceEqual(result.MergedPool!), "existing_file_preserved");
            Reject(() => CharacterPoolFiles.SaveNew(Path.Combine(testRoot, "DefaultCharacterPool.bin"), first, ".bin", CancellationToken.None), "pool_output_path_invalid");
            Check(!Directory.EnumerateFiles(testRoot, "*.tmp").Any(), "no_temporary_remains");
            using (var cancelledSave = new CancellationTokenSource())
            {
                cancelledSave.Cancel(); string notSaved = Path.Combine(testRoot, "Cancelled.bin");
                try { CharacterPoolFiles.SaveNew(notSaved, first, ".bin", cancelledSave.Token); throw new Exception("Cancelled save published"); }
                catch (OperationCanceledException) { }
                Check(!File.Exists(notSaved) && !Directory.EnumerateFiles(testRoot, "*.tmp").Any(), "cancelled_save_no_file");
            }
            await NetworkTests(testRoot, original);
            if (fixtureDirectory != null)
            {
                var vanilla = new List<(string Name, byte[] Bytes)>();
                foreach (string file in Directory.EnumerateFiles(fixtureDirectory, "*.bin"))
                {
                    byte[] bytes = File.ReadAllBytes(file);
                    try
                    {
                        int count = CharacterPoolCodec.Read(bytes).Characters.Count;
                        vanilla.Add((Path.GetFileName(file), bytes));
                        Console.WriteLine($"POOL_FIXTURE: {Path.GetFileName(file)} / {count} records / {CharacterPoolCodec.Read(bytes).Extras.Count} metadata entries / preserved bytes.");
                    }
                    catch (BridgeError error) when (error.Code == "pool_format_unsupported")
                    {
                        Check(CharacterPoolArchive.Inspect(Zip((Path.GetFileName(file), bytes)), "Unsupported").MergedPool == null, "modded_fixture_rejected");
                        Console.WriteLine($"POOL_FIXTURE: {Path.GetFileName(file)} / unsupported metadata / ZIP retained, merge blocked.");
                    }
                }
                Check(vanilla.Count >= 1, "real_standard_fixtures");
                var real = CharacterPoolArchive.Inspect(Zip(vanilla.ToArray()), "The Name Beneath - Fixture Import");
                Check(real.MergedPool != null && CharacterPoolCodec.Read(real.MergedPool).Characters.Count == real.Characters, "real_roundtrip");
                var sourcePools = vanilla.Select(file => CharacterPoolCodec.Read(file.Bytes)).ToArray();
                var realParsed = CharacterPoolCodec.Read(real.MergedPool!);
                Check(realParsed.Characters.Select(c => Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(c.Span)))
                    .SequenceEqual(sourcePools.SelectMany(pool => pool.Characters).Select(c => Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(c.Span))).Distinct()), "real_raw_record_bytes");
                Check(realParsed.Extras.Select(e => (e.CharacterKey, e.ContentKey)).SequenceEqual(sourcePools.SelectMany(pool => pool.Extras).Select(e => (e.CharacterKey, e.ContentKey)).Distinct()), "real_extra_content_and_association");
                CharacterPoolFiles.SaveNew(Path.Combine(testRoot, "FixtureMerged.bin"), real.MergedPool!, ".bin", CancellationToken.None);
                foreach (string file in Directory.EnumerateFiles(fixtureDirectory, "*.zip"))
                    Check(CharacterPoolArchive.Inspect(File.ReadAllBytes(file), "Backend ZIP").MergedPool != null, "backend_store_zip");
                Console.WriteLine($"POOL_FIXTURE_MERGED: {real.Files} files / {real.Characters} characters / {real.Duplicates} exact duplicates removed. Output retained in isolated test folder; not installed into the game.");
            }
            Console.WriteLine("PASS: Character Pool ZIP bounds/CRC/path checks, raw-record/Unicode preservation, exact-only dedup, Appearance Manager metadata preservation/association/ID rebasing/conflicts/defaults, unsupported-format no-partial merge, cancellation, atomic new-file save, credential-pinned GET, error redaction and nonblocking event handoffs.");
            Console.WriteLine("Pool test output: " + testRoot);
            return 0;
        }
        catch (BridgeError error) { Console.Error.WriteLine("Pool self-test code: " + error.Code); return 1; }
        catch (Exception error) { Console.Error.WriteLine("Pool self-test failed: " + error.GetType().Name); return 1; }
    }

    private static async Task NetworkTests(string root, byte[] archive)
    {
        var config = new Configuration(new Uri("https://pool-tests.invalid/"), 0, Path.Combine(root, "network"), "protection-test", null);
        var vault = new CompanionTests.MemoryVault();
        using var handler = new PoolHandler(archive);
        using var api = new JourneyApi(config, handler);
        var service = new ConnectionService(config, vault, api);
        await service.Import(CompanionTests.Secret, CancellationToken.None);
        var download = await service.DownloadCharacterPools(CompanionTests.JourneyId, "Test", CancellationToken.None);
        Check(download.Files == 3 && handler.Auth == CompanionTests.Secret && handler.Accept == "application/zip" &&
            handler.Path == "/v1/game-journey/character-pools.zip?project-protection-bypass=protection-test", "exact_download_request");
        int requests = handler.PoolRequests;
        await RejectAsync(() => service.DownloadCharacterPools("22222222-2222-4222-8222-222222222222", "Wrong", CancellationToken.None), "journey_mismatch");
        Check(handler.PoolRequests == requests, "mismatch_not_sent");
        handler.Status = HttpStatusCode.TemporaryRedirect;
        await RejectAsync(() => service.DownloadCharacterPools(CompanionTests.JourneyId, "Redirect", CancellationToken.None), "api_redirect_rejected");
        handler.Status = HttpStatusCode.OK; handler.ContentType = "text/html";
        await RejectAsync(() => service.DownloadCharacterPools(CompanionTests.JourneyId, "HTML", CancellationToken.None), "pool_download_not_zip");
        handler.ContentType = "application/zip"; handler.Status = HttpStatusCode.ServiceUnavailable;
        await RejectAsync(() => service.DownloadCharacterPools(CompanionTests.JourneyId, "Error", CancellationToken.None), "pool_storage_unavailable");
        Check(!CharacterPoolMessages.Error(new BridgeError("pool_storage_unavailable")).Contains(CompanionTests.Secret, StringComparison.Ordinal), "error_redacted");
        foreach (var (status, code) in new[] { (HttpStatusCode.Unauthorized, "invalid_credential"), (HttpStatusCode.Forbidden, "scope_missing"), (HttpStatusCode.TooManyRequests, "pool_busy") })
        {
            handler.Status = status;
            await RejectAsync(() => service.DownloadCharacterPools(CompanionTests.JourneyId, "Denied", CancellationToken.None), code);
        }
        handler.Status = HttpStatusCode.OK;
        handler.DeclaredLength = CharacterPoolArchive.MaxZipBytes + 1L;
        await RejectAsync(() => service.DownloadCharacterPools(CompanionTests.JourneyId, "Large", CancellationToken.None), "pool_zip_too_large");
        handler.DeclaredLength = archive.Length + 1L;
        await RejectAsync(() => service.DownloadCharacterPools(CompanionTests.JourneyId, "Short", CancellationToken.None), "pool_download_incomplete");
        handler.DeclaredLength = null;
        handler.Release = new(TaskCreationOptions.RunContinuationsAsynchronously);
        using (var stopping = new CancellationTokenSource())
        {
            var cancelled = service.DownloadCharacterPools(CompanionTests.JourneyId, "Cancelled", stopping.Token);
            stopping.Cancel();
            try { await cancelled; throw new Exception("Cancelled HTTP completed"); }
            catch (OperationCanceledException) { }
        }
        handler.Release = new(TaskCreationOptions.RunContinuationsAsynchronously);
        var pending = service.DownloadCharacterPools(CompanionTests.JourneyId, "Pending", CancellationToken.None);
        await handler.Entered.Task.WaitAsync(TimeSpan.FromSeconds(2));
        await service.EventOperation("events_status", new JsonObject { ["expected_journey_id"] = CompanionTests.JourneyId, ["campaign_id"] = "pool-test-campaign" }, CancellationToken.None).WaitAsync(TimeSpan.FromSeconds(2));
        await service.Remove(CancellationToken.None).WaitAsync(TimeSpan.FromSeconds(2));
        handler.Release.TrySetResult();
        await RejectAsync(() => pending, "credential_missing");
        Check(vault.Read(CompanionTests.JourneyId) == null, "removed_credential_not_restored");
    }

    internal sealed class PoolHandler(byte[] archive) : HttpMessageHandler
    {
        internal HttpStatusCode Status = HttpStatusCode.OK;
        internal string ContentType = "application/zip";
        internal string? Auth, Path, Accept;
        internal int PoolRequests;
        internal byte[]? Body;
        internal long? DeclaredLength;
        internal TaskCompletionSource? Release;
        internal readonly TaskCompletionSource Entered = new(TaskCreationOptions.RunContinuationsAsynchronously);
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancel)
        {
            if (request.RequestUri!.AbsolutePath == "/v1/game-journey")
                return new(HttpStatusCode.OK) { Content = new StringContent(new JsonObject { ["data"] = CompanionTests.Context() }.ToJsonString(), Encoding.UTF8, "application/json") };
            Check(request.Method == HttpMethod.Get, "method_get_only");
            PoolRequests++; Auth = request.Headers.Authorization?.Parameter; Path = request.RequestUri.PathAndQuery; Accept = request.Headers.Accept.ToString();
            if (Release != null) { Entered.TrySetResult(); await Release.Task.WaitAsync(cancel); }
            var response = new HttpResponseMessage(Status) { Content = new ByteArrayContent(Status == HttpStatusCode.OK ? Body ?? archive : Encoding.UTF8.GetBytes("private-provider-error:" + CompanionTests.Secret)) };
            response.Content.Headers.ContentType = new(ContentType);
            if (DeclaredLength.HasValue) response.Content.Headers.ContentLength = DeclaredLength;
            return response;
        }
    }
}
