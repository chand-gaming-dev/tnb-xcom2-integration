using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

// The existing standard milestone type, restricted to factual XCOM bond transitions.
internal static class BondMilestones
{
    private static int Number(JsonObject obj, string key, int minimum, int maximum)
    {
        if (obj[key] is not JsonValue value || !value.TryGetValue<int>(out int result) || result < minimum || result > maximum)
            throw new BridgeError("event_invalid");
        return result;
    }
    internal static void Validate(JsonObject capture, HashSet<string> participants)
    {
        if (capture["game_data"] is not JsonObject data || capture["facts"] is not JsonObject facts || capture["mission_key"] != null) throw new BridgeError("event_invalid");
        EventContractValidator.Only(data, "bond_kind", "native_event", "previous_level", "bond_level", "bondmates");
        if (EventContractValidator.Text(data, "bond_kind") != "xcom2_soldier_bond") throw new BridgeError("event_invalid");
        int before = Number(data, "previous_level", 0, 2), after = Number(data, "bond_level", 1, 3);
        string source = EventContractValidator.Text(data, "native_event");
        bool formed = EventContractValidator.Text(facts, "milestone_key") == "xcom2.bond.formed";
        if (after <= before || (formed ? before != 0 || after != 1 || source != "BondCreated" : before < 1 || source != "BondLevelUpComplete")) throw new BridgeError("event_invalid");
        if (data["bondmates"] is not JsonArray mates || mates.Count != 2) throw new BridgeError("event_invalid");
        int previousUnit = 0;
        var linked = new HashSet<string>(StringComparer.Ordinal);
        foreach (var node in mates)
        {
            if (node is not JsonObject mate) throw new BridgeError("event_invalid");
            EventContractValidator.Only(mate, "unit_id", "soldier_name", "instance_id");
            int unit = Number(mate, "unit_id", 1, int.MaxValue);
            if (unit <= previousUnit) throw new BridgeError("event_invalid");
            previousUnit = unit;
            _ = EventContractValidator.Text(mate, "soldier_name", 100);
            if (mate["instance_id"] != null && !linked.Add(EventContractValidator.Uuid(mate, "instance_id"))) throw new BridgeError("event_invalid");
        }
        if (!linked.SetEquals(participants)) throw new BridgeError("event_invalid");
    }
}
