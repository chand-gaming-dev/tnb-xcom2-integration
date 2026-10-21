using System.Net;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal static class ActivationTests
{
    private static void Check(bool condition) { if (!condition) throw new BridgeError("activation_test_failed"); }
    private static async Task Reject(Func<Task> operation, string expected)
    {
        try { await operation(); throw new BridgeError("activation_test_failed"); }
        catch (BridgeError error) when (error.Code == expected) { }
    }
    internal static async Task Run(Configuration config)
    {
        var handler = new Handler();
        using var api = new JourneyApi(config, handler);
        var journal = new ActivationReceipts(config, api);
        var args = new JsonObject { ["expected_journey_id"] = CompanionTests.JourneyId, ["campaign_id"] = "synthetic-campaign", ["unit_id"] = 42,
            ["unit_token"] = "synthetic-intent-A", ["unit_fingerprint"] = "synthetic-soldier-A", ["character_id"] = "synthetic-character", ["roster_entry_id"] = "synthetic-roster" };
        handler.BeforeSend = () => Check(File.Exists(journal.PathFor(CompanionTests.JourneyId, "synthetic-campaign")));
        handler.FailNetwork = true; // fake server activates, but the reply is lost
        try { await journal.Activate(args, CompanionTests.Secret, CancellationToken.None); throw new BridgeError("activation_test_failed"); }
        catch (HttpRequestException) { }
        Check(journal.Status(args)["receipt"]?["state"]?.GetValue<string>() == "pending");
        handler.FailNetwork = false;
        var instance = await new ActivationReceipts(config, api).Activate(args, CompanionTests.Secret, CancellationToken.None);
        Check(handler.Created == 1 && handler.Calls == 2);
        Check(instance["traits"]?[0]?["definition_id"]?.GetValue<string>() == "trait.hardy" && instance["skills"]?[0]?["definition_id"]?.GetValue<string>() == "skill.evasive-maneuvers");
        int calls = handler.Calls;
        await journal.Activate(args, CompanionTests.Secret, CancellationToken.None);
        Check(handler.Calls == calls); // same confirmed intent recovers without another POST
        foreach (string key in new[] { "unit_id", "character_id", "unit_fingerprint", "roster_entry_id" })
        {
            var conflicting = (JsonObject)args.DeepClone();
            if (key == "unit_id") conflicting[key] = 43; else conflicting[key] = "conflicting-value";
            await Reject(() => journal.Activate(conflicting, CompanionTests.Secret, CancellationToken.None), "unit_link_conflict");
        }
        args["instance_id"] = "synthetic-instance";
        journal.Acknowledge(args);
        journal.Acknowledge(args);
        Check(journal.Status(args)["receipt"]?["state"]?.GetValue<string>() == "acknowledged");
        await journal.Activate(args, CompanionTests.Secret, CancellationToken.None);
        Check(handler.Calls == calls);

        // A pre-link loaded save supplies NO confirmed intent. Do not restore or lock from history.
        var beforeLink = (JsonObject)args.DeepClone();
        beforeLink.Remove("unit_token"); beforeLink.Remove("unit_fingerprint");
        Check(journal.Status(beforeLink)["receipt"] == null && journal.Status(beforeLink)["feature_version"]?.GetValue<int>() == 2);

        // Soldier B -> the SAME character after rewind: new intent, reauthorize, same original instance/snapshot.
        var soldierB = (JsonObject)args.DeepClone();
        soldierB["unit_id"] = 43; soldierB["unit_token"] = "synthetic-intent-B"; soldierB["unit_fingerprint"] = "synthetic-soldier-B";
        handler.CanonicalRevision = 1;
        var reused = await journal.Activate(soldierB, CompanionTests.Secret, CancellationToken.None);
        Check(handler.Calls == calls + 1 && handler.Created == 1);
        Check(reused.ToJsonString() == instance.ToJsonString()); // no refresh despite canonical changes
        journal.Acknowledge(soldierB);

        // Soldier A -> a DIFFERENT character after rewind: old attempt no longer owns that unit.
        var otherCharacter = (JsonObject)args.DeepClone();
        otherCharacter["unit_token"] = "synthetic-intent-A-new-character";
        otherCharacter["character_id"] = "another-character"; otherCharacter["roster_entry_id"] = "another-roster";
        var other = await journal.Activate(otherCharacter, CompanionTests.Secret, CancellationToken.None);
        Check(other["instance_id"]?.GetValue<string>() != instance["instance_id"]?.GetValue<string>() && handler.Created == 2);
        Check(journal.Status(args)["receipt"]?["instance"]?["instance_id"]?.GetValue<string>() == "synthetic-instance");
        Check(journal.Status(otherCharacter)["receipt"]?["instance"]?["character_id"]?.GetValue<string>() == "another-character");

        // Another fresh intent for A -> the original character also reuses it (not the latest unit receipt).
        var again = (JsonObject)args.DeepClone(); again["unit_token"] = "synthetic-intent-A-original-again";
        Check((await journal.Activate(again, CompanionTests.Secret, CancellationToken.None)).ToJsonString() == instance.ToJsonString());
        Check(handler.Created == 2);
        calls = handler.Calls;
        await journal.Activate(again, CompanionTests.Secret, CancellationToken.None);
        Check(handler.Calls == calls);

        // Existing cached instances must NOT bypass current authorization for a new pairing.
        var withdrawn = (JsonObject)args.DeepClone(); withdrawn["unit_token"] = "synthetic-new-intent-withdrawn";
        handler.Withdrawn = true;
        await Reject(() => journal.Activate(withdrawn, CompanionTests.Secret, CancellationToken.None), "roster_not_eligible");
        Check(journal.Status(withdrawn)["receipt"]?["state"]?.GetValue<string>() == "pending");
        handler.Withdrawn = false;

        // Legacy schema-1 receipts remain recoverable by exact token, then migrate non-destructively.
        var legacy = (JsonObject)args.DeepClone(); legacy["campaign_id"] = "synthetic-legacy-campaign";
        AtomicFiles.Write(journal.PathFor(CompanionTests.JourneyId, "synthetic-legacy-campaign"), new JsonObject
        {
            ["schema"] = 1, ["journey_id"] = CompanionTests.JourneyId, ["campaign_id"] = "synthetic-legacy-campaign",
            ["receipts"] = new JsonArray(journal.Status(args)["receipt"]!.DeepClone())
        }.ToJsonString());
        Check((await journal.Activate(legacy, CompanionTests.Secret, CancellationToken.None)).ToJsonString() == instance.ToJsonString());
        journal.Acknowledge(legacy);
        var migrated = JsonNode.Parse(File.ReadAllText(journal.PathFor(CompanionTests.JourneyId, "synthetic-legacy-campaign")))!;
        Check(migrated["schema"]?.GetValue<int>() == 2 && migrated["receipts"]?.AsArray().Count == 1);
        var badJournalArgs = (JsonObject)legacy.DeepClone(); badJournalArgs["campaign_id"] = "synthetic-damaged-journal";
        AtomicFiles.Write(journal.PathFor(CompanionTests.JourneyId, "synthetic-damaged-journal"), new JsonObject
        {
            ["schema"] = 2, ["journey_id"] = CompanionTests.JourneyId, ["campaign_id"] = "synthetic-damaged-journal",
            ["receipts"] = new JsonArray(journal.Status(args)["receipt"]!.DeepClone(), journal.Status(args)["receipt"]!.DeepClone())
        }.ToJsonString());
        calls = handler.Calls;
        await Reject(() => journal.Activate(badJournalArgs, CompanionTests.Secret, CancellationToken.None), "link_journal_invalid");
        Check(handler.Calls == calls);

        string disk = File.ReadAllText(journal.PathFor(CompanionTests.JourneyId, "synthetic-campaign"));
        Check(!disk.Contains(CompanionTests.Secret, StringComparison.Ordinal) && !disk.Contains("test-protection", StringComparison.Ordinal));
        var malformed = Instance(); malformed["character_id"] = "wrong";
        try { JourneyProjection.Instance(malformed, CompanionTests.JourneyId, "synthetic-character", "synthetic-roster"); throw new BridgeError("activation_test_failed"); }
        catch (BridgeError error) when (error.Code == "instance_mismatch") { }
        malformed = Instance(); malformed["snapshot"]!["version"] = 4;
        try { JourneyProjection.Instance(malformed, CompanionTests.JourneyId, "synthetic-character", "synthetic-roster"); throw new BridgeError("activation_test_failed"); }
        catch (BridgeError error) when (error.Code == "snapshot_version_unsupported") { }

        var vault = new CompanionTests.MemoryVault();
        var service = new ConnectionService(config, vault, api);
        await service.Import(CompanionTests.Secret, CancellationToken.None);
        var wrongJourney = (JsonObject)args.DeepClone(); wrongJourney["expected_journey_id"] = "another-journey";
        await Reject(() => service.LinkOperation("activate", wrongJourney, CancellationToken.None), "journey_mismatch");
        var socketArgs = (JsonObject)args.DeepClone(); socketArgs["campaign_id"] = "synthetic-socket-campaign";
        using var stopping = new CancellationTokenSource();
        var ready = new TaskCompletionSource<int>(TaskCreationOptions.RunContinuationsAsynchronously);
        var server = new LoopbackServer(service, 0).Run(stopping.Token, p => ready.SetResult(p));
        int port = await ready.Task;
        try
        {
            var ping = await CompanionTests.Call(port, "{\"protocol\":2,\"request_id\":3,\"op\":\"ping\"}\n");
            Check(ping["data"]?["armory_link_version"]?.GetValue<int>() == 2);
            foreach (string operation in new[] { "activation_status", "activate", "activation_ack", "activation_status" })
            {
                var request = new JsonObject { ["protocol"] = 2, ["request_id"] = 1, ["op"] = operation, ["args"] = socketArgs.DeepClone() };
                var response = await CompanionTests.Call(port, request.ToJsonString() + "\n");
                Check(response["ok"]?.GetValue<bool>() == true && !response.ToJsonString().Contains(CompanionTests.Secret, StringComparison.Ordinal));
                if (operation == "activate") Check(response["data"]?["instance_id"]?.GetValue<string>() == "synthetic-instance");
            }
            var requestNoIntent = (JsonObject)socketArgs.DeepClone(); requestNoIntent.Remove("unit_token");
            var responseNoIntent = await CompanionTests.Call(port, new JsonObject { ["protocol"] = 2, ["request_id"] = 2, ["op"] = "activation_status", ["args"] = requestNoIntent }.ToJsonString() + "\n");
            Check(responseNoIntent["ok"]?.GetValue<bool>() == true && responseNoIntent["data"]?["receipt"] == null);
        }
        finally { stopping.Cancel(); await server; }

        var cancelledArgs = (JsonObject)args.DeepClone(); cancelledArgs["campaign_id"] = "synthetic-cancelled-campaign";
        handler.Started = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        handler.Hold = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously).Task;
        using (var cancelled = new CancellationTokenSource())
        {
            var activation = journal.Activate(cancelledArgs, CompanionTests.Secret, cancelled.Token);
            await handler.Started.Task.WaitAsync(TimeSpan.FromSeconds(3));
            cancelled.Cancel();
            try { await activation; throw new BridgeError("activation_test_failed"); }
            catch (OperationCanceledException) { }
        }
        Check(journal.Status(cancelledArgs)["receipt"]?["state"]?.GetValue<string>() == "pending");
        handler.Hold = null; handler.Started = null;
        await new ActivationReceipts(config, api).Activate(cancelledArgs, CompanionTests.Secret, CancellationToken.None);
        Check(journal.Status(cancelledArgs)["receipt"]?["state"]?.GetValue<string>() == "activated");
        var duplicate = Instance(); duplicate["snapshot"]!["traits"]!.AsArray().Add(duplicate["snapshot"]!["traits"]![0]!.DeepClone());
        try { JourneyProjection.Instance(duplicate, CompanionTests.JourneyId, "synthetic-character", "synthetic-roster"); throw new BridgeError("activation_test_failed"); }
        catch (BridgeError error) when (error.Code == "api_response_invalid") { }
        Console.WriteLine("PASS: save-authoritative rewind (A->C then B->C; A->C then A->D), immutable instance reuse/reauthorization, intent-scoped retry/ack/cancellation, legacy migration, exact POST, socket status and redaction (fake API only).");
    }
    internal static JsonObject Instance(string character = "synthetic-character")
    {
        bool original = character == "synthetic-character";
        return new JsonObject
        {
            ["id"] = original ? "synthetic-instance" : "another-instance", ["journey_id"] = CompanionTests.JourneyId, ["character_id"] = character, ["commander_id"] = "22222222-2222-4222-8222-222222222222",
            ["roster_entry_id"] = original ? "synthetic-roster" : "another-roster", ["onboarding_mode"] = "bind_existing",
            ["snapshot"] = new JsonObject
            {
                ["id"] = original ? "synthetic-snapshot" : "another-snapshot", ["journey_id"] = CompanionTests.JourneyId, ["identity_id"] = character, ["identity_type"] = "character",
                ["version"] = 3, ["issued_at"] = "2026-10-19T12:00:00Z", ["authorization_decision_id"] = "synthetic-authorization",
                ["identity"] = new JsonObject { ["display_name"] = "<Ren\u00e9 & Co>" },
                ["traits"] = new JsonArray(new JsonObject { ["definition"] = new JsonObject { ["id"] = "trait.hardy", ["version"] = 1, ["catalog_version"] = "synthetic", ["name"] = "Hardy", ["acquisition_kind"] = "starting", ["polarity"] = "positive" }, ["acquisition_source"] = "creation_selected" }),
                ["skills"] = new JsonArray(new JsonObject { ["id"] = "skill.evasive-maneuvers", ["version"] = 1, ["catalog_version"] = "synthetic", ["name"] = "Evasive Maneuvers", ["provisional"] = false }),
                ["gameplay_effects"] = new JsonArray()
            }
        };
    }
    private sealed class Handler : HttpMessageHandler
    {
        internal Action? BeforeSend;
        internal bool FailNetwork, Withdrawn;
        internal int Calls, Created, CanonicalRevision;
        internal TaskCompletionSource? Started;
        internal Task? Hold;
        private readonly Dictionary<string, JsonObject> instances = new(StringComparer.Ordinal);
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancel)
        {
            if (request.Method == HttpMethod.Get && request.RequestUri?.AbsolutePath == "/v1/game-journey")
                return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(new JsonObject { ["data"] = CompanionTests.Context() }.ToJsonString()) };
            Calls++; BeforeSend?.Invoke();
            var body = JsonNode.Parse(await request.Content!.ReadAsStringAsync(cancel))!.AsObject();
            Check(request.Method == HttpMethod.Post && body.Count == 2 && body["onboarding_mode"]?.GetValue<string>() == "bind_existing" && body["character_id"] != null);
            Started?.TrySetResult();
            if (Hold != null) await Hold.WaitAsync(cancel);
            if (Withdrawn) return new HttpResponseMessage(HttpStatusCode.Forbidden) { Content = new StringContent("{\"error\":{\"code\":\"roster_not_eligible\"}}") };
            string character = body["character_id"]!.GetValue<string>();
            if (!instances.TryGetValue(character, out var instance))
            {
                instance = Instance(character);
                if (CanonicalRevision > 0) instance["snapshot"]!["skills"]![0]!["id"] = "skill.cover-discipline";
                instances.Add(character, instance); Created++;
            }
            if (FailNetwork) throw new HttpRequestException("Synthetic response lost after server activation");
            return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(new JsonObject { ["data"] = instance.DeepClone() }.ToJsonString()) };
        }
    }
}
