using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

// Queue/receipt compatibility only. XP recognition and history explanations belong
// to the API/portal; deliberately do not reproduce their award algorithm here.
internal static class PromotionOccurrenceTests
{
    private const string LegacyKey = "unit:17:" + EventTests.Instance + ":rank:0:1";
    private static void Check(bool value, string name)
    {
        if (!value) throw new BridgeError("promotion_test_" + name);
    }
    private static JsonObject Args(string key, int from = 0, int to = 1)
    {
        var args = EventTests.Capture("threadline.character.promoted", key);
        var capture = args["capture"]!.AsObject();
        capture.Remove("mission_key"); capture.Remove("game_data");
        capture["facts"] = new JsonObject
        {
            ["from_rank"] = from.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ["to_rank"] = to.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ["promotion_track"] = "xcom2_soldier_rank"
        };
        return args;
    }
    private static JsonObject Receipt(EventRecord record) => new()
    {
        ["status"] = "accepted", ["raw_event_id"] = Guid.NewGuid().ToString(),
        ["event_id"] = record.Payload["event_id"]!.DeepClone(),
        ["journey_id"] = record.Journey, ["commander_id"] = record.Commander,
        ["occurred_at"] = record.Payload["occurred_at"]!.DeepClone(),
        ["ingested_at"] = DateTimeOffset.UtcNow.ToString("O"),
        ["source_confidence"] = "operator_reported", ["gameplay_attested"] = false
    };
    internal static void Run(Configuration config, JsonArray fixtures, string? nativeLog)
    {
        var scoped = config with { DataDirectory = Path.Combine(config.DataDirectory, "promotion-occurrences") };
        var queue = new EventOutbox(scoped);
        var legacy = Args(LegacyKey);
        string legacyId = queue.Enqueue(legacy)["event_id"]!.GetValue<string>();
        var oldRecord = queue.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow)!;
        queue.Accepted(oldRecord, Receipt(oldRecord));
        string oldPath = Directory.EnumerateFiles(scoped.DataDirectory, "*.json", SearchOption.AllDirectories).Single();
        string oldBytes = File.ReadAllText(oldPath);

        var samples = new List<JsonObject>();
        if (nativeLog != null)
        {
            const string marker = "TNB_NATIVE_PROMOTION_OCCURRENCE=";
            foreach (string line in File.ReadLines(nativeLog).Where(l => l.Contains(marker, StringComparison.Ordinal)))
            {
                var capture = JsonNode.Parse(line[(line.IndexOf(marker, StringComparison.Ordinal) + marker.Length)..])!.AsObject();
                Check(capture["clock_zone"]?.GetValue<string>() == TimeZoneInfo.Local.Id, "native_capture_includes_verified_clock_zone");
                var args = Args("unused"); args["capture"] = capture;
                samples.Add(args);
            }
            Check(samples.Count == 3, "native_occurrences_required");
        }
        else
        {
            samples.Add(Args(LegacyKey + ":occurrence:AAAAAAAABBBB4CCC8DDDEEEEEEEEEEEE"));
            samples.Add(Args(LegacyKey + ":occurrence:FFFFFFFFBBBB4CCC8DDDEEEEEEEEEEEE"));
            samples.Add(Args("unit:17:" + EventTests.Instance + ":rank:1:2:occurrence:AAAAAAAABBBB4CCC8DDDEEEEEEEEEEEE", 1, 2));
        }
        Check(samples[0]["capture"]!["facts"]!.ToJsonString() == samples[1]["capture"]!["facts"]!.ToJsonString(), "repeated_rank_facts");
        var ids = new HashSet<string>(StringComparer.Ordinal) { legacyId };
        foreach (var args in samples)
        {
            var payload = EventContractValidator.Build(args, out _);
            Check(payload["type_version"]!.GetValue<int>() == 1 && payload["mission_ref"] == null, "unchanged_v1_shape");
            Check(payload["participants"]![0]!["roles"]![0]!.GetValue<string>() == "promoted", "primary_participant");
            Check(payload["facts"]!["promotion_track"]!.GetValue<string>() == "xcom2_soldier_rank", "recognizable_track");
            Check(payload["xp"] == null && payload["xp_suppressions"] == null && payload["facts"]!["xp"] == null, "no_client_xp");
            fixtures.Add(payload);
            var handoff = queue.Enqueue(args);
            string id = handoff["event_id"]!.GetValue<string>();
            Check(ids.Add(id), "distinct_occurrence_id");
            queue = new EventOutbox(scoped);
            Check(queue.Enqueue(args).ToJsonString() == handoff.ToJsonString(), "restart_retry_stable");
        }
        Check(queue.Status(CompanionTests.JourneyId)["queued"]!.GetValue<int>() == 3, "all_new_occurrences_retained");
        var missingZone = Args("unit:17:" + EventTests.Instance + ":rank:0:1:occurrence:MISSING_ZONE_TEST");
        missingZone["capture"]!.AsObject().Remove("clock_zone");
        try { queue.Enqueue(missingZone); throw new Exception("Missing clock zone accepted"); }
        catch (BridgeError error) { Check(error.Code == "event_clock_unverified", "missing_zone_rejected_before_handoff"); }
        if (nativeLog != null)
        {
            const string marker = "TNB_NATIVE_PROMOTION_RECOVERED=";
            string line = File.ReadLines(nativeLog).Single(l => l.Contains(marker, StringComparison.Ordinal));
            var recovered = Args("unused");
            recovered["capture"] = JsonNode.Parse(line[(line.IndexOf(marker, StringComparison.Ordinal) + marker.Length)..])!.AsObject();
            Check(recovered["capture"]!.ToJsonString() == samples[0]["capture"]!.ToJsonString(), "recovery_changes_only_missing_zone");
            Check(queue.Enqueue(recovered)["event_id"]!.GetValue<string>() == EventContractValidator.Build(samples[0], out _)["event_id"]!.GetValue<string>() &&
                queue.Status(CompanionTests.JourneyId)["queued"]!.GetValue<int>() == 3, "recovered_original_is_exact_retry_not_new_occurrence");
        }
        foreach (var args in samples)
        {
            var record = queue.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow)!;
            string original = record.Payload.ToJsonString();
            queue.Failed(record, new BridgeError("network_unavailable"), DateTimeOffset.UtcNow);
            queue = new EventOutbox(scoped);
            queue.Retry(CompanionTests.JourneyId, "test-campaign");
            record = queue.Next(CompanionTests.JourneyId, DateTimeOffset.UtcNow)!;
            Check(record.Payload.ToJsonString() == original, "network_retry_exact_payload");
            // Acceptance is valid with no XP/reason fields, including zero-XP
            // server decisions; those are exposed by HISTORY, not this receipt.
            queue.Accepted(record, Receipt(record));
            Check(queue.Enqueue(args)["accepted_online"]!.GetValue<bool>(), "accepted_retry_no_new_event");
        }
        queue = new EventOutbox(scoped);
        Check(queue.Status(CompanionTests.JourneyId)["accepted"]!.GetValue<int>() == 4, "accepted_restart");
        Check(queue.Enqueue(legacy)["event_id"]!.GetValue<string>() == legacyId && File.ReadAllText(oldPath) == oldBytes, "legacy_immutable");
        var changed = (JsonObject)samples[0].DeepClone();
        changed["capture"]!["facts"]!["to_rank"] = "3";
        try { queue.Enqueue(changed); throw new Exception("Changed promotion retry accepted"); }
        catch (BridgeError error) { Check(error.Code == "event_replay_conflict", "changed_retry_conflicts"); }
        var inventedXp = (JsonObject)samples[0].DeepClone();
        inventedXp["capture"]!["facts"]!["xp"] = 0;
        try { EventContractValidator.Build(inventedXp, out _); throw new Exception("Client XP accepted"); }
        catch (BridgeError error) { Check(error.Code == "event_invalid", "client_xp_rejected"); }
        Console.WriteLine("PASS: promotion occurrences: repeated-rank/new-rank IDs, durable exact retries/restart, unchanged v1 acceptance without XP fields, no client award authority and immutable legacy records; native fixtures: " + (nativeLog == null ? 0 : samples.Count) + ".");
    }
}
