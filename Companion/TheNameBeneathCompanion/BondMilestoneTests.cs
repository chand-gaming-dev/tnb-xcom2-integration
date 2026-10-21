using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal static class BondMilestoneTests
{
    private const string Other = "44444444-4444-4444-8444-444444444444";
    private static void Check(bool value) { if (!value) throw new Exception("Bond milestone assertion failed"); }
    internal static JsonObject Args(bool both, int level = 1)
    {
        var args = EventTests.Capture("threadline.narrative.milestone_reached", "bond:17:29:episode:1:level:" + level);
        var capture = args["capture"]!.AsObject(); capture.Remove("mission_key");
        capture["summary"] = "Ren\u00e9 & Snow \u96ea bonded (level " + level + ")";
        capture["facts"] = new JsonObject { ["milestone_key"] = level == 1 ? "xcom2.bond.formed" : "xcom2.bond.level_increased", ["milestone_label"] = "Soldier bond level " + level };
        capture["participants"] = both ? new JsonArray(EventTests.Instance, Other) : new JsonArray(EventTests.Instance);
        var second = new JsonObject { ["unit_id"] = 29, ["soldier_name"] = "Snow \u96ea" };
        if (both) second["instance_id"] = Other;
        capture["game_data"] = new JsonObject
        {
            ["bond_kind"] = "xcom2_soldier_bond", ["native_event"] = level == 1 ? "BondCreated" : "BondLevelUpComplete",
            ["previous_level"] = level - 1, ["bond_level"] = level,
            ["bondmates"] = new JsonArray(new JsonObject { ["unit_id"] = 17, ["soldier_name"] = "Ren\u00e9", ["instance_id"] = EventTests.Instance }, second)
        };
        return args;
    }
    private static void Reject(JsonObject args)
    {
        try { EventContractValidator.Build(args, out _); throw new Exception("Invalid bond accepted"); }
        catch (BridgeError error) { Check(error.Code == "event_invalid"); }
    }
    internal static void Run(Configuration original, JsonArray fixtures, string? nativeLog)
    {
        foreach (var args in new[] { Args(false), Args(true), Args(false, 2), Args(true, 3) })
        {
            var payload = EventContractValidator.Build(args, out _);
            Check(payload["type_version"]!.GetValue<int>() == 1 && payload["mission_ref"] == null);
            Check(payload["participants"]!.AsArray().All(p => p?["participation"]?.GetValue<string>() == "subject" && p["roles"]?[0]?.GetValue<string>() == "bondmate"));
            fixtures.Add(payload);
        }
        var nativeCount = 0;
        if (nativeLog != null)
        {
            const string marker = "TNB_NATIVE_BOND_CAPTURE=";
            foreach (string line in File.ReadLines(nativeLog).Where(l => l.Contains(marker, StringComparison.Ordinal)))
            {
                var capture = JsonNode.Parse(line[(line.IndexOf(marker, StringComparison.Ordinal) + marker.Length)..])!.AsObject();
                capture["clock_zone"] = TimeZoneInfo.Local.Id;
                var args = EventTests.Capture(); args["capture"] = capture;
                fixtures.Add(EventContractValidator.Build(args, out _)); nativeCount++;
            }
        }
        foreach (Action<JsonObject> mutate in new Action<JsonObject>[] {
            a => a["capture"]!["participants"] = new JsonArray(),
            a => a["capture"]!["participants"] = new JsonArray(EventTests.Instance, Other, EventTests.Commander),
            a => a["capture"]!["game_data"]!["bond_level"] = 0,
            a => a["capture"]!["game_data"]!["previous_level"] = 1,
            a => a["capture"]!["game_data"]!["bond_level"] = 4,
            a => a["capture"]!["game_data"]!["native_event"] = "OnBondAvailable",
            a => a["capture"]!["game_data"]!["bondmates"]![1]!["unit_id"] = 17,
            a => a["capture"]!["game_data"]!["bondmates"]![1]!["instance_id"] = Other,
            a => a["capture"]!["facts"]!["milestone_key"] = "xcom2.invented",
            a => a["capture"]!["facts"]!["xp"] = 3000,
            a => a["capture"]!["game_data"]!["relationship"] = "best_friends",
            a => a["capture"]!["mission_key"] = "invented-mission"
        }) { var bad = Args(false); mutate(bad); Reject(bad); }

        var config = original with { DataDirectory = Path.Combine(original.DataDirectory, "bonds") };
        var outbox = new EventOutbox(config);
        var first = Args(true);
        string id = outbox.Enqueue(first)["event_id"]!.GetValue<string>();
        var replay = (JsonObject)first.DeepClone(); replay["capture"]!["participants"] = new JsonArray(Other, EventTests.Instance);
        replay["capture"]!["captured_local"] = "invalid-later-clock";
        Check(new EventOutbox(config).Enqueue(replay)["event_id"]!.GetValue<string>() == id);
        var nextLevel = Args(true, 2);
        Check(outbox.Enqueue(nextLevel)["event_id"]!.GetValue<string>() != id);
        var rebond = Args(true); rebond["capture"]!["key"] = "bond:17:29:episode:2:level:1";
        Check(outbox.Enqueue(rebond)["event_id"]!.GetValue<string>() != id);
        replay["capture"]!["game_data"]!["bondmates"]![0]!["soldier_name"] = "Changed facts";
        try { outbox.Enqueue(replay); throw new Exception("Conflicting bond replaced original"); }
        catch (BridgeError error) { Check(error.Code == "event_replay_conflict"); }
        Check(new EventOutbox(config).Status(CompanionTests.JourneyId)["queued"]!.GetValue<int>() == 3);
        Console.WriteLine("PASS: bond milestone one/two linked participants, local partner, strict levels/keys/details, immutable replay/restart, distinct level/re-bond IDs and conflict preservation; native fixtures: " + nativeCount + ".");
    }
}
