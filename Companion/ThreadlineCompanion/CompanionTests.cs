using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

internal static class CompanionTests
{
    internal const string JourneyId = "11111111-1111-4111-8111-111111111111";
    internal const string Secret = "tlj_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static void Check(bool condition, string message) { if (!condition) throw new Exception(message); }
    internal static JsonObject Context(bool allScopes = true) => new()
    {
        ["journey_id"] = JourneyId, ["journey_title"] = "Ren\u00e9's Resistance & Resolve", ["game_name"] = "XCOM 2", ["status"] = "started",
        ["commander"] = new JsonObject
        {
            ["id"] = "22222222-2222-4222-8222-222222222222", ["display_name"] = "Ren\u00e9",
            ["characteristics"] = new JsonObject
            {
                ["observed_at"] = "2026-10-18T12:00:00Z",
                ["traits"] = new JsonArray(new JsonObject
                {
                    ["definition"] = new JsonObject { ["id"] = "trait.resourceful", ["version"] = 2, ["catalog_version"] = "test", ["name"] = "Resourceful", ["polarity"] = "positive", ["acquisition_kind"] = "chosen" },
                    ["acquisition_source"] = "creation_selected"
                }),
                ["skills"] = new JsonArray(new JsonObject { ["id"] = "skill.quartermaster", ["version"] = 1, ["catalog_version"] = "test", ["name"] = "Quartermaster", ["provisional"] = false })
            }
        },
        ["capabilities"] = allScopes ? new JsonArray("roster:read", "instances:create", "instances:read", "events:write") : new JsonArray("roster:read")
    };
    internal static async Task<int> Run()
    {
        string data = Path.Combine(Path.GetTempPath(), "TNB-Tests-" + Guid.NewGuid().ToString("N"));
        try
        {
            var config = new Configuration(new Uri("https://example.invalid/"), 0, data, "test-protection", null);
            var vault = new MemoryVault();
            var handler = new FakeHandler();
            using var api = new ThreadlineApi(config, handler);
            var service = new ConnectionService(config, vault, api);
            await ActivationTests.Run(config);
            await LifecycleTests.Run(config);
            await JourneyTitleTests.Run(config);
            Check(!service.Status()["credential_stored"]!.GetValue<bool>(), "Fresh vault was marked stored");
            try { await service.Import("not-a-credential", CancellationToken.None); throw new Exception("Malformed credential was accepted"); }
            catch (BridgeError error) { Check(error.Code == "invalid_credential_format", "Malformed credential error was lost"); }
            Check(handler.Method == null, "Malformed credential reached the API");
            await service.Import(Secret, CancellationToken.None);
            Check(service.Status()["credential_stored"]!.GetValue<bool>(), "Successful import did not store credential");
            Check(handler.Auth == Secret && handler.Method == "GET", "Context used incorrect authorization or verb");
            Check(handler.Path?.Contains("project-protection-bypass=test-protection", StringComparison.Ordinal) == true, "Development protection query missing");
            Check(!service.Status().ToJsonString().Contains(Secret, StringComparison.Ordinal), "Status leaked a credential");
            Check(!File.ReadAllText(service.ContextPath).Contains(Secret, StringComparison.Ordinal), "Save leaked a credential");
            var preview = await service.PreviewContext(JourneyId, CancellationToken.None);
            Check(preview["traits"]?[0]?["definition_id"]?.GetValue<string>() == "trait.resourceful", "Nested Trait definition was not normalized");
            Check(preview["skills"]?[0]?["definition_id"]?.GetValue<string>() == "skill.quartermaster", "Direct Skill definition was not normalized");
            Check(!preview.ToJsonString().Contains(Secret, StringComparison.Ordinal) && preview["commander"] == null, "Raw context or credential escaped projection");
            var noCharacteristics = Context();
            noCharacteristics["commander"]!.AsObject().Remove("characteristics");
            Check(!JourneyProjection.Context(noCharacteristics)["characteristics_available"]!.GetValue<bool>(), "Missing characteristics were claimed available");
            var invalidDefinition = Context();
            invalidDefinition["commander"]!["characteristics"]!["traits"]![0]!["definition"]!["version"] = 0;
            try { JourneyProjection.Context(invalidDefinition); throw new Exception("Invalid definition version accepted"); }
            catch (BridgeError) { }
            var previewRoster = await service.PreviewRoster(JourneyId, "test & cursor", CancellationToken.None);
            Check(previewRoster["items"]?[0]?["character_id"]?.GetValue<string>() == "test-character", "Roster IDs lost");
            Check(handler.Path?.Contains("cursor=test%20%26%20cursor", StringComparison.Ordinal) == true, "Roster cursor not encoded");
            string? beforeMismatch = handler.Path;
            try { await service.PreviewRoster("another-journey", "", CancellationToken.None); throw new Exception("Cross-Journey roster accepted"); }
            catch (BridgeError error) { Check(error.Code == "journey_mismatch", "Cross-Journey error lost"); }
            Check(handler.Path == beforeMismatch, "Cross-Journey request reached API");
            handler.Status = HttpStatusCode.Unauthorized;
            try { await service.Import("tlj_" + new string('b',64), CancellationToken.None); throw new Exception("Rejected import succeeded"); }
            catch (BridgeError) { }
            Check(vault.Read(JourneyId) == Secret, "Invalid replacement overwrote the original credential");
            handler.Status = HttpStatusCode.OK;
            handler.AllScopes = false;
            try { await service.Import(Secret, CancellationToken.None); throw new Exception("Missing scopes were accepted"); }
            catch (BridgeError error) { Check(error.Code == "scope_missing", "Missing scopes error was lost"); }
            handler.AllScopes = true;
            var reopened = new ConnectionService(config, vault, api);
            Check(reopened.Status()["connection"]!.GetValue<string>() == "unverified", "Restart asserted a live connection without testing");
            var anotherEndpoint = new ConnectionService(config with { Api = new Uri("https://another.invalid/") }, vault, api);
            Check(anotherEndpoint.Journey == null, "Another endpoint reused saved Journey context");
            handler.FailNetwork = true;
            try { await reopened.Test(CancellationToken.None); throw new Exception("Offline test succeeded"); }
            catch (HttpRequestException) { }
            Check(reopened.Status()["credential_stored"]!.GetValue<bool>() && reopened.Status()["connection"]!.GetValue<string>() == "unable_to_verify", "Offline test invalidated the stored credential");
            handler.FailNetwork = false;
            await reopened.Test(CancellationToken.None);

            using var stopping = new CancellationTokenSource();
            var ready = new TaskCompletionSource<int>(TaskCreationOptions.RunContinuationsAsynchronously);
            var server = new LoopbackServer(reopened, 0).Run(stopping.Token, p => ready.SetResult(p));
            int port = await ready.Task;
            JsonObject ping = await Call(port, "{\"protocol\":2,\"request_id\":7,\"op\":\"ping\"}\n", true);
            Check(ping["ok"]!.GetValue<bool>() && ping["request_id"]!.GetValue<int>() == 7, "Fragmented loopback ping failed");
            JsonObject status = await Call(port, "{\"protocol\":2,\"request_id\":8,\"op\":\"status\"}\n");
            Check(status["data"]?["commander_name"]?.GetValue<string>() == "Ren\u00e9", "Unicode response did not roundtrip");
            var socketPreview = await Call(port, "{\"protocol\":2,\"request_id\":20,\"op\":\"journey_context\"}\n");
            Check(socketPreview["ok"]!.GetValue<bool>() && socketPreview["data"]?["traits"]?[0]?["definition_id"]?.GetValue<string>() == "trait.resourceful", "Socket context projection failed");
            var socketRoster = await Call(port, "{\"protocol\":2,\"request_id\":21,\"op\":\"roster\",\"args\":{\"expected_journey_id\":\"" + JourneyId + "\"}}\n");
            Check(socketRoster["ok"]!.GetValue<bool>(), "Socket pinned roster failed");
            handler.FailNetwork = true;
            var offline = await Call(port, "{\"protocol\":2,\"request_id\":11,\"op\":\"test\"}\n");
            Check(!offline["ok"]!.GetValue<bool>() && offline["data"]?["credential_stored"]?.GetValue<bool>() == true, "Failed verification lost vault-backed status");
            handler.FailNetwork = false;
            var wrongVersion = await Call(port, "{\"protocol\":1,\"request_id\":9,\"op\":\"ping\"}\n");
            Check(wrongVersion["error"]!.GetValue<string>() == "protocol_mismatch", "Protocol mismatch accepted");
            var browser = await Call(port, "GET / HTTP/1.1\r\n");
            Check(!browser["ok"]!.GetValue<bool>(), "HTTP browser request accepted as RPC");
            var unknown = await Call(port, "{\"protocol\":2,\"request_id\":10,\"op\":\"raw_http\"}\n");
            Check(unknown["error"]!.GetValue<string>() == "operation_unknown", "Arbitrary HTTP forwarding allowed");
            foreach (string operation in new[] { "import", "remove" })
            {
                var rejected = await Call(port, "{\"protocol\":2,\"request_id\":12,\"op\":\"" + operation + "\"}\n");
                Check(rejected["error"]!.GetValue<string>() == "operation_unknown", "Credential mutation allowed over the game socket");
            }
            var parallel = await Task.WhenAll(Enumerable.Range(0, 8).Select(i => Call(port, "{\"protocol\":2,\"request_id\":" + i + ",\"op\":\"ping\"}\n")));
            Check(parallel.All(item => item["ok"]!.GetValue<bool>()), "Concurrent client handling failed");
            stopping.Cancel();
            await server;
            await reopened.Remove(CancellationToken.None);
            Check(!reopened.Status()["credential_stored"]!.GetValue<bool>(), "Credential removal did not refresh status");

            // Use a unique, synthetic vault target; never touch the active development Journey.
            var windows = new WindowsSecrets(new Uri("https://tnb-vault-self-test.invalid/"));
            string testJourney = Guid.NewGuid().ToString();
            try
            {
                windows.Write(testJourney, Secret);
                Check(windows.Read(testJourney) == Secret, "Windows vault roundtrip failed");
            }
            finally { windows.Remove(testJourney); }
            Check(windows.Read(testJourney) == null, "Windows vault cleanup failed");
            Console.WriteLine("PASS: credentials/scopes, context persistence, nested Traits/direct Skills, Journey-pinned read-only roster, cursor encoding, malformed projection rejection, socket preview, redaction, TCP lifecycle and isolated Windows vault roundtrip.");
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine("Companion self-test failed: " + (error is BridgeError bridge ? bridge.Code : error.GetType().Name));
            return 1;
        }
        finally
        {
            // Only the unique directory created by this self-test is removed.
            if (Path.GetFileName(data).StartsWith("TNB-Tests-", StringComparison.Ordinal) && Directory.Exists(data)) Directory.Delete(data, true);
        }
    }
    internal static async Task<JsonObject> Call(int port, string text, bool fragment = false)
    {
        using var client = new TcpClient();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
        await client.ConnectAsync(IPAddress.Loopback, port, timeout.Token);
        var bytes = Encoding.ASCII.GetBytes(text);
        if (fragment)
        {
            await client.GetStream().WriteAsync(bytes.AsMemory(0, 5), timeout.Token);
            await Task.Delay(20, timeout.Token);
            await client.GetStream().WriteAsync(bytes.AsMemory(5), timeout.Token);
        }
        else await client.GetStream().WriteAsync(bytes, timeout.Token);
        return JsonNode.Parse(await LoopbackServer.ReadFrame(client.GetStream(), timeout.Token)) as JsonObject ?? throw new Exception("Invalid response");
    }
    internal sealed class MemoryVault : ISecretStore
    {
        private readonly ConcurrentDictionary<string, string> values = new();
        public string? Read(string journey) => values.GetValueOrDefault(journey);
        public void Write(string journey, string secret) => values[journey] = secret;
        public void Remove(string journey) => values.TryRemove(journey, out _);
    }
    internal sealed class FakeHandler : HttpMessageHandler
    {
        internal HttpStatusCode Status = HttpStatusCode.OK;
        internal bool AllScopes = true, FailNetwork;
        internal string? Auth, Method, Path;
        internal string? JourneyTitle;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancel)
        {
            if (FailNetwork) throw new HttpRequestException("Synthetic offline test");
            Auth = request.Headers.Authorization?.Parameter;
            Method = request.Method.Method;
            Path = request.RequestUri?.PathAndQuery;
            var roster = new JsonObject { ["items"] = new JsonArray(new JsonObject { ["character_id"] = "test-character", ["roster_entry_id"] = "test-roster-entry", ["display_name"] = "<Ren\u00e9 & Co>", ["eligible"] = true }), ["next_cursor"] = "next test cursor" };
            var context = Context(AllScopes);
            if (JourneyTitle != null) context["journey_title"] = JourneyTitle;
            var body = Status == HttpStatusCode.OK ? new JsonObject { ["data"] = request.RequestUri?.AbsolutePath.EndsWith("/roster", StringComparison.Ordinal) == true ? roster : context } : new JsonObject { ["error"] = new JsonObject { ["code"] = "invalid_credential" } };
            return Task.FromResult(new HttpResponseMessage(Status) { Content = new StringContent(body.ToJsonString()) });
        }
    }
}
