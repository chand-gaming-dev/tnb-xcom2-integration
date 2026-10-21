using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

internal static class FactualEventTests
{
    private static void Check(bool value) { if (!value) throw new Exception("Factual event assertion failed"); }
    private static JsonObject State(string change, int sequence = 1)
    {
        var args = EventTests.Capture("threadline.character." + change, "unit:17:captivity:" + sequence + ":" + change);
        var capture = args["capture"]!.AsObject(); capture.Remove("mission_key");
        capture["facts"] = new JsonObject { ["circumstances"] = "XCOM reports the soldier " + change + "." };
        return args;
    }
    private static JsonObject Bond(bool both, int level = 1)
    {
        var args = BondMilestoneTests.Args(both, level);
        var capture = args["capture"]!.AsObject();
        capture["event_type"] = level == 1 ? "threadline.relationship.formed" : "threadline.relationship.developed";
        var facts = new JsonObject { ["relationship_type"] = "xcom2.soldier_bond", ["level"] = level, ["details"] = "Soldiers bonded." };
        if (!both) facts["game_local_participants"] = new JsonArray(new JsonObject { ["local_ref"] = "xcom2-unit-29", ["display_name"] = "Snow \u96ea" });
        capture["facts"] = facts;
        return args;
    }
    private static void Reject(JsonObject args)
    {
        try { EventContractValidator.Build(args, out _); throw new Exception("Invalid factual event accepted"); }
        catch (BridgeError error) { Check(error.Code == "event_invalid"); }
    }
    internal static void Run(Configuration config, JsonArray fixtures, string? nativeLog)
    {
        foreach (var args in new[] { State("captured"), State("freed"), Bond(false), Bond(true), Bond(false, 2), Bond(true, 3) })
        {
            var payload = EventContractValidator.Build(args, out _);
            Check(payload["mission_ref"] == null && payload["type_version"]!.GetValue<int>() == 1);
            Check(payload["participants"]!.AsArray().All(p => p!["kind"]!.GetValue<string>() == "character" && p["participation"]!.GetValue<string>() == "subject"));
            fixtures.Add(payload);
        }
        var bad = State("captured"); bad["capture"]!["facts"]!["xp"] = 100; Reject(bad);
        bad = State("freed"); bad["capture"]!["participants"] = new JsonArray(); Reject(bad);
        bad = State("captured"); bad["capture"]!["facts"]!["circumstances"] = new string('a', 501); Reject(bad);
        bad = Bond(false); bad["capture"]!["facts"]!["game_local_participants"]![0]!["local_ref"] = "invented-partner"; Reject(bad);
        bad = Bond(false); bad["capture"]!["facts"]!["game_local_participants"]![0]!["instance_id"] = EventTests.Instance; Reject(bad);
        bad = Bond(true); bad["capture"]!["facts"]!["level"] = 2; Reject(bad);
        bad = Bond(true); bad["capture"]!["event_type"] = "threadline.relationship.developed"; Reject(bad);
        bad = Bond(true); bad["capture"]!["facts"]!["unknown"] = true; Reject(bad);
        var queue = new EventOutbox(config with { DataDirectory = Path.Combine(config.DataDirectory, "factual-events") });
        var captured = State("captured");
        string firstId = queue.Enqueue(captured)["event_id"]!.GetValue<string>();
        Check(new EventOutbox(config with { DataDirectory = Path.Combine(config.DataDirectory, "factual-events") }).Enqueue(captured)["event_id"]!.GetValue<string>() == firstId);
        Check(queue.Enqueue(State("captured", 2))["event_id"]!.GetValue<string>() != firstId);
        queue.Enqueue(State("freed"));
        new EventOutbox(config with { DataDirectory = Path.Combine(config.DataDirectory, "freed-without-capture") }).Enqueue(State("freed"));
        var legacy = BondMilestoneTests.Args(true);
        queue.Enqueue(legacy);
        try { queue.Enqueue(Bond(true)); throw new Exception("Legacy occurrence relabeled"); }
        catch (BridgeError error) { Check(error.Code == "event_replay_conflict"); }
        var futureBond = Bond(true); futureBond["capture"]!["key"] = "bond:17:29:episode:2:level:1";
        queue.Enqueue(futureBond);
        if (nativeLog != null)
            foreach (var line in File.ReadLines(nativeLog).Where(l => l.Contains("TNB_NATIVE_CAPTIVITY_CAPTURE=", StringComparison.Ordinal)))
            {
                const string marker = "TNB_NATIVE_CAPTIVITY_CAPTURE=";
                var capture = JsonNode.Parse(line[(line.IndexOf(marker, StringComparison.Ordinal) + marker.Length)..])!.AsObject();
                capture["clock_zone"] = TimeZoneInfo.Local.Id;
                var args = EventTests.Capture(); args["capture"] = capture; fixtures.Add(EventContractValidator.Build(args, out _));
            }
        Console.WriteLine("PASS: captivity/freedom and factual bond contracts, one/two linked/local participants, strict evidence, legacy milestone preservation, durable restart, repeated capture identity and conflict guards.");
    }
}
