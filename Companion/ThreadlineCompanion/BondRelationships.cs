using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

// New occurrences use factual relationships; legacy milestone captures stay immutable.
internal static class BondRelationships
{
    internal static void Validate(JsonObject capture, HashSet<string> participants)
    {
        var facts = capture["facts"]!.AsObject();
        bool formed = capture["event_type"]!.GetValue<string>() == "threadline.relationship.formed";
        // Reuse native transition/roster checks without changing the source capture,
        // its fingerprint or any persisted legacy milestone representation.
        var legacyShape = (JsonObject)capture.DeepClone();
        legacyShape["facts"] = new JsonObject { ["milestone_key"] = formed ? "xcom2.bond.formed" : "xcom2.bond.level_increased" };
        BondMilestones.Validate(legacyShape, participants);
        var data = capture["game_data"]!.AsObject();
        if (facts["level"]!.GetValue<int>() != data["bond_level"]!.GetValue<int>()) throw new BridgeError("event_invalid");
        var expected = new JsonArray();
        foreach (var mate in data["bondmates"]!.AsArray().Select(n => n!.AsObject()).Where(m => m["instance_id"] == null))
            expected.Add(new JsonObject { ["local_ref"] = "xcom2-unit-" + mate["unit_id"]!.GetValue<int>(), ["display_name"] = mate["soldier_name"]!.GetValue<string>() });
        if (expected.Count == 0)
        {
            if (facts["game_local_participants"] is JsonArray locals && locals.Count == 0) return;
            if (facts["game_local_participants"] != null) throw new BridgeError("event_invalid");
        }
        else if (facts["game_local_participants"] is not JsonArray locals ||
            EventContractValidator.Canonical(locals) != EventContractValidator.Canonical(expected)) throw new BridgeError("event_invalid");
    }
}
