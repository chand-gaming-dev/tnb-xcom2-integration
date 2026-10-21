namespace TheNameBeneath.Companion;

internal sealed class BridgeError(string code, int httpStatus = 0, TimeSpan? retryAfter = null) : Exception(code)
{
    public string Code { get; } = code;
    internal int HttpStatus { get; } = httpStatus;
    internal TimeSpan? RetryAfter { get; } = retryAfter;
}

internal sealed record Configuration(Uri Api, int Port, string DataDirectory, string? ProtectionToken, string? DevelopmentCredential)
{
    internal const string DefaultApi = "https://411118fe-d137-412d-a4ae-8990609684d8-00-2xyc418vgc8ol.worf.replit.dev/";
    internal static Configuration Load(string[] args)
    {
        string? Option(string name)
        {
            int i = Array.IndexOf(args, name);
            if (i < 0) return null;
            if (i + 1 >= args.Length || args[i + 1].StartsWith("--", StringComparison.Ordinal)) throw new BridgeError("invalid_arguments");
            return args[i + 1];
        }
        var values = new Dictionary<string, string>(StringComparer.Ordinal);
        var developmentFile = Option("--dev-config");
        if (developmentFile != null)
        {
            foreach (var raw in File.ReadLines(developmentFile))
            {
                var line = raw.Trim();
                if (line.Length == 0 || line.StartsWith('#')) continue;
                int split = line.IndexOf('=');
                if (split <= 0) continue;
                string key = line[..split].Trim();
                if (key is not ("THREADLINE_DEV_API_BASE_URL" or "REPLIT_DEV_EXTERNAL_ACCESS_TOKEN" or "THREADLINE_JOURNEY_CREDENTIAL")) continue;
                string value = line[(split + 1)..].Trim();
                if (value.Length >= 2 && ((value[0] == '\'' && value[^1] == '\'') || (value[0] == '"' && value[^1] == '"'))) value = value[1..^1];
                values[key] = value;
            }
        }
        string? Setting(string key) => Environment.GetEnvironmentVariable(key) is { Length: > 0 } env ? env : values.GetValueOrDefault(key);
        var api = new Uri(Option("--api") ?? Setting("THREADLINE_DEV_API_BASE_URL") ?? DefaultApi);
        if ((api.Scheme != "https" && !(api.Scheme == "http" && api.IsLoopback)) || api.UserInfo.Length != 0 || api.Query.Length != 0 || api.Fragment.Length != 0 || api.AbsolutePath != "/")
            throw new BridgeError("invalid_api_origin");
        int port = int.Parse(Option("--port") ?? "27129", System.Globalization.CultureInfo.InvariantCulture);
        if (port is < 1024 or > 65535) throw new BridgeError("invalid_port");
        // Persisted location is a compatibility identifier, not public branding.
        string data = Option("--data") ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Threadline", "TheNameBeneath");
        string? protection = Setting("REPLIT_DEV_EXTERNAL_ACCESS_TOKEN");
        if (protection != null && !api.Host.EndsWith(".replit.dev", StringComparison.OrdinalIgnoreCase)) throw new BridgeError("protection_origin_mismatch");
        // The existing Vanguard credential is loaded only with an explicit development-file option.
        return new(api, port, Path.GetFullPath(data), protection, developmentFile == null ? null : Setting("THREADLINE_JOURNEY_CREDENTIAL"));
    }
}
