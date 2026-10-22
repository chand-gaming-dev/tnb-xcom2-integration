using System.Net;

namespace TheNameBeneath.Companion;

internal static class CompanionWindowTests
{
    private static void Check(bool condition) { if (!condition) throw new InvalidOperationException("UI assertion failed"); }

    internal static int Run()
    {
        string data = Path.Combine(Path.GetTempPath(), "TNB-UI-Tests-" + Guid.NewGuid().ToString("N"));
        int result = 1;
        try
        {
            var config = new Configuration(new Uri("https://example.invalid/"), 27129, data, null, null);
            var vault = new CompanionTests.MemoryVault();
            var handler = new CompanionTests.FakeHandler();
            using var api = new JourneyApi(config, handler);
            var service = new ConnectionService(config, vault, api);
            using var cancel = new CancellationTokenSource();
            var ready = new TaskCompletionSource<int>(TaskCreationOptions.RunContinuationsAsynchronously);
            var server = Task.Run(() => new LoopbackServer(service, 0).Run(cancel.Token, port => ready.TrySetResult(port)));
            int port = ready.Task.GetAwaiter().GetResult();
            using var window = new CompanionWindow(config, service, cancel) { ShowInTaskbar = false, Opacity = 0 };
            window.ObserveListener(server);
            using var deadline = new System.Windows.Forms.Timer { Interval = 30000 };
            deadline.Tick += (_, _) => { result = 1; window.Close(); };
            window.Shown += async (_, _) =>
            {
                try
                {
                    CompanionIconTests.CheckWindowAndExecutable(window);
                    await CheckMinimizeRestoreLayout(window);
                    CheckHeaderLayout(window);
                    Check(window.Text == "The Name Beneath - XCom 2 Companion " + Program.Version);
                    Check(window.ClosingHelpLabel.Text.Contains("XCOM continues running", StringComparison.Ordinal));
                    Check(window.ClosingHelpLabel.Text.Contains("Saved credentials, links and bonuses are retained", StringComparison.Ordinal));
                    Check(!window.FeedbackLabel.Text.Contains("stops the game", StringComparison.Ordinal));
                    Check(window.CredentialInput.UseSystemPasswordChar && window.CredentialInput.ShortcutsEnabled);
                    Check(!window.StoredIndicator.AutoCheck && !window.StoredIndicator.Checked);
                    window.CredentialInput.Text = "invalid";
                    await window.SaveEnteredCredential();
                    Check(window.CredentialInput.Text.Length == 0 && !window.StoredIndicator.Checked && handler.Method == null);
                    window.CredentialInput.Text = "  " + CompanionTests.Secret + "  ";
                    await window.SaveEnteredCredential();
                    Check(window.StoredIndicator.Checked && window.CredentialInput.Text.Length == 0);
                    Check(window.ConnectionLabel.Text.Contains("Connected", StringComparison.Ordinal));
                    Check(window.JourneyLabel.Text.Contains("Ren\u00e9", StringComparison.Ordinal) && window.JourneyMetadataLabel.Text.Contains(CompanionTests.JourneyId, StringComparison.Ordinal));
                    Check(window.JourneyLabel.Text.Contains("Ren\u00e9's Resistance & Resolve", StringComparison.Ordinal) && !window.JourneyLabel.UseMnemonic);
                    Check(window.JourneyLabel.Text.Contains("Game: XCOM 2", StringComparison.Ordinal) && window.JourneyLabel.MaximumSize.Width == 700);
                    Check(window.Tabs.TabPages.Count == 3 && window.Tabs.TabPages[1].Text == "Gameplay reporting");
                    await CheckMinimizeRestoreLayout(window);
                    if (Environment.GetEnvironmentVariable("TNB_UI_TEST_PREVIEW") is { Length: > 0 } linkedPreview)
                    {
                        using var bitmap = new Bitmap(window.Width, window.Height);
                        window.DrawToBitmap(bitmap, new Rectangle(Point.Empty, window.Size));
                        bitmap.Save(linkedPreview, System.Drawing.Imaging.ImageFormat.Png);
                    }
                    if (Environment.GetEnvironmentVariable("TNB_REPORT_UI_TEST_PREVIEW") is { Length: > 0 } reportPreview)
                    {
                        window.Tabs.SelectedIndex = 1; Application.DoEvents();
                        Check(window.AcceptButton == null);
                        using var bitmap = new Bitmap(window.Width, window.Height);
                        window.DrawToBitmap(bitmap, new Rectangle(Point.Empty, window.Size));
                        bitmap.Save(reportPreview, System.Drawing.Imaging.ImageFormat.Png);
                        window.Tabs.SelectedIndex = 0;
                    }
                    var gameStatus = await CompanionTests.Call(port, "{\"protocol\":2,\"request_id\":1,\"op\":\"status\"}\n");
                    Check(gameStatus["data"]?["credential_stored"]?.GetValue<bool>() == true);
                    Check(!gameStatus.ToJsonString().Contains(CompanionTests.Secret, StringComparison.Ordinal));
                    int shortHeight = window.JourneyLabel.Height;
                    handler.JourneyTitle = "<Long Journey> & " + new string('\u96ea', 143);
                    await window.RunAction(() => service.Test(cancel.Token), "Title refreshed");
                    Check(window.JourneyLabel.Text.Contains(handler.JourneyTitle, StringComparison.Ordinal) && window.JourneyLabel.Height > shortHeight);
                    Check(window.JourneyLabel.Width <= 700);
                    handler.JourneyTitle = null;
                    await window.RunAction(() => service.Test(cancel.Token), "Title refreshed");
                    handler.Status = HttpStatusCode.Unauthorized;
                    window.CredentialInput.Text = "tlj_" + new string('b', 64);
                    await window.SaveEnteredCredential();
                    Check(vault.Read(CompanionTests.JourneyId) == CompanionTests.Secret && window.StoredIndicator.Checked);
                    Check(window.CredentialInput.Text.Length == 0);
                    handler.Status = HttpStatusCode.OK;
                    handler.FailNetwork = true;
                    await window.RunAction(() => service.Test(cancel.Token), "Verified");
                    Check(window.StoredIndicator.Checked && window.ConnectionLabel.Text.Contains("Unable to verify", StringComparison.Ordinal));
                    Check(!window.FeedbackLabel.Text.Contains(CompanionTests.Secret, StringComparison.Ordinal));
                    Check(!CompanionMessages.Error(new Exception(CompanionTests.Secret)).Contains(CompanionTests.Secret, StringComparison.Ordinal));
                    handler.FailNetwork = false;
                    await window.RemoveCredential();
                    Check(!window.StoredIndicator.Checked && vault.Read(CompanionTests.JourneyId) == null);
                    gameStatus = await CompanionTests.Call(port, "{\"protocol\":2,\"request_id\":2,\"op\":\"status\"}\n");
                    Check(gameStatus["data"]?["credential_stored"]?.GetValue<bool>() == false);
                    Check(window.CredentialInput.Text.Length == 0);
                    result = 0;
                }
                catch (BridgeError error) { Console.Error.WriteLine("UI self-test code: " + error.Code); result = 1; }
                catch { result = 1; }
                finally { window.Close(); }
            };
            deadline.Start();
            Application.Run(window);
            Check(cancel.IsCancellationRequested);
            server.GetAwaiter().GetResult();
            Console.WriteLine(result == 0 ? "PASS: portal icon resource/window/executable, header sizing, minimize/restore for all tabs and normal/maximized windows, masked entry, validation, Journey confirmation, credential lifecycle, shared socket status and shutdown." : "FAIL: companion UI self-test.");
            return result;
        }
        catch { Console.Error.WriteLine("FAIL: companion UI self-test."); return 1; }
        finally
        {
            if (Path.GetFileName(data).StartsWith("TNB-UI-Tests-", StringComparison.Ordinal) && Directory.Exists(data)) Directory.Delete(data, true);
        }
    }

    private static async Task CheckMinimizeRestoreLayout(CompanionWindow window)
    {
        var shell = (TableLayoutPanel)window.Tabs.Parent!;
        var heading = shell.GetControlFromPosition(0, 0)!;
        Size originalSize = window.Size;
        int originalTab = window.Tabs.SelectedIndex;
        string journeyText = window.JourneyLabel.Text;
        bool stored = window.StoredIndicator.Checked;
        try
        {
            foreach (Size size in new[] { originalSize, window.MinimumSize })
                foreach (FormWindowState state in new[] { FormWindowState.Normal, FormWindowState.Maximized })
                    for (int tab = 0; tab < window.Tabs.TabPages.Count; tab++)
                    {
                        window.WindowState = FormWindowState.Normal;
                        window.Size = size;
                        window.WindowState = state;
                        window.Tabs.SelectedIndex = tab;
                        await Task.Delay(30);
                        int headerHeight = heading.Height;
                        Size titleConstraint = window.HeaderTitle.MaximumSize;
                        Size subtitleConstraint = window.HeaderSubtitle.MaximumSize;
                        window.WindowState = FormWindowState.Minimized;
                        await Task.Delay(30);
                        window.RefreshStatus(); // The normal reporting timer also runs while minimized.
                        Check(window.WindowState == FormWindowState.Minimized);
                        Check(window.HeaderTitle.MaximumSize == titleConstraint && window.HeaderSubtitle.MaximumSize == subtitleConstraint);
                        window.WindowState = state;
                        await Task.Delay(30); // Let native restore/layout messages run, without forcing a repair.
                        if (!window.Tabs.Visible || window.Tabs.Height < 120 || window.Tabs.Bottom > shell.ClientSize.Height || heading.Height != headerHeight)
                            throw new InvalidOperationException("Restoring the window hides the main tab content.");
                        Check(window.WindowState == state && window.Tabs.SelectedIndex == tab);
                        Check(window.Tabs.SelectedTab!.ClientRectangle.Height > 0);
                        Check(window.StoredIndicator.Checked == stored && window.JourneyLabel.Text == journeyText);
                    }
        }
        finally
        {
            window.WindowState = FormWindowState.Normal;
            window.Size = originalSize;
            window.Tabs.SelectedIndex = originalTab;
            await Task.Delay(30);
        }
    }

    private static void CheckHeaderLayout(CompanionWindow window)
    {
        Size originalSize = window.Size;
        Font originalFont = window.HeaderTitle.Font;
        using var largeFont = new Font(originalFont.FontFamily, originalFont.Size * 2, originalFont.Style);
        using var expectedIcon = CompanionBranding.LoadIcon(256, 256);
        using var expected = expectedIcon.ToBitmap();
        Check(window.HeaderLogo.Image is Bitmap actual && actual.Size == expected.Size);
        var artwork = (Bitmap)window.HeaderLogo.Image!;
        for (int y = 0; y < expected.Height; y++)
            for (int x = 0; x < expected.Width; x++) Check(expected.GetPixel(x, y) == artwork.GetPixel(x, y));
        try
        {
            foreach (Size size in new[] { originalSize, window.MinimumSize, new Size(1400, 950) })
                foreach (Font font in new[] { originalFont, largeFont })
                {
                    window.Size = size; window.HeaderTitle.Font = font;
                    window.PerformLayout(); Application.DoEvents();
                    Rectangle title = new(window.PointToClient(window.HeaderTitle.PointToScreen(Point.Empty)), window.HeaderTitle.Size);
                    Rectangle subtitle = new(window.PointToClient(window.HeaderSubtitle.PointToScreen(Point.Empty)), window.HeaderSubtitle.Size);
                    Rectangle logo = new(window.PointToClient(window.HeaderLogo.PointToScreen(Point.Empty)), window.HeaderLogo.Size);
                    Check(!title.IntersectsWith(subtitle) && !title.IntersectsWith(logo) && !subtitle.IntersectsWith(logo));
                    foreach (var label in new[] { window.HeaderTitle, window.HeaderSubtitle })
                    {
                        Check(label.Bottom <= label.Parent!.ClientSize.Height && label.Right <= label.Parent.ClientSize.Width);
                        Check(label.Height >= label.GetPreferredSize(new Size(label.Width, 0)).Height);
                    }
                    Check(subtitle.Bottom < window.Tabs.Top);
                }
        }
        finally { window.HeaderTitle.Font = originalFont; window.Size = originalSize; window.PerformLayout(); Application.DoEvents(); }
    }
}
