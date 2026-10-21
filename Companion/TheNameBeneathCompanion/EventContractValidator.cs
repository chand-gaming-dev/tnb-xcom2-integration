using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

// This is deliberately a subset of Contract v0.2. Shared-contract fixtures test it too.
internal static class EventContractValidator
{
    internal static string Hash(string text) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text))).ToLowerInvariant();
    internal static string EventId(string journey, string campaign, string key) => "xcom2:" + Hash(journey + "\n" + campaign + "\n" + key)[..48];
    internal static string Text(JsonObject value, string key, int max = 128)
    {
        string result;
        try { result = value[key]?.GetValue<string>() ?? ""; }
        catch (InvalidOperationException) { throw new BridgeError("event_invalid"); }
        if (result.Length is 0 || result.Length > max || result.Any(char.IsControl)) throw new BridgeError("event_invalid");
        return result;
    }
    internal static string Uuid(JsonObject value, string key)
    {
        string result = Text(value, key);
        if (!Guid.TryParseExact(result, "D", out _)) throw new BridgeError("event_invalid");
        return result.ToLowerInvariant();
    }
    internal static void Only(JsonObject value, params string[] keys)
    {
        if (value.Any(pair => !keys.Contains(pair.Key, StringComparer.Ordinal))) throw new BridgeError("event_invalid");
    }
    internal static JsonObject Build(JsonObject args, out string fingerprint, bool normalizeClock = true)
    {
        Only(args, "expected_journey_id", "expected_commander_id", "campaign_id", "sender_local_now", "capture");
        string journey = Uuid(args, "expected_journey_id");
        _ = Uuid(args, "expected_commander_id");
        string campaign = Text(args, "campaign_id", 128);
        var capture = args["capture"] as JsonObject ?? throw new BridgeError("event_invalid");
        Only(capture, "key", "mission_key", "captured_local", "clock_zone", "event_type", "summary", "facts", "participants", "game_data");
        string key = Text(capture, "key", 512);
        string type = Text(capture, "event_type");
        string role = type switch
        {
            "threadline.mission.started" or "threadline.mission.character_deployed" or "threadline.mission.completed" => "deployed",
            "threadline.character.promoted" => "promoted",
            "threadline.character.injured" => "injured",
            "threadline.character.recovered" => "recovered",
            "threadline.character.died" => "deceased",
            "threadline.character.captured" => "captured",
            "threadline.character.freed" => "freed",
            "threadline.relationship.formed" or "threadline.relationship.developed" => "relationship_participant",
            "threadline.narrative.milestone_reached" => "bondmate",
            _ => throw new BridgeError("event_invalid")
        };
        // UE3's native JsonObject encodes an empty array-holder as {}.
        var participants = capture["participants"] as JsonArray ?? (capture["participants"] is JsonObject empty && empty.Count == 0 ? new JsonArray() : throw new BridgeError("event_invalid"));
        if (participants.Count > 50 || (participants.Count == 0 && type != "threadline.mission.started" && type != "threadline.mission.completed")) throw new BridgeError("event_invalid");
        if (role is "bondmate" or "relationship_participant" ? participants.Count is < 1 or > 2 : role != "deployed" && participants.Count != 1) throw new BridgeError("event_invalid");
        var normalizedParticipants = new JsonArray();
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var node in participants)
        {
            string id = node is JsonValue v && v.TryGetValue<string>(out var s) && Guid.TryParseExact(s, "D", out _) ? s.ToLowerInvariant() : throw new BridgeError("event_invalid");
            if (!seen.Add(id)) throw new BridgeError("event_invalid");
        }
        // Roster iteration order is not an occurrence change.
        foreach (string id in seen.Order(StringComparer.Ordinal)) normalizedParticipants.Add(new JsonObject
        {
            ["participant_ref"] = "soldier:" + id, ["kind"] = "character", ["instance_id"] = id,
            ["participation"] = type == "threadline.mission.started" ? "context" : "subject", ["roles"] = new JsonArray(type == "threadline.mission.started" ? "assigned" : role)
        });
        var facts = capture["facts"] as JsonObject ?? throw new BridgeError("event_invalid");
        ValidateFacts(type, facts);
        if (role == "bondmate") BondMilestones.Validate(capture, seen);
        if (role == "relationship_participant") BondRelationships.Validate(capture, seen);
        var result = new JsonObject
        {
            ["contract_version"] = "0.2", ["event_id"] = EventId(journey, campaign, key), ["journey_id"] = journey,
            ["event_type"] = type, ["type_version"] = type == "threadline.mission.completed" ? 2 : 1,
            ["summary"] = Text(capture, "summary", 500), ["participants"] = normalizedParticipants,
            ["facts"] = facts.DeepClone()
        };
        if (type == "threadline.character.recovered" && facts["injury_ref"]?.GetValue<string>() is { } injuryKey && injuryKey.StartsWith("unit:", StringComparison.Ordinal))
            result["facts"]!["injury_ref"] = EventId(journey, campaign, injuryKey);
        if (capture["mission_key"] != null)
            result["mission_ref"] = "xcom2:" + Hash(journey + "\n" + campaign + "\n" + Text(capture, "mission_key", 512))[..48];
        if (role == "deployed" && result["mission_ref"] == null) throw new BridgeError("event_invalid");
        if (type == "threadline.mission.completed") result["outcome"] = new JsonObject { ["status"] = facts["result"]!.DeepClone() };
        if (capture["game_data"] is { } data)
        {
            if (data is not JsonObject obj || obj.Count > 50) throw new BridgeError("event_invalid");
            ValidateData(obj, 0);
            result["game_data"] = obj.DeepClone();
        }
        // Capture clock is intentionally not part of factual replay equality.
        fingerprint = Hash(Canonical(result));
        if (normalizeClock) result["occurred_at"] = NormalizeClock(Text(capture, "captured_local", 32), Text(capture, "clock_zone")).ToString("O", CultureInfo.InvariantCulture);
        if (Encoding.UTF8.GetByteCount(result.ToJsonString()) > 48 * 1024) throw new BridgeError("event_too_large");
        return result;
    }
    internal static DateTimeOffset NormalizeClock(string text, string? zone = null)
    {
        if (zone != null && zone != TimeZoneInfo.Local.Id) throw new BridgeError("event_clock_zone_changed");
        if (!DateTime.TryParseExact(text, "yyyy-MM-dd'T'HH:mm:ss.fff", CultureInfo.InvariantCulture, DateTimeStyles.None, out var local)) throw new BridgeError("event_clock_invalid");
        local = DateTime.SpecifyKind(local, DateTimeKind.Unspecified);
        // Native GetSystemTime was verified against Windows: it is LOCAL, not UTC.
        if (TimeZoneInfo.Local.IsInvalidTime(local) || TimeZoneInfo.Local.IsAmbiguousTime(local)) throw new BridgeError("event_clock_ambiguous");
        var utc = new DateTimeOffset(TimeZoneInfo.ConvertTimeToUtc(local, TimeZoneInfo.Local), TimeSpan.Zero);
        if (utc > DateTimeOffset.UtcNow.AddMinutes(5)) throw new BridgeError("event_clock_invalid");
        return utc;
    }
    internal static void VerifySenderClock(JsonObject args)
    {
        var sender = NormalizeClock(Text(args, "sender_local_now", 32));
        if ((sender - DateTimeOffset.UtcNow).Duration() > TimeSpan.FromMinutes(5)) throw new BridgeError("event_clock_unverified");
    }
    private static void ValidateFacts(string type, JsonObject f)
    {
        switch (type)
        {
            case "threadline.mission.started": Only(f, "mission_name", "map_ref", "difficulty_label"); break;
            case "threadline.mission.character_deployed": Only(f, "deployment_kind"); break;
            case "threadline.mission.completed":
                Only(f, "result", "turns", "duration_seconds", "squad_injuries", "squad_deaths");
                if (Text(f, "result") is not ("success" or "failure" or "partial" or "neutral")) throw new BridgeError("event_invalid");
                break;
            case "threadline.character.promoted": Only(f, "from_rank", "to_rank", "promotion_track"); _ = Text(f, "to_rank"); break;
            case "threadline.character.injured": Only(f, "injury_code", "severity_label", "recovery_duration_seconds"); _ = Text(f, "injury_code"); break;
            case "threadline.character.recovered": Only(f, "recovery", "injury_ref"); if (Text(f, "recovery") is not ("full" or "partial")) throw new BridgeError("event_invalid"); break;
            case "threadline.character.died": Only(f, "local_finality", "cause_code"); if (Text(f, "local_finality") is not ("dead" or "incapacitated_permanent")) throw new BridgeError("event_invalid"); break;
            case "threadline.character.captured":
            case "threadline.character.freed": Only(f, "circumstances"); break;
            case "threadline.relationship.formed":
            case "threadline.relationship.developed":
                Only(f, "relationship_type", "level", "details", "game_local_participants");
                if (Text(f, "relationship_type") != "xcom2.soldier_bond" || f["level"] is not JsonValue level || !level.TryGetValue<int>(out int bondLevel) || bondLevel is < 1 or > 3) throw new BridgeError("event_invalid");
                if (f["details"] != null) _ = Text(f, "details", 500);
                return;
            case "threadline.narrative.milestone_reached":
                Only(f, "milestone_key", "milestone_label");
                if (Text(f, "milestone_key") is not ("xcom2.bond.formed" or "xcom2.bond.level_increased")) throw new BridgeError("event_invalid");
                break;
        }
        foreach (var pair in f)
        {
            if (pair.Key is "turns" or "duration_seconds" or "squad_injuries" or "squad_deaths" or "recovery_duration_seconds")
            {
                if (pair.Value is not JsonValue n || !n.TryGetValue<int>(out int number) || number < 0) throw new BridgeError("event_invalid");
            }
            else _ = Text(f, pair.Key, pair.Key is "mission_name" or "milestone_label" or "circumstances" ? 500 : 128);
        }
    }
    private static void ValidateData(JsonNode? node, int depth)
    {
        if (depth > 6) throw new BridgeError("event_invalid");
        if (node is JsonObject obj)
        {
            foreach (var p in obj)
            {
                if (p.Key.Length is < 1 or > 64 || p.Key.Any(char.IsControl)) throw new BridgeError("event_invalid");
                ValidateData(p.Value, depth + 1);
            }
        }
        else if (node is JsonArray array)
        {
            if (array.Count > 50) throw new BridgeError("event_invalid");
            foreach (var child in array) ValidateData(child, depth + 1);
        }
        else if (node is JsonValue value && value.TryGetValue<string>(out var text) && (text.Length > 500 || text.Any(char.IsControl))) throw new BridgeError("event_invalid");
    }
    internal static string Canonical(JsonNode? node) => node switch
    {
        JsonObject obj => "{" + string.Join(",", obj.OrderBy(p => p.Key, StringComparer.Ordinal).Select(p => System.Text.Json.JsonSerializer.Serialize(p.Key) + ":" + Canonical(p.Value))) + "}",
        JsonArray array => "[" + string.Join(",", array.Select(Canonical)) + "]",
        _ => node?.ToJsonString() ?? "null"
    };
    internal static void ValidateReceipt(JsonObject receipt, JsonObject payload, string commander)
    {
        if (Text(receipt, "status") is not ("accepted" or "duplicate") || Uuid(receipt, "journey_id") != payload["journey_id"]!.GetValue<string>() ||
            Text(receipt, "event_id") != payload["event_id"]!.GetValue<string>() || Uuid(receipt, "commander_id") != commander ||
            ReceiptTime(receipt, "occurred_at") != DateTimeOffset.Parse(payload["occurred_at"]!.GetValue<string>(), CultureInfo.InvariantCulture) ||
            Text(receipt, "source_confidence") != "operator_reported" || receipt["gameplay_attested"]?.GetValue<bool>() != false) throw new BridgeError("event_receipt_invalid");
        _ = Uuid(receipt, "raw_event_id");
        _ = ReceiptTime(receipt, "ingested_at");
    }
    private static DateTimeOffset ReceiptTime(JsonObject receipt, string key)
    {
        string text = Text(receipt, key);
        if (!System.Text.RegularExpressions.Regex.IsMatch(text, @"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$") ||
            !DateTimeOffset.TryParse(text, CultureInfo.InvariantCulture, DateTimeStyles.None, out var result)) throw new BridgeError("event_receipt_invalid");
        return result;
    }
}
