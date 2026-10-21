using System.Net.Http.Headers;
using System.Text;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal sealed partial class JourneyApi
{
    internal async Task<byte[]> DownloadCharacterPools(string secret, CancellationToken cancel)
    {
        using var deadline = CancellationTokenSource.CreateLinkedTokenSource(cancel);
        deadline.CancelAfter(TimeSpan.FromSeconds(75));
        cancel = deadline.Token;
        string url = config.Api.GetLeftPart(UriPartial.Authority) + "/v1/game-journey/character-pools.zip";
        if (!string.IsNullOrEmpty(config.ProtectionToken)) url += "?project-protection-bypass=" + Uri.EscapeDataString(config.ProtectionToken);
        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", secret);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/zip"));
        request.Headers.CacheControl = new CacheControlHeaderValue { NoStore = true };
        using var response = await http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancel).ConfigureAwait(false);
        LastStatus = (int)response.StatusCode;
        if (LastStatus is >= 300 and < 400) throw new BridgeError("api_redirect_rejected");
        if (LastStatus != 200)
        {
            TimeSpan? retry = response.Headers.RetryAfter?.Delta ?? (response.Headers.RetryAfter?.Date - DateTimeOffset.UtcNow);
            string fallback = LastStatus switch { 401 => "invalid_credential", 403 => "scope_missing", 404 => "pool_endpoint_unavailable", 429 => "pool_busy", >= 500 => "pool_storage_unavailable", _ => "pool_download_failed" };
            // Error bodies are separately bounded; never display raw provider errors.
            using var failure = await response.Content.ReadAsStreamAsync(cancel).ConfigureAwait(false);
            using var memory = new MemoryStream();
            var chunk = new byte[4096];
            int n;
            while ((n = await failure.ReadAsync(chunk, cancel).ConfigureAwait(false)) > 0)
            {
                if (memory.Length + n > 65536) throw new BridgeError(fallback, LastStatus, retry);
                memory.Write(chunk, 0, n);
            }
            string? code = null;
            try { code = (JsonNode.Parse(memory.ToArray()) as JsonObject)?["error"]?["code"]?.GetValue<string>(); }
            catch (Exception error) when (error is System.Text.Json.JsonException or InvalidOperationException) { }
            if (code == null || code.Length > 64 || code.Any(c => !(char.IsAsciiLetterLower(c) || char.IsAsciiDigit(c) || c == '_'))) code = fallback;
            throw new BridgeError(code, LastStatus, retry);
        }
        if (!string.Equals(response.Content.Headers.ContentType?.MediaType, "application/zip", StringComparison.OrdinalIgnoreCase) ||
            response.Content.Headers.ContentEncoding.Any(value => value != "identity")) throw new BridgeError("pool_download_not_zip");
        long? declared = response.Content.Headers.ContentLength;
        if (declared is > CharacterPoolArchive.MaxZipBytes or < 22) throw new BridgeError("pool_zip_too_large");
        using var stream = await response.Content.ReadAsStreamAsync(cancel).ConfigureAwait(false);
        using var bytes = new MemoryStream();
        var buffer = new byte[81920];
        int count;
        while ((count = await stream.ReadAsync(buffer, cancel).ConfigureAwait(false)) != 0)
        {
            if (bytes.Length + count > CharacterPoolArchive.MaxZipBytes) throw new BridgeError("pool_zip_too_large");
            bytes.Write(buffer, 0, count);
        }
        if (declared.HasValue && bytes.Length != declared.Value) throw new BridgeError("pool_download_incomplete");
        return bytes.ToArray();
    }
}

internal sealed partial class ConnectionService
{
    internal async Task<CharacterPoolDownload> DownloadCharacterPools(string expectedJourney, string title, CancellationToken cancel)
    {
        string secret;
        await gate.WaitAsync(cancel).ConfigureAwait(false);
        try { secret = Credential(expectedJourney); }
        finally { gate.Release(); }
        // Crucial: never hold the activation/event-handoff gate over a large download.
        byte[] zip = await api.DownloadCharacterPools(secret, cancel).ConfigureAwait(false);
        CharacterPoolDownload download;
        try { download = CharacterPoolArchive.Inspect(zip, title, cancel); }
        catch (InvalidDataException) { throw new BridgeError("pool_zip_invalid"); }
        catch (DecoderFallbackException) { throw new BridgeError("pool_file_invalid"); }
        await gate.WaitAsync(cancel).ConfigureAwait(false);
        try
        {
            cancel.ThrowIfCancellationRequested();
            if (Credential(expectedJourney) != secret) throw new BridgeError("pool_credential_changed");
            return download;
        }
        finally { gate.Release(); }
    }
}

internal static class CharacterPoolFiles
{
    internal static string ImportDirectory => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
        "My Games", "XCOM2 War of the Chosen", "XComGame", "CharacterPool", "Importable");

    internal static void SaveNew(string path, byte[] bytes, string extension, CancellationToken cancel)
    {
        path = Path.GetFullPath(path);
        string name = Path.GetFileName(path);
        if (!string.Equals(Path.GetExtension(path), extension, StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("DefaultCharacterPool", StringComparison.OrdinalIgnoreCase)) throw new BridgeError("pool_output_path_invalid");
        if (File.Exists(path)) throw new BridgeError("pool_output_exists");
        string directory = Path.GetDirectoryName(path)!;
        if (!Directory.Exists(directory)) throw new DirectoryNotFoundException();
        string temporary = Path.Combine(directory, ".tnb-pool-" + Guid.NewGuid().ToString("N") + ".tmp");
        try
        {
            using (var stream = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
            {
                for (int offset = 0; offset < bytes.Length; offset += 81920)
                {
                    cancel.ThrowIfCancellationRequested();
                    stream.Write(bytes, offset, Math.Min(81920, bytes.Length - offset));
                }
                stream.Flush(true);
            }
            cancel.ThrowIfCancellationRequested();
            File.Move(temporary, path, false); // atomic publish, never overwrite an existing pool/archive
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); } // only our own explicit unique temporary file
    }
}

internal static class CharacterPoolMessages
{
    internal static string Error(Exception error) => error is BridgeError bridge ? bridge.Code switch
    {
        "pool_output_exists" => "That file already exists. Choose a new filename; existing files are never overwritten.",
        "pool_output_path_invalid" => "Choose a new .bin pool or .zip archive filename, not an active DefaultCharacterPool file.",
        "pool_download_not_zip" or "pool_download_incomplete" or "pool_zip_invalid" => "The complete ZIP could not be verified. No files were saved. Retry the download.",
        "pool_zip_too_large" or "pool_export_limit_exceeded" => "The archive exceeds supported limits: 200 files, 10 MiB per file, 100 MiB total source data.",
        "pool_journey_game_unsupported" => "This Journey is not associated with a supported XCOM 2 game registration. Check it in the portal.",
        "pool_endpoint_unavailable" => "This API does not expose the Character Pool download endpoint yet, or the development app is unavailable.",
        "pool_export_empty" or "pool_manifest_invalid" => "No complete export is available. Check authorized character attachments in the portal.",
        "pool_busy" => "Character Pool exports are busy or rate-limited. Wait at least a minute before retrying.",
        "pool_object_missing" or "pool_object_integrity_failed" or "pool_attachment_invalid" or "pool_storage_mismatch" => "An attached file is missing or failed server verification. Its owner may need to upload it again; no partial archive was saved.",
        "pool_not_configured" or "pool_storage_unavailable" or "pool_manifest_unavailable" or "pool_operation_cancelled" => "Character Pool storage is unavailable or the export timed out. Retry later.",
        "pool_credential_changed" or "journey_mismatch" => "The active Journey or credential changed during download. Download again for the current Journey.",
        "scope_missing" => "The Journey credential needs roster:read permission to download Character Pools.",
        _ => CompanionMessages.Error(error)
    } : error switch
    {
        OperationCanceledException => "Character Pool operation cancelled or timed out. Previously saved files are unchanged.",
        IOException or UnauthorizedAccessException => "The file could not be read or saved. Check the destination and permissions; choose a new filename.",
        _ => CompanionMessages.Error(error)
    };
}
