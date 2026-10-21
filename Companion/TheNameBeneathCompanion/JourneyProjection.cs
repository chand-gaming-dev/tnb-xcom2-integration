using System.Text;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

// Bounded, explicitly projected nonsecret records, not a second implementation of the API schema.
internal static class JourneyProjection
{
    private static string Text(JsonNode? value, int maximum, bool optional = false)
    {
        if (value == null && optional) return "";
        if (value is not JsonValue scalar || !scalar.TryGetValue<string>(out string? text) || text == null || text.Length > maximum || (!optional && string.IsNullOrWhiteSpace(text)))
            throw new BridgeError("api_response_invalid");
        return text;
    }
    private static int Version(JsonObject definition)
    {
        if (definition["version"] is not JsonValue value || !value.TryGetValue<int>(out int version) || version < 1) throw new BridgeError("api_response_invalid");
        return version;
    }
    private static JsonObject Definition(JsonObject value) => new()
    {
        ["definition_id"] = Text(value["id"], 128), ["definition_version"] = Version(value),
        ["catalog_version"] = Text(value["catalog_version"], 128), ["name"] = Text(value["name"], 100)
    };
    internal static string Title(JsonObject value)
    {
        if (value["journey_title"] is not JsonValue scalar || !scalar.TryGetValue<string>(out string? title) ||
            string.IsNullOrWhiteSpace(title) || title.EnumerateRunes().Count() > 160)
            throw new BridgeError("api_response_invalid");
        return title;
    }
    internal static string DisplayTitle(string? title) => string.IsNullOrWhiteSpace(title)
        ? "Journey title unavailable — use Test connection to refresh"
        : SingleLine(title);
    internal static string SingleLine(string value) => string.Concat(value.Select(c => char.IsControl(c) || c is '\u2028' or '\u2029' ? ' ' : c));
    internal static JsonObject Context(JsonObject value)
    {
        var commander = value["commander"] as JsonObject ?? throw new BridgeError("api_response_invalid");
        string state = Text(value["status"], 32);
        if (state is not ("upcoming" or "started" or "finished")) throw new BridgeError("api_response_invalid");
        int journeyVersion = 0;
        if (value["journey_version"] != null && (value["journey_version"] is not JsonValue versionValue || !versionValue.TryGetValue<int>(out journeyVersion) || journeyVersion < 1)) throw new BridgeError("api_response_invalid");
        bool canManage = journeyVersion > 0 && value["capabilities"] is JsonArray scopes && scopes.Any(node => node?.GetValue<string>() == "journey:manage");
        var characteristics = commander["characteristics"] as JsonObject;
        var (traits, skills) = Characteristics(characteristics);
        return Bounded(new JsonObject
        {
            ["feature_version"] = 1, ["journey_id"] = Text(value["journey_id"], 128), ["journey_title"] = Title(value), ["game_name"] = Text(value["game_name"], 160),
            ["journey_version"] = journeyVersion, ["can_manage_journey"] = canManage,
            ["journey_status"] = state, ["commander_id"] = Text(commander["id"], 128), ["commander_name"] = Text(commander["display_name"], 100),
            ["characteristics_available"] = characteristics != null,
            ["observed_at"] = characteristics == null ? "" : Text(characteristics["observed_at"], 64),
            ["title_observed_at"] = DateTimeOffset.UtcNow.ToString("O"),
            ["traits"] = traits, ["skills"] = skills
        });
    }
    // Frozen character snapshots contain characteristics, not live Journey metadata.
    private static (JsonArray Traits, JsonArray Skills) Characteristics(JsonObject? characteristics)
    {
        var traits = new JsonArray();
        var skills = new JsonArray();
        var traitIds = new HashSet<string>(StringComparer.Ordinal);
        var skillIds = new HashSet<string>(StringComparer.Ordinal);
        if (characteristics != null)
        {
            if (characteristics["traits"] is not JsonArray sourceTraits || characteristics["skills"] is not JsonArray sourceSkills) throw new BridgeError("api_response_invalid");
            if (sourceTraits.Count > 128 || sourceSkills.Count > 128) throw new BridgeError("characteristics_too_large");
            foreach (var source in sourceTraits)
            {
                if (source is not JsonObject trait || trait["definition"] is not JsonObject definition) throw new BridgeError("api_response_invalid");
                var projected = Definition(definition);
                if (!traitIds.Add(projected["definition_id"]!.GetValue<string>())) throw new BridgeError("api_response_invalid");
                projected["polarity"] = Text(definition["polarity"], 32, true);
                projected["acquisition_kind"] = Text(definition["acquisition_kind"], 32);
                projected["acquisition_source"] = Text(trait["acquisition_source"], 64);
                traits.Add(projected);
            }
            foreach (var source in sourceSkills)
            {
                if (source is not JsonObject skill || skill["provisional"] is not JsonValue provisional || !provisional.TryGetValue<bool>(out bool flag)) throw new BridgeError("api_response_invalid");
                var projected = Definition(skill);
                if (!skillIds.Add(projected["definition_id"]!.GetValue<string>())) throw new BridgeError("api_response_invalid");
                projected["provisional"] = flag;
                skills.Add(projected);
            }
        }
        return (traits, skills);
    }
    internal static JsonObject Roster(JsonObject value, string expectedJourney)
    {
        if (value["items"] is not JsonArray source || source.Count > 5) throw new BridgeError("api_response_invalid");
        var items = new JsonArray();
        foreach (var entry in source)
        {
            if (entry is not JsonObject item || item["eligible"] is not JsonValue eligible || !eligible.TryGetValue<bool>(out bool flag) || !flag) throw new BridgeError("api_response_invalid");
            items.Add(new JsonObject { ["character_id"] = Text(item["character_id"], 128), ["roster_entry_id"] = Text(item["roster_entry_id"], 128), ["name"] = Text(item["display_name"], 100) });
        }
        return Bounded(new JsonObject { ["feature_version"] = 1, ["journey_id"] = expectedJourney, ["items"] = items, ["next_cursor"] = Text(value["next_cursor"], 1024, true) });
    }
    internal static JsonObject Instance(JsonObject value, string journey, string character, string roster, string expectedCommander = "")
    {
        if (Text(value["journey_id"], 128) != journey || Text(value["character_id"], 128) != character || Text(value["roster_entry_id"], 128) != roster || Text(value["onboarding_mode"], 32) != "bind_existing") throw new BridgeError("instance_mismatch");
        var snapshot = value["snapshot"] as JsonObject ?? throw new BridgeError("api_response_invalid");
        if (expectedCommander.Length != 0 && Text(value["commander_id"], 128) != expectedCommander) throw new BridgeError("instance_mismatch");
        var identity = snapshot["identity"] as JsonObject ?? throw new BridgeError("api_response_invalid");
        if (Text(snapshot["journey_id"], 128) != journey || Text(snapshot["identity_id"], 128) != character || Text(snapshot["identity_type"], 32) != "character" || snapshot["gameplay_effects"] is not JsonArray effects || effects.Count != 0) throw new BridgeError("instance_mismatch");
        // Reuse the fixed-field characteristic projector; never forward identity provenance or raw JSON.
        var (traits, skills) = Characteristics(new JsonObject { ["traits"] = snapshot["traits"]?.DeepClone(), ["skills"] = snapshot["skills"]?.DeepClone() });
        int version = Version(snapshot);
        if (version > 3) throw new BridgeError("snapshot_version_unsupported");
        return Bounded(new JsonObject
        {
            ["feature_version"] = 1, ["journey_id"] = journey, ["commander_id"] = Text(value["commander_id"], 128),
            ["character_id"] = character, ["roster_entry_id"] = roster, ["character_name"] = Text(identity["display_name"], 100),
            ["instance_id"] = Text(value["id"], 128), ["snapshot_id"] = Text(snapshot["id"], 128), ["snapshot_version"] = version,
            ["issued_at"] = Text(snapshot["issued_at"], 64), ["authorization_decision_id"] = Text(snapshot["authorization_decision_id"], 128),
            ["traits"] = traits, ["skills"] = skills
        });
    }
    private static JsonObject Bounded(JsonObject value)
    {
        // Leave room for the RPC envelope; fail rather than truncate a commander's source records.
        if (Encoding.ASCII.GetByteCount(value.ToJsonString()) > 58000) throw new BridgeError("preview_too_large");
        return value;
    }
}
