using System.Net;
using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

internal static class LifecycleTests
{
    private static void Check(bool condition) { if (!condition) throw new Exception("Lifecycle assertion failed"); }
    private static JsonObject Args(int version = 7) => new()
    {
        ["expected_journey_id"] = CompanionTests.JourneyId, ["expected_version"] = version, ["confirmed"] = true
    };
    private static async Task Reject(Func<Task<JsonObject>> action, string code)
    {
        try { await action(); throw new Exception("Invalid lifecycle request accepted"); }
        catch (BridgeError error) { Check(error.Code == code); }
    }
    internal static async Task Run(Configuration original)
    {
        var config = original with { DataDirectory = Path.Combine(original.DataDirectory, "lifecycle") };
        var handler = new Handler();
        using var api = new ThreadlineApi(config, handler);
        var vault = new CompanionTests.MemoryVault();
        var service = new ConnectionService(config, vault, api);
        await service.Import(CompanionTests.Secret, CancellationToken.None);
        Check(service.Status()["journey_status"]!.GetValue<string>() == "upcoming");
        Check(handler.Posts == 0);
        var legacy = await service.PreviewContext("", CancellationToken.None);
        Check(!legacy["can_manage_journey"]!.GetValue<bool>());
        await Reject(() => service.StartJourney(Args(), CancellationToken.None), "journey_management_permission_missing");
        handler.Manage = true;
        await service.Import(CompanionTests.Secret, CancellationToken.None);
        var preview = await service.PreviewContext("", CancellationToken.None);
        Check(preview["can_manage_journey"]!.GetValue<bool>() && preview["journey_version"]!.GetValue<int>() == 7);
        service.Status(); await service.Test(CancellationToken.None);
        Check(handler.Posts == 0); // Import/Test/Preview/Status never starts.
        var unconfirmed = Args(); unconfirmed["confirmed"] = false;
        await Reject(() => service.StartJourney(unconfirmed, CancellationToken.None), "journey_start_confirmation_required");
        await Reject(() => service.StartJourney(Args(0), CancellationToken.None), "journey_start_confirmation_required");
        var other = Args(); other["expected_journey_id"] = Guid.NewGuid().ToString();
        await Reject(() => service.StartJourney(other, CancellationToken.None), "journey_mismatch");
        Check(handler.Posts == 0);
        using (var cancelled = new CancellationTokenSource())
        {
            cancelled.Cancel();
            try { await service.StartJourney(Args(), cancelled.Token); throw new Exception("Cancelled start accepted"); }
            catch (OperationCanceledException) { }
        }
        Check(handler.Posts == 0);
        handler.LoseReply = true;
        try { await service.StartJourney(Args(), CancellationToken.None); throw new Exception("Lost reply accepted"); }
        catch (HttpRequestException) { }
        Check(handler.Posts == 1 && handler.Transitions == 1); // no automatic retry
        var recovered = await service.PreviewContext(CompanionTests.JourneyId, CancellationToken.None);
        Check(recovered["journey_status"]!.GetValue<string>() == "started" && recovered["journey_version"]!.GetValue<int>() == 8);
        var started = await service.StartJourney(Args(), CancellationToken.None);
        Check(started["journey_status"]!.GetValue<string>() == "started" && handler.Transitions == 1);
        Check(started["journey_title"]!.GetValue<string>() == "Lifecycle title" && service.Status()["journey_title"]!.GetValue<string>() == "Lifecycle title");
        Check(!started.ToJsonString().Contains(CompanionTests.Secret, StringComparison.Ordinal));
        Check(!File.ReadAllText(service.ContextPath).Contains(CompanionTests.Secret, StringComparison.Ordinal));
        handler.Deny = true;
        await Reject(() => service.StartJourney(Args(), CancellationToken.None), "journey_credential_scope_insufficient");
        handler.Deny = false;
        handler.WrongJourney = true;
        await Reject(() => service.StartJourney(Args(), CancellationToken.None), "journey_mismatch");
        handler.WrongJourney = false;
        handler.MissingVersion = true;
        await Reject(() => service.StartJourney(Args(), CancellationToken.None), "journey_start_response_invalid");
        handler.MissingVersion = false;
        handler.FinishedReply = true;
        await Reject(() => service.StartJourney(Args(), CancellationToken.None), "journey_not_started");
        handler.FinishedReply = false;
        using var stop = new CancellationTokenSource();
        var ready = new TaskCompletionSource<int>(TaskCreationOptions.RunContinuationsAsynchronously);
        var server = new LoopbackServer(service, 0).Run(stop.Token, port => ready.TrySetResult(port));
        int port = await ready.Task.WaitAsync(TimeSpan.FromSeconds(5));
        try
        {
            var request = new JsonObject { ["protocol"] = 2, ["request_id"] = 1, ["op"] = "journey_start", ["args"] = Args() };
            var response = await CompanionTests.Call(port, request.ToJsonString() + "\n");
            Check(response["ok"]!.GetValue<bool>() && response["data"]?["journey_status"]?.GetValue<string>() == "started");
            int before = handler.Posts;
            foreach (string op in new[] { "journey_finish", "journey_reopen", "journey_manage" })
            {
                request["op"] = op;
                response = await CompanionTests.Call(port, request.ToJsonString() + "\n");
                Check(!response["ok"]!.GetValue<bool>() && response["error"]!.GetValue<string>() == "operation_unknown");
            }
            Check(handler.Posts == before); // no generic lifecycle proxy exposed
        }
        finally { stop.Cancel(); await server; }
        Console.WriteLine("PASS: explicit Journey start, legacy-scope compatibility, exact target/version, no read-side start, cancellation, lost-response recovery, idempotent retry, socket allowlist and redaction (fake API only).");
    }
    private sealed class Handler : HttpMessageHandler
    {
        internal bool Manage, LoseReply, Deny, WrongJourney, MissingVersion, FinishedReply;
        internal int Posts, Transitions, Version = 7;
        internal string State = "upcoming";
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancel)
        {
            Check(request.Headers.Authorization?.Parameter == CompanionTests.Secret);
            if (request.Method == HttpMethod.Post)
            {
                Posts++;
                Check(request.RequestUri?.AbsolutePath == "/v1/game-journey/lifecycle");
                var body = JsonNode.Parse(await request.Content!.ReadAsStringAsync(cancel))!.AsObject();
                Check(body.Count == 3 && body["action"]!.GetValue<string>() == "start" && body["expected_journey_id"]!.GetValue<string>() == CompanionTests.JourneyId && body["expected_version"]!.GetValue<int>() == 7);
                if (Deny) return new HttpResponseMessage(HttpStatusCode.Forbidden) { Content = new StringContent(new JsonObject { ["error"] = new JsonObject { ["code"] = "journey_credential_scope_insufficient" } }.ToJsonString()) };
                if (State == "upcoming") { State = "started"; Version++; Transitions++; }
                if (LoseReply) { LoseReply = false; throw new HttpRequestException("Synthetic lost start reply"); }
            }
            else Check(request.Method == HttpMethod.Get);
            var context = CompanionTests.Context(); context["status"] = State; context["journey_version"] = Version;
            context["journey_title"] = "Lifecycle title";
            if (Manage) context["capabilities"]!.AsArray().Add("journey:manage");
            if (WrongJourney) context["journey_id"] = Guid.NewGuid().ToString();
            if (MissingVersion) context.Remove("journey_version");
            if (FinishedReply) context["status"] = "finished";
            return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(new JsonObject { ["data"] = context }.ToJsonString()) };
        }
    }
}
