namespace TheNameBeneath.Companion;

internal static class ConfigurationTests
{
    internal static async Task Run(string root)
    {
        static void Check(bool condition, string code) { if (!condition) throw new Exception(code); }
        const string developmentOrigin = "https://configuration-tests.replit.dev/";
        var stale = new Dictionary<string, string>
        {
            ["THREADLINE_DEV_API_BASE_URL"] = developmentOrigin,
            ["REPLIT_DEV_EXTERNAL_ACCESS_TOKEN"] = "synthetic-stale-token",
            ["THREADLINE_JOURNEY_CREDENTIAL"] = CompanionTests.Secret
        };
        var production = Configuration.Load([], stale.GetValueOrDefault);
        Check(production.Api.AbsoluteUri == "https://thenamebeneath.com/" && production.ProtectionToken == null &&
            production.DevelopmentCredential == null, "production_ignores_stale_development_environment");

        Directory.CreateDirectory(root);
        string file = Path.Combine(root, "synthetic-development.env");
        File.WriteAllText(file, $"THREADLINE_DEV_API_BASE_URL={developmentOrigin}\nREPLIT_DEV_EXTERNAL_ACCESS_TOKEN=synthetic-file-token\n");
        var fromFile = Configuration.Load(["--dev-config", file], _ => null);
        Check(fromFile.Api.AbsoluteUri == developmentOrigin && fromFile.ProtectionToken == "synthetic-file-token", "explicit_development_file_retained");
        var fromEnvironment = Configuration.Load(["--dev-config", file], stale.GetValueOrDefault);
        Check(fromEnvironment.ProtectionToken == "synthetic-stale-token" && fromEnvironment.DevelopmentCredential == CompanionTests.Secret,
            "explicit_development_environment_precedence_retained");
        var explicitProduction = Configuration.Load(["--api", Configuration.DefaultApi, "--dev-config", file], stale.GetValueOrDefault);
        Check(explicitProduction.Api == production.Api && explicitProduction.ProtectionToken == null, "production_never_uses_development_protection");
        var explicitDevelopment = Configuration.Load(["--api", developmentOrigin], stale.GetValueOrDefault);
        Check(explicitDevelopment.ProtectionToken == "synthetic-stale-token" && explicitDevelopment.DevelopmentCredential == null,
            "explicit_development_origin_retained");

        var handler = new CompanionTests.FakeHandler();
        using var api = new JourneyApi(production, handler);
        await api.Send("GET", "/v1/game-journey", CompanionTests.Secret, null, CancellationToken.None);
        Check(handler.Path == "/v1/game-journey" && handler.Auth == CompanionTests.Secret, "production_json_bearer_without_bypass");
        using var poolHandler = new CharacterPoolTests.PoolHandler(new byte[22]);
        using var poolApi = new JourneyApi(production, poolHandler);
        await poolApi.DownloadCharacterPools(CompanionTests.Secret, CancellationToken.None);
        Check(poolHandler.Path == "/v1/game-journey/character-pools.zip" && poolHandler.Auth == CompanionTests.Secret,
            "production_zip_bearer_without_bypass");
        using var productionService = new DisposableApiService(production with { DataDirectory = root });
        using var developmentService = new DisposableApiService(fromFile with { DataDirectory = root });
        Check(productionService.Service.ContextPath != developmentService.Service.ContextPath,
            "production_and_development_context_remain_separate");
        Console.WriteLine("PASS: Production default, stale development settings ignored, explicit development opt-in, bearer-only JSON/ZIP and endpoint isolation.");
    }

    private sealed class DisposableApiService : IDisposable
    {
        private readonly JourneyApi api;
        internal ConnectionService Service { get; }
        internal DisposableApiService(Configuration config)
        {
            api = new JourneyApi(config, new CompanionTests.FakeHandler());
            Service = new ConnectionService(config, new CompanionTests.MemoryVault(), api);
        }
        public void Dispose() => api.Dispose();
    }
}
