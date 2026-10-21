using System.Net;
using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal static class JourneyTitleTests
{
    private static void Check(bool value) { if (!value) throw new Exception("Journey title assertion failed"); }
    private static void Reject(JsonObject context)
    {
        try { JourneyProjection.Context(context); throw new Exception("Invalid title accepted"); }
        catch (BridgeError error) { Check(error.Code == "api_response_invalid"); }
        try { ConnectionService.ValidateContext(context); throw new Exception("Invalid cached title accepted"); }
        catch (BridgeError error) { Check(error.Code == "api_response_invalid"); }
    }
    internal static async Task Run(Configuration original)
    {
        foreach (JsonNode? value in new JsonNode?[] { null, JsonValue.Create(""), JsonValue.Create("  "), JsonValue.Create(42), new JsonObject(), JsonValue.Create(new string('a', 161)) })
        {
            var context = CompanionTests.Context(); context["journey_title"] = value; Reject(context);
        }
        var valid = CompanionTests.Context(); valid.Remove("journey_title"); Reject(valid);
        string unicode = string.Concat(Enumerable.Repeat("\U0001f30c", 160));
        valid["journey_title"] = unicode;
        Check(JourneyProjection.Context(valid)["journey_title"]!.GetValue<string>() == unicode);
        valid["journey_title"] = unicode + "x"; Reject(valid);
        valid["journey_title"] = "<Resistance> & Resolve\n\u96ea\u2028Again";
        Check(JourneyProjection.Context(valid)["journey_title"]!.GetValue<string>() == valid["journey_title"]!.GetValue<string>());
        Check(JourneyProjection.DisplayTitle(valid["journey_title"]!.GetValue<string>()) == "<Resistance> & Resolve \u96ea Again");
        Check(JourneyProjection.DisplayTitle(null).Contains("unavailable", StringComparison.Ordinal));

        var config = original with { DataDirectory = Path.Combine(original.DataDirectory, "titles") };
        var handler = new Handler();
        using var api = new JourneyApi(config, handler);
        var vault = new CompanionTests.MemoryVault();
        var service = new ConnectionService(config, vault, api);
        var imported = await service.Import(CompanionTests.Secret, CancellationToken.None);
        Check(imported["journey_title"]!.GetValue<string>() == handler.Title && imported["game_name"]!.GetValue<string>() == "XCOM 2");
        string originalJourney = service.Journey!;
        handler.Title = "A renamed Journey & \u96ea";
        var tested = await service.Test(CancellationToken.None);
        Check(tested["journey_title"]!.GetValue<string>() == handler.Title && service.Journey == originalJourney);
        Check(tested["title_observed_at"]!.GetValue<string>().Length > 0);
        var projected = await service.PreviewContext(originalJourney, CancellationToken.None);
        Check(projected["journey_title"]!.GetValue<string>() == handler.Title && projected["traits"]!.AsArray().Count == 1);
        var reloaded = new ConnectionService(config, vault, api);
        Check(reloaded.Status()["journey_title"]!.GetValue<string>() == handler.Title && reloaded.Status()["connection"]!.GetValue<string>() == "unverified");
        handler.Invalid = true;
        try { await service.Test(CancellationToken.None); throw new Exception("Invalid fresh title accepted"); }
        catch (BridgeError error) { Check(error.Code == "api_response_invalid"); }
        Check(service.Status()["journey_title"]!.GetValue<string>() == handler.Title);
        Check(handler.Posts == 0); // Names never trigger lifecycle, activation, event or grant calls.
        var oldCache = JsonNode.Parse(File.ReadAllText(service.ContextPath))!.AsObject();
        oldCache.Remove("journey_title"); oldCache.Remove("_tnb_title_observed_at");
        AtomicFiles.Write(service.ContextPath, oldCache.ToJsonString());
        var legacy = new ConnectionService(config, vault, api);
        Check(legacy.Status()["credential_stored"]!.GetValue<bool>() && legacy.Status()["journey_title"]!.GetValue<string>() == "");
        handler.Invalid = false;
        Check((await legacy.Test(CancellationToken.None))["journey_title"]!.GetValue<string>() == handler.Title);
        Console.WriteLine("PASS: required Journey title, Unicode bounds, literal display, rename/cache refresh, legacy title-less cache, invalid-response preservation and stable identity (fake GETs only).");
    }
    private sealed class Handler : HttpMessageHandler
    {
        internal string Title = "Original Journey";
        internal bool Invalid;
        internal int Posts;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancel)
        {
            if (request.Method != HttpMethod.Get) Posts++;
            var context = CompanionTests.Context();
            context["journey_title"] = Invalid ? null : Title;
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(new JsonObject { ["data"] = context }.ToJsonString()) });
        }
    }
}
