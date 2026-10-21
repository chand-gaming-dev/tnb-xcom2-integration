using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal sealed class LoopbackServer(ConnectionService connection, int port)
{
    internal const int Protocol = 2;
    internal const int MaximumFrameBytes = 65536;
    internal async Task Run(CancellationToken cancel, Action<int>? started = null)
    {
        var listener = new TcpListener(IPAddress.Loopback, port) { ExclusiveAddressUse = true };
        listener.Start(8);
        started?.Invoke(((IPEndPoint)listener.LocalEndpoint).Port);
        var tasks = new List<Task>();
        using var limit = new SemaphoreSlim(4, 4);
        try
        {
            while (!cancel.IsCancellationRequested)
            {
                await limit.WaitAsync(cancel);
                TcpClient client;
                try { client = await listener.AcceptTcpClientAsync(cancel); }
                catch { limit.Release(); throw; }
                tasks.RemoveAll(task => task.IsCompleted);
                tasks.Add(Handle(client, limit, cancel));
            }
        }
        catch (OperationCanceledException) when (cancel.IsCancellationRequested) { }
        finally { listener.Stop(); await Task.WhenAll(tasks); }
    }
    private async Task Handle(TcpClient client, SemaphoreSlim limit, CancellationToken stopping)
    {
        using (client)
        using (var timeout = CancellationTokenSource.CreateLinkedTokenSource(stopping))
        {
            timeout.CancelAfter(TimeSpan.FromSeconds(25));
            try
            {
                client.NoDelay = true;
                var stream = client.GetStream();
                string frame = await ReadFrame(stream, timeout.Token);
                JsonObject response;
                int requestId = 0;
                try
                {
                    if (!frame.StartsWith('{')) throw new BridgeError("protocol_invalid");
                    var request = JsonNode.Parse(frame) as JsonObject ?? throw new BridgeError("protocol_invalid");
                    requestId = request["request_id"]?.GetValue<int>() ?? 0;
                    if (request["protocol"]?.GetValue<int>() != Protocol) throw new BridgeError("protocol_mismatch");
                    JsonObject data = await Dispatch(request, timeout.Token);
                    response = new JsonObject { ["protocol"] = Protocol, ["request_id"] = requestId, ["ok"] = true, ["data"] = data };
                }
                catch (Exception error)
                {
                    string code = error is BridgeError bridge ? bridge.Code : error is HttpRequestException ? "network_unavailable" : error is OperationCanceledException ? "request_timeout" : error is IOException or UnauthorizedAccessException ? "local_storage_unavailable" : "request_invalid";
                    response = new JsonObject { ["protocol"] = Protocol, ["request_id"] = requestId, ["ok"] = false, ["error"] = code };
                    try { response["data"] = connection.Status(); } catch { /* A damaged cache must not terminate the listener. */ }
                }
                // The default encoder escapes non-ASCII characters for UE3's text socket conversion.
                var output = Encoding.ASCII.GetBytes(response.ToJsonString() + "\n");
                if (output.Length > MaximumFrameBytes) return;
                await stream.WriteAsync(output, stopping);
            }
            catch (Exception error) when (error is IOException or SocketException or OperationCanceledException or BridgeError) { }
            finally { limit.Release(); }
        }
    }
    private async Task<JsonObject> Dispatch(JsonObject request, CancellationToken cancel)
    {
        string operation = request["op"]?.GetValue<string>() ?? "";
        return operation switch
        {
            "ping" => new JsonObject { ["companion_version"] = Program.Version, ["protocol"] = Protocol, ["armory_link_version"] = 2, ["journey_management_version"] = 1, ["gameplay_events_version"] = 1, ["bond_milestones_version"] = 1, ["factual_events_version"] = 1, ["clock_zone"] = TimeZoneInfo.Local.Id, ["local_clock"] = DateTime.Now.ToString("yyyy-MM-dd'T'HH:mm:ss.fff", System.Globalization.CultureInfo.InvariantCulture), ["message"] = "The Name Beneath companion ready" },
            "status" => connection.Status(),
            "test" => await connection.Test(cancel),
            "journey_context" => await connection.PreviewContext(request["args"]?["expected_journey_id"]?.GetValue<string>() ?? "", cancel),
            "journey_start" => await connection.StartJourney(request["args"] as JsonObject ?? throw new BridgeError("request_invalid"), cancel),
            "roster" => await connection.PreviewRoster(request["args"]?["expected_journey_id"]?.GetValue<string>() ?? "", request["args"]?["cursor"]?.GetValue<string>() ?? "", cancel),
            "activation_status" or "activate" or "activation_ack" => await connection.LinkOperation(operation, request["args"] as JsonObject ?? throw new BridgeError("request_invalid"), cancel),
            "events_enqueue" or "events_status" or "events_receipts" or "events_retry" => await connection.EventOperation(operation, request["args"] as JsonObject ?? throw new BridgeError("request_invalid"), cancel),
            _ => throw new BridgeError("operation_unknown")
        };
    }
    internal static async Task<string> ReadFrame(Stream stream, CancellationToken cancel)
    {
        using var memory = new MemoryStream();
        var buffer = new byte[1024];
        while (true)
        {
            int count = await stream.ReadAsync(buffer, cancel);
            if (count == 0) throw new BridgeError("frame_incomplete");
            for (int i = 0; i < count; i++)
            {
                if (buffer[i] == '\n') return Encoding.ASCII.GetString(memory.ToArray()).TrimEnd('\r');
                if (buffer[i] > 127 || memory.Length >= MaximumFrameBytes) throw new BridgeError("frame_invalid");
                memory.WriteByte(buffer[i]);
            }
        }
    }
}
