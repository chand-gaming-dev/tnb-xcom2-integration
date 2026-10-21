using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

// A local recovery journal, not a backend campaign or client-operation API.
// Receipts recover a specific saved intent (unit_token), not ownership of a soldier.
// Loading a pre-link save permits a new intent; only that loaded save owns local pairings.
internal sealed class ActivationReceipts(Configuration config, JourneyApi api)
{
    internal string PathFor(string journey, string campaign) => Path.Combine(config.DataDirectory, "links",
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(config.Api.AbsoluteUri + "\n" + journey + "\n" + campaign))) + ".json");

    private static string Required(JsonObject args, string key, int max = 128)
    {
        string value = args[key]?.GetValue<string>() ?? "";
        if (string.IsNullOrWhiteSpace(value) || value.Length > max || value.Any(char.IsControl)) throw new BridgeError("request_invalid");
        return value;
    }
    private JsonArray Read(string journey, string campaign)
    {
        string path = PathFor(journey, campaign);
        if (!File.Exists(path)) return [];
        var journal = JsonNode.Parse(File.ReadAllText(path)) as JsonObject ?? throw new BridgeError("link_journal_invalid");
        if (journal["schema"]?.GetValue<int>() is not (1 or 2) || journal["journey_id"]?.GetValue<string>() != journey || journal["campaign_id"]?.GetValue<string>() != campaign || journal["receipts"] is not JsonArray receipts)
            throw new BridgeError("link_journal_invalid");
        if (receipts.Count > 4096) throw new BridgeError("link_journal_full");
        var tokens = new HashSet<string>(StringComparer.Ordinal);
        foreach (var node in receipts)
            if (node is not JsonObject receipt || !tokens.Add(Required(receipt, "unit_token"))) throw new BridgeError("link_journal_invalid");
        return receipts;
    }
    private void Write(string journey, string campaign, JsonArray receipts) => AtomicFiles.Write(PathFor(journey, campaign),
        new JsonObject { ["schema"] = 2, ["journey_id"] = journey, ["campaign_id"] = campaign, ["receipts"] = receipts.DeepClone() }.ToJsonString());

    internal JsonObject Status(JsonObject args)
    {
        string journey = Required(args, "expected_journey_id"), campaign = Required(args, "campaign_id");
        int unit = args["unit_id"]?.GetValue<int>() ?? 0;
        if (unit < 1) throw new BridgeError("request_invalid");
        string token = args["unit_token"]?.GetValue<string>() ?? "";
        // No saved intent means no automatic restoration and no historical pairing lock.
        JsonObject? receipt = null;
        if (token.Length != 0)
        {
            Required(args, "unit_token");
            receipt = Read(journey, campaign).OfType<JsonObject>().SingleOrDefault(r => r["unit_token"]?.GetValue<string>() == token);
            if (receipt != null) MatchIntent(receipt, args);
        }
        return new JsonObject { ["feature_version"] = 2, ["journey_id"] = journey, ["receipt"] = receipt?.DeepClone() };
    }

    private static void MatchIntent(JsonObject receipt, JsonObject args)
    {
        foreach (string key in new[] { "unit_token", "unit_fingerprint", "character_id", "roster_entry_id" })
            if (receipt[key]?.GetValue<string>() != Required(args, key, key == "unit_fingerprint" ? 512 : 128)) throw new BridgeError("unit_link_conflict");
        if (receipt["unit_id"]?.GetValue<int>() != args["unit_id"]?.GetValue<int>()) throw new BridgeError("unit_link_conflict");
    }

    // Caller serializes this with credential mutations, retaining the credential/Journey pin.
    internal async Task<JsonObject> Activate(JsonObject args, string secret, CancellationToken cancel, string expectedCommander = "")
    {
        string journey = Required(args, "expected_journey_id"), campaign = Required(args, "campaign_id"),
            token = Required(args, "unit_token"), fingerprint = Required(args, "unit_fingerprint", 512), character = Required(args, "character_id"), roster = Required(args, "roster_entry_id");
        int unit = args["unit_id"]?.GetValue<int>() ?? 0;
        if (unit < 1) throw new BridgeError("request_invalid");
        var receipts = Read(journey, campaign);
        var receipt = receipts.OfType<JsonObject>().SingleOrDefault(r => r["unit_token"]?.GetValue<string>() == token);
        if (receipt != null) MatchIntent(receipt, args);
        if (receipt == null)
        {
            if (receipts.Count >= 4096) throw new BridgeError("link_journal_full");
            receipt = new JsonObject { ["unit_id"] = unit, ["unit_token"] = token, ["unit_fingerprint"] = fingerprint, ["character_id"] = character,
                ["roster_entry_id"] = roster, ["state"] = "pending", ["created_at"] = DateTimeOffset.UtcNow.ToString("O") };
            receipts.Add(receipt);
            // Persist BEFORE network I/O, including before a timeout, shutdown or lost response.
            Write(journey, campaign, receipts);
        }
        if (receipt["instance"] is JsonObject recovered)
        {
            if (expectedCommander.Length != 0 && recovered["commander_id"]?.GetValue<string>() != expectedCommander) throw new BridgeError("instance_mismatch");
            return (JsonObject)recovered.DeepClone();
        }
        // A NEW intent always reauthorizes through the API. Its unique Journey/character key
        // reuses the original instance/snapshot, without bypassing current roster consent.
        var response = await api.Send("POST", "/v1/game-journey/character-instances", secret,
            new JsonObject { ["character_id"] = character, ["onboarding_mode"] = "bind_existing" }, cancel);
        var projected = JourneyProjection.Instance(response, journey, character, roster, expectedCommander);
        receipt["instance"] = projected.DeepClone();
        receipt["state"] = "activated";
        Write(journey, campaign, receipts);
        return projected;
    }

    internal JsonObject Acknowledge(JsonObject args)
    {
        string journey = Required(args, "expected_journey_id"), campaign = Required(args, "campaign_id"), token = Required(args, "unit_token"), instance = Required(args, "instance_id");
        int unit = args["unit_id"]?.GetValue<int>() ?? 0;
        var receipts = Read(journey, campaign);
        var receipt = receipts.OfType<JsonObject>().SingleOrDefault(r => r["unit_token"]?.GetValue<string>() == token);
        if (unit < 1 || receipt == null || receipt["unit_id"]?.GetValue<int>() != unit || receipt["instance"]?["instance_id"]?.GetValue<string>() != instance) throw new BridgeError("receipt_mismatch");
        receipt["state"] = "acknowledged";
        Write(journey, campaign, receipts);
        return new JsonObject { ["feature_version"] = 2, ["acknowledged"] = true };
    }
}
