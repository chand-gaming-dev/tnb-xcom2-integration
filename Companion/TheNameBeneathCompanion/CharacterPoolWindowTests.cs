using System.Net;

namespace TheNameBeneath.Companion;

internal static class CharacterPoolWindowTests
{
    private static void Check(bool condition, string label) { if (!condition) throw new BridgeError("pool_ui_test_" + label); }
    internal static int Run()
    {
        int result = 1;
        string root = Path.Combine(Path.GetTempPath(), "TNB-PoolUITests-" + Guid.NewGuid().ToString("N"));
        try
        {
            Check(CharacterPoolsPanel.MergedFileName("TNB Test 1", "12345678-rest") == "TNB-TNB Test 1.bin", "journey_filename");
            Check(CharacterPoolsPanel.MergedFileName("  Resistance: West/East?*\"<>|\\  ", "12345678-rest") == "TNB-Resistance- West-East.bin", "safe_filename");
            Check(CharacterPoolsPanel.MergedFileName(" .. ", "12345678-rest") == "TNB-Journey-12345678.bin", "empty_filename_fallback");
            Check(CharacterPoolsPanel.MergedFileName(null, "12345678-rest") == "TNB-Journey-12345678.bin", "legacy_filename_fallback");
            string unicodeName = CharacterPoolsPanel.MergedFileName(new string('A', 99) + "\U0001F680" + "Last", "12345678-rest");
            Check(unicodeName == "TNB-" + new string('A', 99) + ".bin", "bounded_unicode_filename");
            var config = new Configuration(new Uri("https://pool-ui.invalid/"), 27129, root, null, null);
            using var handler = new CharacterPoolTests.PoolHandler(CharacterPoolTests.Zip(("character.bin", CharacterPoolTests.Fixture())));
            using var api = new JourneyApi(config, handler);
            var service = new ConnectionService(config, new CompanionTests.MemoryVault(), api);
            using var stopping = new CancellationTokenSource();
            using var window = new CompanionWindow(config, service, stopping) { ShowInTaskbar = false, Opacity = 0 };
            using var deadline = new System.Windows.Forms.Timer { Interval = 20000 };
            deadline.Tick += (_, _) => window.Close();
            window.Shown += async (_, _) =>
            {
                try
                {
                    Check(window.Tabs.TabPages.Count == 3 && !window.PoolsPanel.DownloadButton.Enabled, "tabs_unconfigured");
                    Check(handler.PoolRequests == 0, "no_automatic_download");
                    window.CredentialInput.Text = CompanionTests.Secret;
                    await window.SaveEnteredCredential();
                    window.Tabs.SelectedIndex = 2;
                    Check(window.AcceptButton == null, "no_hidden_accept_action");
                    Check(window.PoolsPanel.JourneyText.Text.Contains("René's Resistance & Resolve", StringComparison.Ordinal) && !window.PoolsPanel.JourneyText.UseMnemonic, "journey_name_literal");
                    Check(window.PoolsPanel.DownloadButton.Enabled, "download_enabled");
                    Check(window.PoolsPanel.SuggestedMergedFileName == "TNB-Ren\u00e9's Resistance & Resolve.bin", "cached_journey_filename");
                    handler.Release = new(TaskCreationOptions.RunContinuationsAsynchronously);
                    var pending = window.PoolsPanel.Download();
                    await handler.Entered.Task.WaitAsync(TimeSpan.FromSeconds(2));
                    Check(window.PoolsPanel.IsBusy && !window.CredentialInput.Enabled && !window.PoolsPanel.DownloadButton.Enabled, "controls_busy");
                    handler.Release.TrySetResult(); await pending; handler.Release = null;
                    Check(!window.PoolsPanel.IsBusy && window.CredentialInput.Enabled && window.PoolsPanel.SaveMergedButton.Enabled && window.PoolsPanel.SaveZipButton.Enabled, "save_actions_ready");
                    Check(window.PoolsPanel.ResultText.Text.Contains("1 character(s)", StringComparison.Ordinal) && !window.PoolsPanel.FeedbackText.Text.Contains(CompanionTests.Secret, StringComparison.Ordinal), "counts_and_redaction");
                    if (Environment.GetEnvironmentVariable("TNB_POOL_UI_TEST_PREVIEW") is { Length: > 0 } preview)
                    {
                        window.PerformLayout(); window.PoolsPanel.PerformLayout(); Application.DoEvents();
                        using var bitmap = new Bitmap(window.Width, window.Height);
                        window.DrawToBitmap(bitmap, new Rectangle(Point.Empty, window.Size));
                        bitmap.Save(preview, System.Drawing.Imaging.ImageFormat.Png);
                    }
                    handler.Status = HttpStatusCode.NotFound;
                    await window.PoolsPanel.Download();
                    Check(!window.PoolsPanel.SaveZipButton.Enabled && !window.PoolsPanel.SaveMergedButton.Enabled && window.PoolsPanel.FeedbackText.Text.Contains("endpoint", StringComparison.Ordinal), "failed_download_clears_stale_result");
                    handler.Status = HttpStatusCode.OK;
                    byte[] native = CharacterPoolTests.Fixture();
                    handler.Body = CharacterPoolTests.Zip(("appearance-manager.bin", CharacterPoolTests.WithExtras(native,
                        (CharacterPoolCodec.Read(native).Characters[0].ToArray(), 7, "PoweredArmor1"))));
                    await window.PoolsPanel.Download();
                    Check(window.PoolsPanel.SaveZipButton.Enabled && window.PoolsPanel.SaveMergedButton.Enabled, "appearance_manager_merge_ready");
                    handler.Body = CharacterPoolTests.Zip(("extended.bin", CharacterPoolTests.Fixture(extended: true)));
                    await window.PoolsPanel.Download();
                    Check(window.PoolsPanel.SaveZipButton.Enabled && !window.PoolsPanel.SaveMergedButton.Enabled && window.PoolsPanel.FeedbackText.Text.Contains("extended.bin", StringComparison.Ordinal), "unsupported_zip_only");
                    await window.RemoveCredential();
                    Check(!window.PoolsPanel.DownloadButton.Enabled && !window.PoolsPanel.SaveZipButton.Enabled, "credential_removal_clears_download");
                    window.CredentialInput.Text = CompanionTests.Secret; await window.SaveEnteredCredential();
                    handler.Release = new(TaskCreationOptions.RunContinuationsAsynchronously);
                    var closingOperation = window.PoolsPanel.Download();
                    Check(window.PoolsPanel.IsBusy, "closing_operation_started");
                    window.Close();
                    await closingOperation;
                    Check(stopping.IsCancellationRequested && !window.PoolsPanel.IsBusy, "close_cancel_settled");
                    result = 0;
                }
                catch (BridgeError error) { Console.Error.WriteLine("Pool UI self-test code: " + error.Code); }
                catch (Exception error) { Console.Error.WriteLine("Pool UI self-test failed: " + error.GetType().Name); }
                finally { window.Close(); }
            };
            deadline.Start(); Application.Run(window);
            Console.WriteLine(result == 0
                ? "PASS: Character Pools tab, explicit download, literal Journey title, busy controls, ZIP/merge availability, stale/unsupported results, credential removal and close-during-download cancellation."
                : "FAIL: Character Pools UI self-test.");
            return result;
        }
        catch (Exception error) { Console.Error.WriteLine("Pool UI self-test failed: " + error.GetType().Name); return 1; }
    }
}
