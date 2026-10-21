using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal sealed partial class ConnectionService
{
    private readonly EventOutbox events;
    private string reportingError = "";
    internal JsonObject ReportingStatus()
    {
        var result = events.Status(Journey ?? "");
        result["local_storage_error"] = reportingError;
        result["delivery_enabled"] = Journey is { } id && vault.Read(id) != null;
        return result;
    }
    internal void RetryReporting() => events.Retry(Journey ?? "", null);
    internal async Task<JsonObject> EventOperation(string operation, JsonObject args, CancellationToken cancel)
    {
        string journey = EventContractValidator.Uuid(args, "expected_journey_id");
        string campaign = EventContractValidator.Text(args, "campaign_id");
        await gate.WaitAsync(cancel);
        try
        {
            if (journey != Journey) throw new BridgeError("journey_mismatch");
            if (operation == "events_enqueue")
            {
                if (EventContractValidator.Uuid(args, "expected_commander_id") != context?["commander"]?["id"]?.GetValue<string>()) throw new BridgeError("journey_mismatch");
                return events.Enqueue(args); // Offline handoff is permitted; credential validation is NOT an HTTP dependency.
            }
            return operation switch
            {
                "events_status" => events.Status(journey, campaign),
                "events_retry" => events.Retry(journey, campaign),
                "events_receipts" => events.Receipts(journey, campaign, args["event_ids"] as JsonArray ?? throw new BridgeError("request_invalid")),
                _ => throw new BridgeError("operation_unknown")
            };
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException) { reportingError = "local_storage_unavailable"; throw; }
        finally { gate.Release(); }
    }
    internal async Task<bool> DeliverOne(CancellationToken cancel)
    {
        // Selection and credential use share the same guard as import/remove/linking.
        await gate.WaitAsync(cancel);
        try
        {
            var record = events.Next(Journey, DateTimeOffset.UtcNow);
            if (record == null || vault.Read(record.Journey) == null) return false;
            if (record.Commander != context?["commander"]?["id"]?.GetValue<string>()) return false;
            try
            {
                var receipt = await api.Send("POST", "/v1/game-journey/events", Credential(record.Journey), record.Payload, cancel);
                if (api.LastStatus is not (200 or 201)) throw new BridgeError("event_receipt_invalid");
                if ((api.LastStatus == 201 && receipt["status"]?.GetValue<string>() != "accepted") || (api.LastStatus == 200 && receipt["status"]?.GetValue<string>() != "duplicate")) throw new BridgeError("event_receipt_invalid");
                events.Accepted(record, receipt);
                reportingError = "";
            }
            catch (OperationCanceledException) when (cancel.IsCancellationRequested) { throw; }
            catch (Exception e) when (e is BridgeError or HttpRequestException or OperationCanceledException or System.Text.Json.JsonException or InvalidOperationException)
            { events.Failed(record, e, DateTimeOffset.UtcNow); }
            return true;
        }
        finally { gate.Release(); }
    }
    internal async Task RunEventDelivery(CancellationToken cancel)
    {
        try
        {
            while (!cancel.IsCancellationRequested)
            {
                try { await DeliverOne(cancel); }
                catch (Exception e) when (e is IOException or UnauthorizedAccessException) { reportingError = "local_storage_unavailable"; }
                catch (Exception e) when (e is BridgeError or System.Text.Json.JsonException or InvalidOperationException) { reportingError = "reporting_delivery_unavailable"; }
                await Task.Delay(1000, cancel);
            }
        }
        catch (OperationCanceledException) when (cancel.IsCancellationRequested) { }
    }
}
