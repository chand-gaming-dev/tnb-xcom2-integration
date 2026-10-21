using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal sealed class CompanionWindow : Form
{
    private readonly ConnectionService connection;
    private readonly CancellationTokenSource stopping;
    private Icon? companionIcon;
    private Bitmap? headerArtwork;
    internal readonly PictureBox HeaderLogo = new() { Size = new Size(64, 64), SizeMode = PictureBoxSizeMode.Zoom, Margin = new Padding(0, 4, 16, 0), AccessibleName = "The Name Beneath logo", TabStop = false };
    internal readonly Label HeaderTitle = new() { Text = "THE NAME BENEATH", AutoSize = true, ForeColor = Color.White, Margin = new Padding(0, 0, 0, 4), UseMnemonic = false };
    internal readonly Label HeaderSubtitle = new() { Text = "XCOM 2  |  Journey connection, gameplay reports & character pools", AutoSize = true, ForeColor = Color.WhiteSmoke, Margin = Padding.Empty, UseMnemonic = false };
    internal readonly TextBox CredentialInput = new() { UseSystemPasswordChar = true, MaxLength = 1280, Dock = DockStyle.Fill, AccessibleName = "Journey credential", ShortcutsEnabled = true };
    internal readonly CheckBox StoredIndicator = new() { Text = "Credential stored in Windows Credential Manager", AutoSize = true, AutoCheck = false, TabStop = false };
    internal readonly Label ConnectionLabel = new() { AutoSize = true };
    internal readonly Label JourneyLabel = new() { AutoSize = true, MaximumSize = new Size(580, 0), UseMnemonic = false };
    internal readonly Label JourneyMetadataLabel = CompanionLayout.Text("");
    internal readonly Label FeedbackLabel = new() { AutoSize = true, MaximumSize = new Size(580, 0) };
    internal readonly Label ClosingHelpLabel = new() { Text = "XCOM continues running if you close this window; report transfer/delivery pauses. Saved credentials, links and bonuses are retained. Already handed-off reports and online history do not rewind with an XCOM save.", AutoSize = true, MaximumSize = new Size(580, 0), Margin = new Padding(0, 16, 0, 0) };
    private readonly Label listenerLabel = new() { AutoSize = true };
    private readonly Label endpointLabel = CompanionLayout.Text("");
    private readonly Label[] reportCounts = Enumerable.Range(0, 5).Select(_ => CompanionLayout.Text("0", 125)).ToArray();
    internal readonly Label ReportingLabel = new() { AutoSize = true, MaximumSize = new Size(580, 0) };
    private readonly Button retryEventsButton = new() { Text = "Retry eligible reports", AutoSize = true };
    private readonly Button saveButton = new() { Text = "Validate and save", AutoSize = true };
    private readonly Button testButton = new() { Text = "Test connection", AutoSize = true };
    private readonly Button removeButton = new() { Text = "Remove credential", AutoSize = true };
    private readonly System.Windows.Forms.Timer refresh = new() { Interval = 2000 };
    private bool busy;
    private bool closingAfterPoolOperation;
    internal readonly TabControl Tabs = new() { Dock = DockStyle.Fill };
    internal readonly CharacterPoolsPanel PoolsPanel;

    internal CompanionWindow(Configuration config, ConnectionService service, CancellationTokenSource cancellation)
    {
        connection = service;
        stopping = cancellation;
        Text = "The Name Beneath - XCom 2 Companion " + Program.Version;
        companionIcon = CompanionBranding.LoadIcon();
        Icon = companionIcon;
        ClientSize = new Size(850, 780);
        MinimumSize = new Size(780, 650);
        Font = new Font("Segoe UI", 10F);
        BackColor = Color.FromArgb(245, 247, 246);
        ForeColor = CompanionLayout.Ink;
        StartPosition = FormStartPosition.CenterScreen;
        AutoScaleMode = AutoScaleMode.Dpi;

        JourneyLabel.MaximumSize = new Size(700, 0);
        FeedbackLabel.MaximumSize = new Size(700, 0); FeedbackLabel.UseMnemonic = false;
        ReportingLabel.MaximumSize = new Size(700, 0); ReportingLabel.UseMnemonic = false;
        ClosingHelpLabel.MaximumSize = new Size(800, 0); ClosingHelpLabel.UseMnemonic = false;
        ClosingHelpLabel.Text = "XCOM continues running if you close the companion. Report transfer/delivery pauses. Saved credentials, links and bonuses are retained. Online history does not rewind when loading an older XCOM save.";
        var shell = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 4 };
        shell.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        shell.RowStyles.Add(new RowStyle(SizeType.AutoSize)); shell.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); shell.RowStyles.Add(new RowStyle(SizeType.AutoSize)); shell.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        // Text determines height; no fixed pixel Y offsets that can overlap at
        // another Windows DPI/font scale. Wrap when the available width shrinks.
        var heading = new TableLayoutPanel { AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink, Dock = DockStyle.Top,
            BackColor = CompanionLayout.Accent, Padding = new Padding(20, 16, 20, 16), Margin = Padding.Empty, ColumnCount = 2, RowCount = 1 };
        heading.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        heading.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        heading.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        using (var artworkIcon = CompanionBranding.LoadIcon(256, 256)) headerArtwork = artworkIcon.ToBitmap();
        HeaderLogo.Image = headerArtwork;
        HeaderTitle.Font = new Font(Font.FontFamily, 20F, FontStyle.Bold);
        var headerText = new TableLayoutPanel { AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink, Dock = DockStyle.Top,
            Margin = Padding.Empty, ColumnCount = 1, RowCount = 2 };
        headerText.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        headerText.RowStyles.Add(new RowStyle(SizeType.AutoSize)); headerText.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        headerText.Controls.Add(HeaderTitle, 0, 0); headerText.Controls.Add(HeaderSubtitle, 0, 1);
        headerText.SizeChanged += (_, _) =>
        {
            int width = Math.Max(1, headerText.ClientSize.Width);
            HeaderTitle.MaximumSize = new Size(width, 0); HeaderSubtitle.MaximumSize = new Size(width, 0);
        };
        heading.Controls.Add(HeaderLogo, 0, 0); heading.Controls.Add(headerText, 1, 0);
        shell.Controls.Add(heading, 0, 0); shell.Controls.Add(Tabs, 0, 1);
        FeedbackLabel.Padding = new Padding(16, 8, 16, 8); FeedbackLabel.Margin = Padding.Empty; FeedbackLabel.MaximumSize = new Size(800, 0); FeedbackLabel.BackColor = Color.White;
        shell.Controls.Add(FeedbackLabel, 0, 2);
        ClosingHelpLabel.Padding = new Padding(16, 6, 16, 12); ClosingHelpLabel.Margin = Padding.Empty; ClosingHelpLabel.Font = new Font(Font.FontFamily, 9F); ClosingHelpLabel.ForeColor = Color.DimGray;
        shell.Controls.Add(ClosingHelpLabel, 0, 3); Controls.Add(shell);
        var connectionTab = new TabPage("Journey");
        var reportingTab = new TabPage("Gameplay reporting");
        var poolsTab = new TabPage("Character Pools");
        Tabs.TabPages.AddRange([connectionTab, reportingTab, poolsTab]);
        var layout = CompanionLayout.Page(connectionTab);
        PoolsPanel = new CharacterPoolsPanel(service, cancellation.Token);
        PoolsPanel.BusyChanged += SetBusy;
        poolsTab.Controls.Add(PoolsPanel);
        ConnectionLabel.Font = new Font(Font, FontStyle.Bold);
        CompanionLayout.Add(layout, CompanionLayout.Section("Current Journey", ConnectionLabel, JourneyLabel, StoredIndicator));
        CompanionLayout.Add(layout, CompanionLayout.Section("Journey credential", CompanionLayout.Text("Paste the Journey credential from the portal. Stored securely in Windows."), CredentialInput,
            CompanionLayout.Buttons(saveButton, testButton, removeButton)));
        listenerLabel.Text = "Local listener: 127.0.0.1:" + config.Port + "  |  Protocol " + LoopbackServer.Protocol;
        CompanionLayout.Add(layout, CompanionLayout.Section("Connection details", JourneyMetadataLabel, CompanionLayout.Text("API: " + config.Api.GetLeftPart(UriPartial.Authority)), listenerLabel));
        var reports = CompanionLayout.Page(reportingTab);
        var metrics = new TableLayoutPanel { AutoSize = true, ColumnCount = 5, RowCount = 2, Dock = DockStyle.Top };
        string[] countNames = ["Queued", "Retrying", "Paused", "Held", "Accepted"];
        for (int i = 0; i < reportCounts.Length; i++)
        {
            metrics.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 20));
            reportCounts[i].Font = new Font(Font.FontFamily, 22F, FontStyle.Bold);
            metrics.Controls.Add(reportCounts[i], i, 0); metrics.Controls.Add(CompanionLayout.Text(countNames[i], 125), i, 1);
        }
        CompanionLayout.Add(reports, CompanionLayout.Section("Gameplay reports", CompanionLayout.Text("Scope: the active Journey, across all of its local campaigns."), metrics, ReportingLabel, CompanionLayout.Buttons(retryEventsButton)));
        CompanionLayout.Add(reports, CompanionLayout.Section("Delivery and history", CompanionLayout.Text("Queued reports are saved locally and delivered while the companion is running. Held reports need review; Retry does not rewrite their facts or IDs. Loading an older XCOM save does not remove reports already handed off.")));
        CompanionLayout.Add(reports, CompanionLayout.Section("Storage diagnostics", endpointLabel));
        FeedbackLabel.Text = "Keep the companion running for linking and online features. You can view saved bonuses in XCOM without it.";
        AcceptButton = saveButton;
        Tabs.SelectedIndexChanged += (_, _) => AcceptButton = Tabs.SelectedIndex == 0 ? saveButton : null;

        saveButton.Click += async (_, _) =>
        {
            if (StoredIndicator.Checked && MessageBox.Show(this,
                "Replace the active local credential? A credential for another Journey will switch the companion's active Journey. Existing campaign links and history will not be moved or deleted.",
                "Replace credential", MessageBoxButtons.OKCancel, MessageBoxIcon.Question) != DialogResult.OK) return;
            await SaveEnteredCredential();
        };
        testButton.Click += async (_, _) => await RunAction(() => connection.Test(stopping.Token), "Connection verified.");
        retryEventsButton.Click += (_, _) => { connection.RetryReporting(); RefreshStatus(); };
        removeButton.Click += async (_, _) =>
        {
            if (MessageBox.Show(this, "Remove only the active local credential? This does not revoke it on the service or delete permanent links and history.",
                "Remove local credential", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning) == DialogResult.OK)
                await RemoveCredential();
        };
        refresh.Tick += (_, _) => { if (!busy) RefreshStatus(); };
        Shown += (_, _) => { RefreshStatus(); refresh.Start(); };
        FormClosing += async (_, args) =>
        {
            refresh.Stop(); CredentialInput.Clear(); stopping.Cancel();
            if (PoolsPanel.IsBusy && !closingAfterPoolOperation)
            {
                args.Cancel = true;
                await PoolsPanel.CancelAndWait();
                closingAfterPoolOperation = true;
                Close();
            }
        };
        RefreshStatus();
    }

    internal Task SaveEnteredCredential()
    {
        // Never repopulate this field from the vault. Clear it before any asynchronous work.
        string entered = CredentialInput.Text.Trim();
        CredentialInput.Clear();
        return RunAction(() => connection.Import(entered, stopping.Token), "Credential validated and saved. Journey details are shown above.");
    }

    internal Task RemoveCredential()
    {
        CredentialInput.Clear();
        return RunAction(() => connection.Remove(stopping.Token), "Local credential removed. Journey history and permanent associations are unchanged.");
    }

    internal async Task RunAction(Func<Task<JsonObject>> operation, string success)
    {
        if (busy || stopping.IsCancellationRequested) return;
        SetBusy(true);
        FeedbackLabel.Text = "Checking...";
        try
        {
            // Service operations stay on workers, even when this window closes mid-request.
            await Task.Run(operation);
            if (!IsDisposed && !stopping.IsCancellationRequested) FeedbackLabel.Text = success;
        }
        catch (Exception error)
        {
            if (!IsDisposed && !stopping.IsCancellationRequested) FeedbackLabel.Text = CompanionMessages.Error(error);
        }
        finally
        {
            if (!IsDisposed && !stopping.IsCancellationRequested) { SetBusy(false); RefreshStatus(); }
        }
    }

    internal void RefreshStatus()
    {
        try
        {
            ApplyStatus(connection.Status());
            var reporting = connection.ReportingStatus();
            string[] countKeys = ["queued", "retrying", "paused", "held", "accepted"];
            for (int i = 0; i < reportCounts.Length; i++) reportCounts[i].Text = reporting[countKeys[i]]?.ToString() ?? "0";
            string stamp = reporting["last_accepted_at"]?.GetValue<string>() ?? "";
            ReportingLabel.Text = "Last accepted: " + (DateTimeOffset.TryParse(stamp, out var accepted) ? accepted.ToLocalTime().ToString("g") + " (local time)" : "none yet") + Environment.NewLine +
                (reporting["delivery_enabled"]?.GetValue<bool>() == true ? "Delivery enabled while the companion is running." : "Delivery paused: connect a Journey credential.");
            endpointLabel.Text = "All Journeys on this API endpoint: " + reporting["endpoint_damaged_files"] + " damaged file(s), " + reporting["endpoint_replay_conflicts"] + " replay conflict(s)." +
                (reporting["local_storage_error"]?.GetValue<string>() is { Length: > 0 } issue ? Environment.NewLine + issue : "");
            retryEventsButton.Enabled = !busy && StoredIndicator.Checked;
        }
        catch (Exception error)
        {
            StoredIndicator.Text = "Credential stored (status unavailable)";
            ConnectionLabel.Text = "Connection: status unavailable";
            FeedbackLabel.Text = CompanionMessages.Error(error);
        }
    }

    internal void ApplyStatus(JsonObject status)
    {
        StoredIndicator.Text = "Credential stored in Windows Credential Manager";
        StoredIndicator.Checked = status["credential_stored"]!.GetValue<bool>();
        ConnectionLabel.Text = "Connection: " + CompanionMessages.Connection(status["connection"]!.GetValue<string>());
        bool stored = StoredIndicator.Checked;
        JourneyLabel.Text = stored
            ? "Journey: " + JourneyProjection.DisplayTitle(status["journey_title"]?.GetValue<string>()) +
              Environment.NewLine + "Commander: " + JourneyProjection.SingleLine(status["commander_name"]!.GetValue<string>()) +
              Environment.NewLine + "Game: " + JourneyProjection.SingleLine(status["game_name"]?.GetValue<string>() ?? "") + " (" + status["journey_status"]!.GetValue<string>() + ")"
            : "No active stored credential. Enter one above to connect.";
        JourneyMetadataLabel.Text = stored ? "Journey ID: " + status["journey_id"]!.GetValue<string>() + Environment.NewLine + "Title last checked: " +
            (DateTimeOffset.TryParse(status["title_observed_at"]?.GetValue<string>(), out var observed) ? observed.ToLocalTime().ToString("g") + " (local time)" : "not yet refreshed") : "No Journey metadata cached.";
        testButton.Enabled = stored && !busy;
        removeButton.Enabled = stored && !busy;
        PoolsPanel.SetContext(status, busy);
    }

    private void SetBusy(bool value)
    {
        busy = value;
        retryEventsButton.Enabled = !value && StoredIndicator.Checked;
        saveButton.Enabled = !value;
        CredentialInput.Enabled = !value;
        testButton.Enabled = !value && StoredIndicator.Checked;
        removeButton.Enabled = !value && StoredIndicator.Checked;
        PoolsPanel.SetParentBusy(value);
    }

    internal void ObserveListener(Task listener)
    {
        // Await only after the UI message loop exists; continuations must stay on that thread.
        Shown += async (_, _) =>
        {
            try { await listener; }
            catch (Exception error)
            {
                if (!IsDisposed && !stopping.IsCancellationRequested)
                {
                    listenerLabel.Text = "Local game connection unavailable";
                    FeedbackLabel.Text = CompanionMessages.Error(error);
                }
            }
        };
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) refresh.Dispose();
        base.Dispose(disposing);
        if (disposing) { companionIcon?.Dispose(); companionIcon = null; headerArtwork?.Dispose(); headerArtwork = null; }
    }
}
