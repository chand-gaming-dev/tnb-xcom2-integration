using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

internal sealed partial class ConnectionService
{
    private static readonly string[] RequiredScopes = ["roster:read", "instances:create", "instances:read", "events:write"];
    private readonly Configuration config;
    private readonly ISecretStore vault;
    private readonly ThreadlineApi api;
    private readonly ActivationReceipts activations;
    private JsonObject? context;
    private string connection = "not_configured";
    private readonly SemaphoreSlim gate = new(1, 1);
    private readonly object stateLock = new();
    internal string ContextPath => Path.Combine(config.DataDirectory, Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(config.Api.AbsoluteUri)))[..16] + ".context.json");

    internal ConnectionService(Configuration configuration, ISecretStore secretStore, ThreadlineApi client)
    {
        config = configuration; vault = secretStore; api = client;
        activations = new ActivationReceipts(configuration, client);
        events = new EventOutbox(configuration);
        if (File.Exists(ContextPath))
        {
            try { context = JsonNode.Parse(File.ReadAllText(ContextPath)) as JsonObject; }
            catch (System.Text.Json.JsonException) { connection = "saved_context_invalid"; }
            if (context != null) connection = "unverified";
        }
    }
    internal JsonObject Status()
    {
        lock (stateLock) return StatusLocked();
    }
    private JsonObject StatusLocked()
    {
        bool stored = Journey is { } id && vault.Read(id) != null;
        var status = new JsonObject
        {
            ["credential_stored"] = stored, ["connection"] = stored ? connection : "not_configured",
            ["api_origin"] = config.Api.GetLeftPart(UriPartial.Authority), ["journey_id"] = Journey ?? "",
            ["journey_title"] = context?["journey_title"]?.GetValue<string>() ?? "",
            ["game_name"] = context?["game_name"]?.GetValue<string>() ?? "",
            ["title_observed_at"] = context?["_tnb_title_observed_at"]?.GetValue<string>() ?? "",
            ["commander_name"] = context?["commander"]?["display_name"]?.GetValue<string>() ?? "",
            ["commander_id"] = context?["commander"]?["id"]?.GetValue<string>() ?? "",
            ["journey_status"] = context?["status"]?.GetValue<string>() ?? ""
        };
        return status;
    }
    internal string? Journey { get { lock (stateLock) return context?["journey_id"]?.GetValue<string>(); } }
    internal string Credential(string expectedJourney)
    {
        if (expectedJourney != Journey) throw new BridgeError("journey_mismatch");
        return vault.Read(expectedJourney) ?? throw new BridgeError("credential_missing");
    }
    internal async Task<JsonObject> Import(string secret, CancellationToken cancel)
    {
        if (!secret.StartsWith("tlj_", StringComparison.Ordinal) || secret.Length is < 48 or > 1280 || secret.Any(char.IsWhiteSpace)) throw new BridgeError("invalid_credential_format");
        await gate.WaitAsync(cancel);
        try
        {
            // Do not replace a working vault entry or context until validation succeeds.
            var verified = await api.Send("GET", "/v1/game-journey", secret, null, cancel);
            ValidateContext(verified);
            string id = verified["journey_id"]!.GetValue<string>();
            cancel.ThrowIfCancellationRequested();
            lock (stateLock)
            {
                vault.Write(id, secret);
                SaveContext(verified);
                connection = "connected";
                events.Retry(id, null);
                return Status();
            }
        }
        finally { gate.Release(); }
    }
    internal async Task<JsonObject> Test(CancellationToken cancel)
    {
        await gate.WaitAsync(cancel);
        try
        {
            string id = Journey ?? throw new BridgeError("credential_missing");
            var verified = await api.Send("GET", "/v1/game-journey", Credential(id), null, cancel);
            ValidateContext(verified);
            if (verified["journey_id"]!.GetValue<string>() != id) throw new BridgeError("journey_mismatch");
            cancel.ThrowIfCancellationRequested();
            lock (stateLock)
            {
                SaveContext(verified);
                connection = "connected";
                return Status();
            }
        }
        catch (BridgeError error)
        {
            lock (stateLock) connection = error.Code is "invalid_credential" or "journey_credential_invalid" ? "invalid_credential" : error.Code == "scope_missing" ? "scope_missing" : "unable_to_verify";
            throw;
        }
        catch (HttpRequestException) { lock (stateLock) connection = "unable_to_verify"; throw; }
        catch (OperationCanceledException) { lock (stateLock) connection = "unable_to_verify"; throw; }
        finally { gate.Release(); }
    }
    internal async Task<JsonObject> Remove(CancellationToken cancel)
    {
        await gate.WaitAsync(cancel);
        try
        {
            lock (stateLock)
            {
                if (Journey is { } id) vault.Remove(id);
                connection = "not_configured";
                return Status();
            }
        }
        finally { gate.Release(); }
    }
    internal async Task<JsonObject> PreviewContext(string expectedJourney, CancellationToken cancel)
    {
        await gate.WaitAsync(cancel);
        try
        {
            string id = Journey ?? throw new BridgeError("credential_missing");
            if (expectedJourney.Length != 0 && expectedJourney != id) throw new BridgeError("journey_mismatch");
            var response = await api.Send("GET", "/v1/game-journey", Credential(id), null, cancel);
            ValidateContext(response);
            if (response["journey_id"]!.GetValue<string>() != id) throw new BridgeError("journey_mismatch");
            // Normalize before touching cached status. Never return the raw API envelope to XCOM.
            var preview = JourneyProjection.Context(response);
            cancel.ThrowIfCancellationRequested();
            lock (stateLock) { SaveContext(response); connection = "connected"; }
            return preview;
        }
        finally { gate.Release(); }
    }
    internal async Task<JsonObject> PreviewRoster(string expectedJourney, string cursor, CancellationToken cancel)
    {
        if (expectedJourney.Length == 0 || cursor.Length > 1024) throw new BridgeError("request_invalid");
        await gate.WaitAsync(cancel);
        try
        {
            // Every page is pinned to the Journey requested by the game, including after rotation.
            string secret = Credential(expectedJourney);
            string path = "/v1/game-journey/roster?limit=5" + (cursor.Length == 0 ? "" : "&cursor=" + Uri.EscapeDataString(cursor));
            return JourneyProjection.Roster(await api.Send("GET", path, secret, null, cancel), expectedJourney);
        }
        finally { gate.Release(); }
    }
    internal async Task<JsonObject> StartJourney(JsonObject args, CancellationToken cancel)
    {
        string expected = args["expected_journey_id"]?.GetValue<string>() ?? "";
        int version = args["expected_version"]?.GetValue<int>() ?? 0;
        if (!Guid.TryParse(expected, out _) || version < 1 || args["confirmed"]?.GetValue<bool>() != true) throw new BridgeError("journey_start_confirmation_required");
        await gate.WaitAsync(cancel);
        try
        {
            string secret = Credential(expected);
            if (context?["capabilities"] is not JsonArray scopes || !scopes.Any(node => node?.GetValue<string>() == "journey:manage")) throw new BridgeError("journey_management_permission_missing");
            string commander = context?["commander"]?["id"]?.GetValue<string>() ?? throw new BridgeError("api_context_invalid");
            // The game socket deliberately exposes Start only, not Finish/Reopen.
            // No automatic HTTP retry: a lost reply is recovered through a fresh context read.
            var response = await api.Send("POST", "/v1/game-journey/lifecycle", secret, new JsonObject
            {
                ["action"] = "start", ["expected_journey_id"] = expected, ["expected_version"] = version
            }, cancel);
            ValidateContext(response);
            if (response["journey_id"]?.GetValue<string>() != expected || response["commander"]?["id"]?.GetValue<string>() != commander) throw new BridgeError("journey_mismatch");
            if (response["status"]?.GetValue<string>() != "started") throw new BridgeError("journey_not_started");
            var projected = JourneyProjection.Context(response);
            if (projected["journey_version"]?.GetValue<int>() < version || projected["can_manage_journey"]?.GetValue<bool>() != true) throw new BridgeError("journey_start_response_invalid");
            cancel.ThrowIfCancellationRequested();
            lock (stateLock) { SaveContext(response); connection = "connected"; }
            return projected;
        }
        finally { gate.Release(); }
    }
    internal async Task<JsonObject> LinkOperation(string operation, JsonObject args, CancellationToken cancel)
    {
        await gate.WaitAsync(cancel);
        try
        {
            string expected = args["expected_journey_id"]?.GetValue<string>() ?? "";
            if (expected.Length == 0 || expected != Journey) throw new BridgeError("journey_mismatch");
            string secret = Credential(expected);
            return operation switch
            {
                "activation_status" => activations.Status(args),
                "activate" => await activations.Activate(args, secret, cancel, context?["commander"]?["id"]?.GetValue<string>() ?? throw new BridgeError("api_context_invalid")),
                "activation_ack" => activations.Acknowledge(args),
                _ => throw new BridgeError("operation_unknown")
            };
        }
        finally { gate.Release(); }
    }
    internal static void ValidateContext(JsonObject value)
    {
        _ = JourneyProjection.Title(value);
        if (!Guid.TryParse(value["journey_id"]?.GetValue<string>(), out _) || value["commander"] is not JsonObject || value["capabilities"] is not JsonArray scopes) throw new BridgeError("api_context_invalid");
        if (RequiredScopes.Any(scope => !scopes.Any(node => node?.GetValue<string>() == scope))) throw new BridgeError("scope_missing");
    }
    private void SaveContext(JsonObject value)
    {
        Directory.CreateDirectory(config.DataDirectory);
        value = (JsonObject)value.DeepClone();
        value["_tnb_title_observed_at"] = DateTimeOffset.UtcNow.ToString("O");
        // Store only the nonsecret context projection, never a credential or raw HTTP envelope.
        AtomicFiles.Write(ContextPath, value.ToJsonString());
        context = (JsonObject)value.DeepClone();
    }
}

internal static class AtomicFiles
{
    internal static void Write(string path, string text)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        string pending = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
        try
        {
            using (var file = new FileStream(pending, FileMode.CreateNew, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough))
            {
                var bytes = System.Text.Encoding.UTF8.GetBytes(text);
                file.Write(bytes);
                file.Flush(true);
            }
            File.Move(pending, path, true);
        }
        finally { if (File.Exists(pending)) File.Delete(pending); }
    }
}
