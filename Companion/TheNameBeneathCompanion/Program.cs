namespace TheNameBeneath.Companion;

internal static class Program
{
    internal const string Version = "0.10.2";

    [STAThread]
    internal static int Main(string[] args)
    {
        bool diagnostic = args.Contains("--pool-self-test") || args.Contains("--self-test") || args.Contains("--event-self-test") || args.Contains("--ui-self-test") || args.Contains("--check-development-connection") || args.Contains("--check-development-journey") || args.Contains("--headless");
        JourneyApi? diagnosticApi = null;
        try
        {
            if (args.Contains("--pool-self-test"))
            {
                int fixtures = Array.IndexOf(args, "--pool-fixture-directory");
                return CharacterPoolTests.Run(fixtures >= 0 && fixtures + 1 < args.Length ? args[fixtures + 1] : null).GetAwaiter().GetResult();
            }
            if (args.Contains("--self-test")) return CompanionTests.Run().GetAwaiter().GetResult();
            if (args.Contains("--event-self-test"))
            {
                int nativeLog = Array.IndexOf(args, "--native-event-log");
                return EventTests.Run(nativeLog >= 0 && nativeLog + 1 < args.Length ? args[nativeLog + 1] : null).GetAwaiter().GetResult();
            }
            if (args.Contains("--ui-self-test"))
            {
                ApplicationConfiguration.Initialize();
                int connectionResult = CompanionWindowTests.Run();
                return connectionResult == 0 ? CharacterPoolWindowTests.Run() : connectionResult;
            }
            var config = Configuration.Load(args);
            using var api = new JourneyApi(config);
            diagnosticApi = api;
            var connection = new ConnectionService(config, new WindowsSecrets(config.Api), api);
            using var cancel = new CancellationTokenSource();
            if (args.Contains("--check-development-connection") || args.Contains("--check-development-journey"))
            {
                string secret = config.DevelopmentCredential ?? throw new BridgeError("development_credential_missing");
                var context = api.Send("GET", "/v1/game-journey", secret, null, cancel.Token).GetAwaiter().GetResult();
                ConnectionService.ValidateContext(context);
                if (args.Contains("--check-development-journey"))
                {
                    JourneyProjection.Context(context);
                    JourneyProjection.Roster(api.Send("GET", "/v1/game-journey/roster?limit=5", secret, null, cancel.Token).GetAwaiter().GetResult(), context["journey_id"]!.GetValue<string>());
                    Console.WriteLine("Read-only Journey/commander/roster projection verified; credential and roster details redacted.");
                }
                Console.WriteLine("Development API connection verified; credential redacted.");
                return 0;
            }
            // Start on a worker so the socket service never captures the WinForms UI context.
            var listener = new LoopbackServer(connection, config.Port);
            if (args.Contains("--headless"))
            {
                Console.CancelKeyPress += (_, e) => { e.Cancel = true; cancel.Cancel(); };
                var headlessReady = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
                var headlessServer = listener.Run(cancel.Token, port => { Console.WriteLine("Listening on 127.0.0.1:" + port); headlessReady.TrySetResult(); });
                Task.WhenAny(headlessReady.Task, headlessServer).GetAwaiter().GetResult();
                if (!headlessReady.Task.IsCompletedSuccessfully) headlessServer.GetAwaiter().GetResult();
                var delivery = Task.Run(() => connection.RunEventDelivery(cancel.Token));
                try { headlessServer.GetAwaiter().GetResult(); }
                finally { cancel.Cancel(); delivery.GetAwaiter().GetResult(); }
                return 0;
            }
            ApplicationConfiguration.Initialize();
            using var window = new CompanionWindow(config, connection, cancel);
            var ready = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
            var server = Task.Run(() => listener.Run(cancel.Token, _ => ready.TrySetResult()));
            Task? eventDelivery = null;
            window.ObserveListener(server);
            try
            {
                // A second copy must fail before offering credential controls with stale context.
                Task.WhenAny(ready.Task, server).GetAwaiter().GetResult();
                if (!ready.Task.IsCompletedSuccessfully) server.GetAwaiter().GetResult();
                eventDelivery = Task.Run(() => connection.RunEventDelivery(cancel.Token));
                Application.Run(window);
            }
            finally { cancel.Cancel(); server.GetAwaiter().GetResult(); eventDelivery?.GetAwaiter().GetResult(); }
            return 0;
        }
        catch (Exception error)
        {
            // Neither exception messages nor URLs with development protection belong in diagnostics.
            string message = CompanionMessages.Error(error);
            if (diagnostic)
            {
                Console.Error.WriteLine(message);
                if (diagnosticApi?.LastStatus > 0) Console.Error.WriteLine("API HTTP status: " + diagnosticApi.LastStatus);
                if (diagnosticApi?.RedirectOrigin != null) Console.Error.WriteLine("Redirect origin: " + diagnosticApi.RedirectOrigin);
                if (error is BridgeError bridge && !bridge.Code.StartsWith("tlj_", StringComparison.Ordinal))
                    Console.Error.WriteLine("Diagnostic code: " + bridge.Code);
            }
            else MessageBox.Show(message, "The Name Beneath companion", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
