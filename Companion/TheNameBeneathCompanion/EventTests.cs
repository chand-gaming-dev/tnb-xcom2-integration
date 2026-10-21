using System.Globalization;
using System.Net;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal static class EventTests
{
    internal const string Commander = "22222222-2222-4222-8222-222222222222";
    internal const string Instance = "33333333-3333-4333-8333-333333333333";
    private static void Check(bool value, string name) { if (!value) throw new BridgeError("event_test_" + name); }
    internal static JsonObject Capture(string type = "threadline.mission.completed", string key = "mission:42:complete") => new()
    {
        ["expected_journey_id"] = CompanionTests.JourneyId, ["expected_commander_id"] = Commander, ["campaign_id"] = "test-campaign",
        ["sender_local_now"] = DateTime.Now.ToString("yyyy-MM-dd'T'HH:mm:ss.fff", CultureInfo.InvariantCulture),
        ["capture"] = new JsonObject
        {
            ["key"] = key, ["mission_key"] = "mission:42:seed:87654", ["captured_local"] = DateTime.Now.AddMinutes(-1).ToString("yyyy-MM-dd'T'HH:mm:ss.fff", CultureInfo.InvariantCulture),
            ["clock_zone"] = TimeZoneInfo.Local.Id,
            ["event_type"] = type, ["summary"] = "René completed 雪 mission", ["participants"] = new JsonArray(Instance),
            ["facts"] = new JsonObject { ["result"] = "success" }, ["game_data"] = new JsonObject { ["mission_kind"] = "tactical" }
        }
    };
    internal static async Task<int> Run(string? nativeLog = null)
    {
        string root = Path.Combine(Path.GetTempPath(), "TNB-EventTests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        var config = new Configuration(new Uri("https://events-tests.invalid/"), 0, root, null, null);
        var fixtures = new JsonArray();
        foreach (string type in new[] { "mission.started", "mission.character_deployed", "mission.completed", "character.promoted", "character.injured", "character.recovered", "character.died" })
        {
            var capture = Capture("threadline." + type, type);
            capture["capture"]!["facts"] = type switch
            {
                "mission.started" => new JsonObject { ["mission_name"] = "Test" },
                "mission.character_deployed" => new JsonObject { ["deployment_kind"] = "tactical" },
                "mission.completed" => new JsonObject { ["result"] = "success", ["squad_deaths"] = 0 },
                "character.promoted" => new JsonObject { ["from_rank"] = "1", ["to_rank"] = "2" },
                "character.injured" => new JsonObject { ["injury_code"] = "xcom2_negative_trait" },
                "character.recovered" => new JsonObject { ["recovery"] = "full" },
                _ => new JsonObject { ["local_finality"] = "dead" }
            };
            fixtures.Add(EventContractValidator.Build(capture, out _));
        }
        var commanderOnly = Capture(key: "commander-only");
        commanderOnly["capture"]!["participants"] = new JsonArray();
        commanderOnly["capture"]!["game_data"]!["mission_kind"] = "covert_action";
        fixtures.Add(EventContractValidator.Build(commanderOnly, out _));
        if (nativeLog != null)
        {
            const string marker = "TNB_NATIVE_CAPTURE=";
            string line = File.ReadLines(nativeLog).First(l => l.Contains(marker, StringComparison.Ordinal));
            var nativeCapture = JsonNode.Parse(line[(line.IndexOf(marker, StringComparison.Ordinal) + marker.Length)..])!.AsObject();
            Check(nativeCapture["summary"]?.GetValue<string>() == "René 雪", "native_unicode_roundtrip");
            nativeCapture["clock_zone"] = TimeZoneInfo.Local.Id;
            var args = Capture(); args["capture"] = nativeCapture;
            fixtures.Add(EventContractValidator.Build(args, out _));
            Console.WriteLine("Native SDK capture/Unicode shape validated by companion.");
        }
        BondMilestoneTests.Run(config, fixtures, nativeLog);
        FactualEventTests.Run(config, fixtures, nativeLog);
        AtomicFiles.Write(Path.Combine(root, "contract-fixtures.json"), fixtures.ToJsonString());
        var outbox = new EventOutbox(config);
        var limited = new EventOutbox(config with { DataDirectory = Path.Combine(root, "capacity") }, 1);
        limited.Enqueue(Capture(key: "capacity-one"));
        try { limited.Enqueue(Capture(key: "capacity-two")); throw new Exception("Full queue accepted"); } catch (BridgeError e) { Check(e.Code == "event_queue_full", "capacity"); }
        Check(limited.Status(CompanionTests.JourneyId)["queued"]!.GetValue<int>() == 1, "full_preserves_first");
        var tiny = new EventOutbox(config with { DataDirectory = Path.Combine(root, "byte-capacity") }, 10, 100);
        try { tiny.Enqueue(Capture(key: "byte-capacity")); throw new Exception("Byte capacity ignored"); } catch (BridgeError e) { Check(e.Code == "event_queue_full", "byte_capacity"); }
        var first = Capture();
        var handoff = outbox.Enqueue(first);
        Check(handoff["durable"]!.GetValue<bool>(), "durable_ack");
        var replay = (JsonObject)first.DeepClone();
        replay["capture"]!["captured_local"] = DateTime.Now.ToString("yyyy-MM-dd'T'HH:mm:ss.fff", CultureInfo.InvariantCulture);
        Check(outbox.Enqueue(replay).ToJsonString() == handoff.ToJsonString(), "clock_replay");
        outbox = new EventOutbox(config);
        Check(outbox.Enqueue(replay).ToJsonString() == handoff.ToJsonString(), "restart_replay");
        replay["capture"]!["captured_local"] = "invalid-later-clock";
        Check(outbox.Enqueue(replay).ToJsonString() == handoff.ToJsonString(), "replay_ignores_clock");
        replay["capture"]!["facts"]!["result"] = "failure";
        try { outbox.Enqueue(replay); throw new Exception("Conflict accepted"); } catch (BridgeError e) { Check(e.Code == "event_replay_conflict", "conflict"); }
        Check(outbox.Status(CompanionTests.JourneyId)["queued"]!.GetValue<int>() == 1, "original_preserved");
        var record = outbox.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow)!;
        Check(outbox.Next("44444444-4444-4444-8444-444444444444", DateTimeOffset.UtcNow) == null, "journey_pin");
        outbox.Failed(record, new BridgeError("rate_limited", 429, TimeSpan.FromMinutes(5)), DateTimeOffset.UtcNow);
        Check(outbox.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow.AddMinutes(1)) == null, "retry_after");
        outbox.Retry(CompanionTests.JourneyId, "test-campaign");
        record = outbox.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow)!;
        outbox.Failed(record, new BridgeError("event_id_conflict", 409), DateTimeOffset.UtcNow);
        outbox.Retry(CompanionTests.JourneyId, null);
        Check(outbox.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow.AddDays(1)) == null, "held_no_retry");
        var dependent = Capture(key: "same-occurrence-next");
        outbox.Enqueue(dependent);
        Check(outbox.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow.AddDays(1)) == null, "occurrence_ordering");
        var unrelated = Capture(key: "independent"); unrelated["capture"]!["mission_key"] = "independent-mission";
        string unrelatedId = outbox.Enqueue(unrelated)["event_id"]!.GetValue<string>();
        Check(outbox.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow)!.Payload["event_id"]!.GetValue<string>() == unrelatedId, "unrelated_proceeds");
        // Keep these independent policy cases separate from subsequent delivery-service counts.
        var unrelatedRecord = outbox.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow)!;
        outbox.Failed(unrelatedRecord, new BridgeError("validation_error", 422), DateTimeOffset.UtcNow);
        var bad = Capture(key: "bad"); bad["capture"]!["facts"]!["invented"] = true;
        try { EventContractValidator.Build(bad, out _); throw new Exception("Unknown fact accepted"); } catch (BridgeError) { }
        bad = Capture(key: "bad-date"); bad["capture"]!["captured_local"] = "2035-01-01T00:00:00.000";
        try { EventContractValidator.Build(bad, out _); throw new Exception("Game calendar accepted"); } catch (BridgeError) { }
        bad = Capture(key: "large"); bad["capture"]!["game_data"]!["oversized"] = new string('a', 50000);
        try { outbox.Enqueue(bad); throw new Exception("Oversized payload accepted"); } catch (BridgeError) { }
        var empty = Capture(key: "ue-empty"); empty["capture"]!["participants"] = new JsonObject();
        Check(EventContractValidator.Build(empty, out _)["participants"]!.AsArray().Count == 0, "ue_empty_array");
        string blocked = Path.Combine(root, "blocked-data-root"); AtomicFiles.Write(blocked, "not a directory");
        var blockedOutbox = new EventOutbox(config with { DataDirectory = blocked });
        try { blockedOutbox.Enqueue(Capture(key: "disk-failure")); throw new Exception("Non-durable write acknowledged"); } catch (IOException) { }
        var fake = new EventHandler();
        using var api = new JourneyApi(config, fake);
        var vault = new TestVault();
        var service = new ConnectionService(config, vault, api);
        await service.Import(CompanionTests.Secret, CancellationToken.None);
        var networkCapture = Capture(key: "network");
        networkCapture["capture"]!["mission_key"] = "another-mission";
        await service.EventOperation("events_enqueue", networkCapture, CancellationToken.None);
        fake.DropAfterAccept = true;
        await service.DeliverOne(CancellationToken.None);
        Check(service.ReportingStatus()["retrying"]!.GetValue<int>() == 1, "lost_http_response");
        service.RetryReporting();
        await service.DeliverOne(CancellationToken.None);
        Check(service.ReportingStatus()["accepted"]!.GetValue<int>() == 1 && fake.Payloads.Count == 2 && fake.Payloads[0] == fake.Payloads[1], "exact_http_replay");
        var restarted = new ConnectionService(config, vault, api);
        Check(restarted.ReportingStatus()["accepted"]!.GetValue<int>() == 1, "receipt_restart");
        var invalidReceipt = Capture(key: "receipt-invalid"); invalidReceipt["capture"]!["mission_key"] = "receipt-mission";
        await restarted.EventOperation("events_enqueue", invalidReceipt, CancellationToken.None);
        fake.InvalidReceipt = true;
        await restarted.DeliverOne(CancellationToken.None);
        Check(restarted.ReportingStatus()["accepted"]!.GetValue<int>() == 1 && restarted.ReportingStatus()["retrying"]!.GetValue<int>() == 1, "malformed_receipt_unaccepted");
        fake.InvalidReceipt = false;
        restarted.RetryReporting();
        fake.ErrorStatus = HttpStatusCode.Unauthorized;
        await restarted.DeliverOne(CancellationToken.None);
        Check(restarted.ReportingStatus()["paused"]!.GetValue<int>() == 1 && !await restarted.DeliverOne(CancellationToken.None), "unauthorized_pauses");
        fake.ErrorStatus = null;
        restarted.RetryReporting();
        await restarted.DeliverOne(CancellationToken.None);
        using (var cancel = new CancellationTokenSource())
        {
            var ready = new TaskCompletionSource<int>(TaskCreationOptions.RunContinuationsAsynchronously);
            var server = new LoopbackServer(restarted, 0).Run(cancel.Token, p => ready.SetResult(p));
            int port = await ready.Task;
            var socketArgs = Capture(key: "socket-unicode"); socketArgs["capture"]!["mission_key"] = "socket-mission";
            var request = new JsonObject { ["protocol"] = 2, ["request_id"] = 57, ["op"] = "events_enqueue", ["args"] = socketArgs };
            string frame = request.ToJsonString() + "\n";
            Check(frame.All(c => c < 128), "socket_ascii");
            var reply = await CompanionTests.Call(port, frame, true);
            Check(reply["ok"]!.GetValue<bool>() && reply["data"]?["durable"]?.GetValue<bool>() == true, "socket_durable");
            var repeated = await CompanionTests.Call(port, frame);
            Check(reply.ToJsonString() == repeated.ToJsonString(), "lost_socket_reply");
            socketArgs["expected_journey_id"] = "44444444-4444-4444-8444-444444444444";
            var wrong = await CompanionTests.Call(port, request.ToJsonString() + "\n");
            Check(wrong["error"]?.GetValue<string>() == "journey_mismatch", "socket_wrong_journey");
            cancel.Cancel(); await server;
        }
        fake.BlockPost = true;
        var deliveryTask = restarted.DeliverOne(CancellationToken.None);
        await fake.PostEntered.Task;
        fake.ContextJourney = "44444444-4444-4444-8444-444444444444";
        var importTask = restarted.Import("tlj_" + new string('b', 64), CancellationToken.None);
        await Task.Delay(25);
        Check(!importTask.IsCompleted, "credential_guard");
        fake.ReleasePost.SetResult();
        await deliveryTask; await importTask;
        Check(!await restarted.DeliverOne(CancellationToken.None) && restarted.ReportingStatus()["accepted"]!.GetValue<int>() == 0, "other_journey_pauses");
        fake.ContextJourney = CompanionTests.JourneyId;
        await restarted.Import(CompanionTests.Secret, CancellationToken.None);
        Check(restarted.ReportingStatus()["accepted"]!.GetValue<int>() == 3, "same_journey_resumes_receipts");
        var receiptQuery = new JsonObject
        {
            ["expected_journey_id"] = CompanionTests.JourneyId, ["campaign_id"] = "test-campaign",
            ["event_ids"] = new JsonArray(EventContractValidator.EventId(CompanionTests.JourneyId, "test-campaign", "network"))
        };
        var receipts = await restarted.EventOperation("events_receipts", receiptQuery, CancellationToken.None);
        Check(receipts["records"]?[0]?["accepted_online"]?.GetValue<bool>() == true, "receipt_query");
        receiptQuery["campaign_id"] = "other-campaign";
        Check((await restarted.EventOperation("events_receipts", receiptQuery, CancellationToken.None))["records"]!.AsArray().Count == 0, "receipt_scope");
        await restarted.Remove(CancellationToken.None);
        Check(restarted.ReportingStatus()["accepted"]!.GetValue<int>() == 3 && !await restarted.DeliverOne(CancellationToken.None), "remove_retains_receipt");
        var journal = Directory.EnumerateFiles(Path.Combine(root, "events-v1"), "*.json", SearchOption.AllDirectories).First(p => !p.EndsWith(".conflict.json", StringComparison.Ordinal));
        AtomicFiles.Write(journal, "{damaged");
        var damaged = new EventOutbox(config);
        Check(damaged.Status(CompanionTests.JourneyId)["endpoint_damaged_files"]!.GetValue<int>() == 1 && File.ReadAllText(journal) == "{damaged", "corrupt_preserved");
        Console.WriteLine("Event journal, replay, restart, retry, credential and fake-HTTP checks passed.");
        Console.WriteLine("Contract fixtures: " + Path.Combine(root, "contract-fixtures.json"));
        return 0;
    }
    private sealed class TestVault : ISecretStore
    {
        private readonly Dictionary<string, string> values = new();
        public string? Read(string id) => values.GetValueOrDefault(id);
        public void Write(string id, string value) => values[id] = value;
        public void Remove(string id) => values.Remove(id);
    }
    private sealed class EventHandler : HttpMessageHandler
    {
        internal bool DropAfterAccept;
        internal bool InvalidReceipt;
        internal HttpStatusCode? ErrorStatus;
        internal string ContextJourney = CompanionTests.JourneyId;
        internal bool BlockPost;
        internal TaskCompletionSource PostEntered = new(TaskCreationOptions.RunContinuationsAsynchronously);
        internal TaskCompletionSource ReleasePost = new(TaskCreationOptions.RunContinuationsAsynchronously);
        internal List<string> Payloads = [];
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancel)
        {
            if (request.Method == HttpMethod.Get)
            {
                var context = CompanionTests.Context(); context["journey_id"] = ContextJourney; return Response(context);
            }
            if (BlockPost) { PostEntered.TrySetResult(); await ReleasePost.Task.WaitAsync(cancel); }
            if (ErrorStatus is { } status) return new HttpResponseMessage(status) { Content = new StringContent("{\"error\":{\"code\":\"invalid_credential\"}}") };
            string body = await request.Content!.ReadAsStringAsync(cancel);
            Payloads.Add(body);
            if (DropAfterAccept) { DropAfterAccept = false; throw new HttpRequestException("simulated lost reply"); }
            var payload = JsonNode.Parse(body)!;
            return Response(new JsonObject
            {
                ["status"] = "duplicate", ["raw_event_id"] = Guid.NewGuid().ToString(), ["event_id"] = payload["event_id"]!.DeepClone(),
                ["journey_id"] = payload["journey_id"]!.DeepClone(), ["commander_id"] = InvalidReceipt ? Instance : Commander, ["occurred_at"] = payload["occurred_at"]!.DeepClone(),
                ["ingested_at"] = DateTimeOffset.UtcNow.ToString("O"), ["source_confidence"] = "operator_reported", ["gameplay_attested"] = false
            });
        }
        private static HttpResponseMessage Response(JsonObject data) => new(HttpStatusCode.OK) { Content = new StringContent(new JsonObject { ["data"] = data }.ToJsonString()) };
    }
}
