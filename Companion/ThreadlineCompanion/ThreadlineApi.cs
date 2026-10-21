using System.Net.Http.Headers;
using System.Text;
using System.Text.Json.Nodes;

namespace ThreadlineCompanion;

internal sealed partial class ThreadlineApi : IDisposable
{
    private readonly Configuration config;
    private readonly HttpClient http;
    internal int LastStatus { get; private set; }
    internal string? RedirectOrigin { get; private set; }
    internal ThreadlineApi(Configuration configuration, HttpMessageHandler? handler = null)
    {
        config = configuration;
        // Each operation supplies its own deadline. JSON remains bounded at 15 s;
        // a verified binary export may take longer without changing JSON behavior.
        http = new HttpClient(handler ?? new HttpClientHandler { AllowAutoRedirect = false, UseCookies = false }) { Timeout = Timeout.InfiniteTimeSpan };
    }
    internal async Task<JsonObject> Send(string method, string path, string secret, JsonObject? body, CancellationToken cancel)
    {
        using var deadline = CancellationTokenSource.CreateLinkedTokenSource(cancel);
        deadline.CancelAfter(TimeSpan.FromSeconds(15));
        cancel = deadline.Token;
        if (!path.StartsWith("/v1/game-journey", StringComparison.Ordinal) || path.StartsWith("//", StringComparison.Ordinal)) throw new BridgeError("invalid_api_path");
        string url = config.Api.GetLeftPart(UriPartial.Authority) + path;
        if (!string.IsNullOrEmpty(config.ProtectionToken)) url += (path.Contains('?') ? "&" : "?") + "project-protection-bypass=" + Uri.EscapeDataString(config.ProtectionToken);
        using var request = new HttpRequestMessage(new HttpMethod(method), url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", secret);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        request.Headers.CacheControl = new CacheControlHeaderValue { NoStore = true };
        if (body != null) request.Content = new StringContent(body.ToJsonString(), Encoding.UTF8, "application/json");
        using var response = await http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancel);
        LastStatus = (int)response.StatusCode;
        TimeSpan? retryAfter = response.Headers.RetryAfter?.Delta ?? (response.Headers.RetryAfter?.Date - DateTimeOffset.UtcNow);
        RedirectOrigin = response.Headers.Location is { IsAbsoluteUri: true } location ? location.GetLeftPart(UriPartial.Authority) : response.Headers.Location != null ? "same-origin relative redirect" : null;
        if ((int)response.StatusCode is >= 300 and < 400) throw new BridgeError("api_redirect_rejected");
        using var stream = await response.Content.ReadAsStreamAsync(cancel);
        using var memory = new MemoryStream();
        var buffer = new byte[8192];
        int count;
        try
        {
            while ((count = await stream.ReadAsync(buffer, cancel)) != 0)
            {
                if (memory.Length + count > 2 * 1024 * 1024) throw new BridgeError("api_response_too_large", LastStatus, retryAfter);
                memory.Write(buffer, 0, count);
            }
        }
        catch (IOException) { throw new HttpRequestException("API response interrupted"); }
        JsonObject? parsed;
        try { parsed = JsonNode.Parse(memory.ToArray()) as JsonObject; }
        catch (System.Text.Json.JsonException) { throw new BridgeError(response.IsSuccessStatusCode ? "api_response_invalid" : "api_error", LastStatus, retryAfter); }
        if (!response.IsSuccessStatusCode)
        {
            string fallback = (int)response.StatusCode switch { 401 => "invalid_credential", 403 => "scope_missing", 429 => "rate_limited", >= 500 => "api_unavailable", _ => "api_rejected" };
            string? code = parsed?["error"] is JsonObject failure && failure["code"] is JsonValue value && value.TryGetValue<string>(out string? errorCode) ? errorCode : null;
            if (code == null || code.Length > 64 || code.Any(c => !(char.IsAsciiLetterLower(c) || char.IsAsciiDigit(c) || c == '_'))) code = fallback;
            throw new BridgeError(code, LastStatus, retryAfter);
        }
        return parsed?["data"] as JsonObject ?? throw new BridgeError("api_response_invalid");
    }
    public void Dispose() => http.Dispose();
}
