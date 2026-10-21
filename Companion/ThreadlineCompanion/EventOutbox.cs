using System.Text.Json;
using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

internal sealed record EventRecord(int Version, string Journey, string Commander, string Campaign, string Key,
    string Fingerprint, string PayloadHash, JsonObject Payload, long Order, string State, int Attempts,
    DateTimeOffset NextAttempt, string Error, JsonObject? Receipt);

// Nonsecret, endpoint-scoped journal. AtomicFiles flushes before rename/acknowledgement.
// Accepted records are retained: removing a credential must not erase replay protection.
internal sealed class EventOutbox
{
    private readonly object sync = new();
    private readonly string root;
    private readonly int maxPending;
    private readonly long maxPendingBytes;
    private readonly Dictionary<string, EventRecord> records = new(StringComparer.Ordinal);
    private readonly HashSet<string> damaged = new(StringComparer.Ordinal);
    private readonly HashSet<string> conflicts = new(StringComparer.Ordinal);
    internal EventOutbox(Configuration config, int maximumPending = 10000, long maximumPendingBytes = 128L * 1024 * 1024)
    {
        maxPending = maximumPending; maxPendingBytes = maximumPendingBytes;
        root = Path.Combine(config.DataDirectory, "events-v1", EventContractValidator.Hash(config.Api.AbsoluteUri)[..32]);
        if (!Directory.Exists(root)) return;
        string[] files;
        try { files = Directory.GetFiles(root, "*.json"); }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException) { damaged.Add("journal_unreadable"); return; }
        foreach (string path in files)
        {
            if (path.EndsWith(".conflict.json", StringComparison.Ordinal)) { conflicts.Add(Path.GetFileName(path)); continue; }
            try
            {
                if (new FileInfo(path).Length > 128 * 1024) throw new BridgeError("event_journal_damaged");
                var record = JsonSerializer.Deserialize<EventRecord>(File.ReadAllText(path)) ?? throw new BridgeError("event_journal_damaged");
                string id = record.Payload["event_id"]!.GetValue<string>();
                var factsOnly = (JsonObject)record.Payload.DeepClone(); factsOnly.Remove("occurred_at");
                if (record.Version != 1 || Path.GetFileName(path) != FileName(id) || record.PayloadHash != EventContractValidator.Hash(EventContractValidator.Canonical(record.Payload)) ||
                    record.Fingerprint != EventContractValidator.Hash(EventContractValidator.Canonical(factsOnly)) ||
                    id != EventContractValidator.EventId(record.Journey, record.Campaign, record.Key) || record.Payload["journey_id"]?.GetValue<string>() != record.Journey ||
                    record.State is not ("queued" or "retrying" or "held" or "paused" or "accepted")) throw new BridgeError("event_journal_damaged");
                if (record.State == "accepted") EventContractValidator.ValidateReceipt(record.Receipt ?? throw new BridgeError("event_journal_damaged"), record.Payload, record.Commander);
                records.Add(id, record);
            }
            catch (Exception e) when (e is JsonException or BridgeError or InvalidOperationException or ArgumentException or NullReferenceException or IOException or UnauthorizedAccessException)
            { damaged.Add(Path.GetFileName(path)); } // Preserve original evidence, never silently delete/overwrite it.
        }
    }
    private static string FileName(string id) => EventContractValidator.Hash(id) + ".json";
    private void Save(EventRecord record)
    {
        string id = record.Payload["event_id"]!.GetValue<string>();
        AtomicFiles.Write(Path.Combine(root, FileName(id)), JsonSerializer.Serialize(record));
        records[id] = record;
    }
    internal JsonObject Enqueue(JsonObject args)
    {
        if (System.Text.Encoding.UTF8.GetByteCount(args.ToJsonString()) > 48 * 1024) throw new BridgeError("event_too_large");
        var payload = EventContractValidator.Build(args, out string fingerprint, false);
        string journey = EventContractValidator.Uuid(args, "expected_journey_id");
        string commander = EventContractValidator.Uuid(args, "expected_commander_id");
        string campaign = EventContractValidator.Text(args, "campaign_id");
        string key = EventContractValidator.Text((JsonObject)args["capture"]!, "key", 512);
        string id = payload["event_id"]!.GetValue<string>();
        lock (sync)
        {
            if (damaged.Contains(FileName(id))) throw new BridgeError("event_journal_damaged");
            if (records.TryGetValue(id, out var previous))
            {
                if (previous.Fingerprint != fingerprint || previous.Commander != commander)
                {
                    string conflict = EventContractValidator.Hash(id + fingerprint) + ".conflict.json";
                    if (!conflicts.Contains(conflict) && conflicts.Count >= 1000) throw new BridgeError("event_queue_full");
                    // A conflicting replay cannot replace the original queued or accepted facts.
                    if (!conflicts.Contains(conflict)) AtomicFiles.Write(Path.Combine(root, conflict), new JsonObject { ["event_id"] = id, ["journey_id"] = journey,
                        ["campaign_id"] = campaign, ["original_fingerprint"] = previous.Fingerprint, ["replay_fingerprint"] = fingerprint,
                        ["replay"] = payload.DeepClone() }.ToJsonString());
                    conflicts.Add(conflict);
                    throw new BridgeError("event_replay_conflict");
                }
                return Handoff(previous);
            }
            var pending = records.Values.Where(r => r.State != "accepted").ToArray();
            if (records.Count >= 100000 || pending.Length >= maxPending)
                throw new BridgeError("event_queue_full");
            EventContractValidator.VerifySenderClock(args);
            if (((JsonObject)args["capture"]!)["clock_zone"]?.GetValue<string>() is not { Length: > 0 }) throw new BridgeError("event_clock_unverified");
            payload["occurred_at"] = EventContractValidator.NormalizeClock(EventContractValidator.Text((JsonObject)args["capture"]!, "captured_local", 32), EventContractValidator.Text((JsonObject)args["capture"]!, "clock_zone")).ToString("O", System.Globalization.CultureInfo.InvariantCulture);
            var record = new EventRecord(1, journey, commander, campaign, key, fingerprint,
                EventContractValidator.Hash(EventContractValidator.Canonical(payload)), payload,
                records.Count == 0 ? 1 : records.Values.Max(r => r.Order) + 1, "queued", 0, DateTimeOffset.UtcNow, "", null);
            if (pending.Sum(r => (long)System.Text.Encoding.UTF8.GetByteCount(JsonSerializer.Serialize(r))) + System.Text.Encoding.UTF8.GetByteCount(JsonSerializer.Serialize(record)) > maxPendingBytes)
                throw new BridgeError("event_queue_full");
            Save(record); // Must succeed before handoff is acknowledged.
            return Handoff(record);
        }
    }
    private static JsonObject Handoff(EventRecord record) => new()
    {
        ["durable"] = true, ["event_id"] = record.Payload["event_id"]!.DeepClone(), ["state"] = record.State,
        ["occurred_at"] = record.Payload["occurred_at"]!.DeepClone(), ["accepted_online"] = record.State == "accepted"
    };
    internal EventRecord? Next(string? journey, DateTimeOffset now)
    {
        lock (sync)
        {
            var groups = new HashSet<string>(StringComparer.Ordinal);
            foreach (var record in records.Values.Where(r => r.Journey == journey && r.State != "accepted").OrderBy(r => r.Order))
            {
                if (!groups.Add(record.Campaign + "\n" + Group(record))) continue;
                if (record.State is "queued" or "retrying" && record.NextAttempt <= now) return record;
            }
            return null;
        }
    }
    private static string Group(EventRecord record) => record.Payload["event_type"]!.GetValue<string>().StartsWith("threadline.character.", StringComparison.Ordinal)
        ? record.Payload["participants"]![0]!["instance_id"]!.GetValue<string>()
        : record.Payload["mission_ref"]?.GetValue<string>() ?? record.Key;
    internal void Accepted(EventRecord record, JsonObject receipt)
    {
        EventContractValidator.ValidateReceipt(receipt, record.Payload, record.Commander);
        lock (sync) Save(record with { State = "accepted", Receipt = (JsonObject)receipt.DeepClone(), Error = "" });
    }
    internal void Failed(EventRecord record, Exception error, DateTimeOffset now)
    {
        string code = error is BridgeError b ? b.Code : error is OperationCanceledException ? "request_timeout" : "network_unavailable";
        int status = (error as BridgeError)?.HttpStatus ?? 0;
        string state = status is 401 or 403 || code is "event_journey_finished" or "event_journey_not_started" ? "paused" :
            status is >= 400 and < 500 and not (408 or 429) || code is "api_redirect_rejected" ? "held" : "retrying";
        double seconds = Math.Min(3600, 5 * Math.Pow(2, Math.Min(record.Attempts, 10))) + Random.Shared.NextDouble() * 5;
        var delay = (error as BridgeError)?.RetryAfter;
        if (delay > TimeSpan.FromSeconds(seconds)) seconds = Math.Min(delay.Value.TotalSeconds, TimeSpan.FromDays(7).TotalSeconds);
        lock (sync) Save(record with { State = state, Attempts = record.Attempts + 1, NextAttempt = now.AddSeconds(seconds), Error = code });
    }
    internal JsonObject Status(string journey, string? campaign = null)
    {
        lock (sync)
        {
            var scoped = records.Values.Where(r => r.Journey == journey && (campaign == null || r.Campaign == campaign)).ToArray();
            var accepted = scoped.Where(r => r.State == "accepted").OrderByDescending(r => r.Order).FirstOrDefault();
            return new JsonObject
            {
                ["journey_id"] = journey, ["campaign_id"] = campaign ?? "", ["queued"] = scoped.Count(r => r.State == "queued"),
                ["retrying"] = scoped.Count(r => r.State == "retrying"), ["held"] = scoped.Count(r => r.State == "held"),
                ["paused"] = scoped.Count(r => r.State == "paused"), ["accepted"] = scoped.Count(r => r.State == "accepted"),
                ["last_accepted_at"] = accepted?.Receipt?["ingested_at"]?.DeepClone(),
                ["endpoint_damaged_files"] = damaged.Count, ["endpoint_replay_conflicts"] = conflicts.Count,
                ["last_error"] = scoped.Where(r => r.Error.Length > 0).OrderByDescending(r => r.Order).FirstOrDefault()?.Error ?? ""
            };
        }
    }
    internal JsonObject Receipts(string journey, string campaign, JsonArray ids)
    {
        if (ids.Count > 20) throw new BridgeError("request_invalid");
        var result = new JsonArray();
        lock (sync)
        {
            foreach (var node in ids)
                if (node?.GetValue<string>() is { } id && records.TryGetValue(id, out var r) && r.Journey == journey && r.Campaign == campaign) result.Add(Handoff(r));
        }
        return new JsonObject { ["records"] = result };
    }
    internal JsonObject Retry(string journey, string? campaign)
    {
        lock (sync)
        {
            foreach (var record in records.Values.Where(r => r.Journey == journey && (campaign == null || r.Campaign == campaign) && r.State is "retrying" or "paused").ToArray())
                Save(record with { State = "queued", NextAttempt = DateTimeOffset.UtcNow, Error = "" });
            return Status(journey, campaign);
        }
    }
}
