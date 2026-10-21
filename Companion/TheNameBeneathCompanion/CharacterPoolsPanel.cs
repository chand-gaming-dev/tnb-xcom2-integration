using System.Text.Json.Nodes;

namespace TheNameBeneath.Companion;

internal sealed class CharacterPoolsPanel : UserControl
{
    private readonly ConnectionService connection;
    private readonly CancellationToken stopping;
    private CancellationTokenSource? operationCancel;
    private Task activeOperation = Task.CompletedTask;
    private string journey = "", journeyTitle = "";
    private string? journeyName;
    private CharacterPoolDownload? download;
    private bool parentBusy;
    internal bool IsBusy { get; private set; }
    internal event Action<bool>? BusyChanged;
    internal readonly Label JourneyText = TextLabel();
    internal readonly Label ResultText = TextLabel();
    internal readonly Label FeedbackText = TextLabel();
    internal readonly Button DownloadButton = new() { Text = "Download Journey files", AutoSize = true };
    internal readonly Button SaveZipButton = new() { Text = "Save original ZIP...", AutoSize = true };
    internal readonly Button SaveMergedButton = new() { Text = "Save merged pool...", AutoSize = true };
    private readonly Button cancelButton = new() { Text = "Cancel", AutoSize = true, Enabled = false };
    private readonly ProgressBar progress = new() { Style = ProgressBarStyle.Marquee, Visible = false, Dock = DockStyle.Top };

    internal CharacterPoolsPanel(ConnectionService service, CancellationToken cancel)
    {
        connection = service; stopping = cancel;
        Dock = DockStyle.Fill;
        var layout = CompanionLayout.Page(this);
        CompanionLayout.Add(layout, CompanionLayout.Section("Journey Character Pools", JourneyText,
            TextLabel("Download the authorized character files for this Journey. Downloading does not recruit soldiers, activate characters or link them to your campaign.")));
        var buttons = CompanionLayout.Buttons(DownloadButton, SaveZipButton, SaveMergedButton, cancelButton);
        CompanionLayout.Add(layout, CompanionLayout.Section("Download and save", buttons, progress, ResultText, FeedbackText));
        CompanionLayout.Add(layout, CompanionLayout.Section("Import into XCOM", TextLabel("1. Download the Journey files.\n2. Choose Save merged pool... and a new filename.\n3. In XCOM's main-menu Character Pool, choose Import Character."),
            TextLabel("Suggested folder: " + CharacterPoolFiles.ImportDirectory),
            TextLabel("Save As lets you choose another location. Existing files are never overwritten. Importing does not change existing campaign soldiers.")));
        CompanionLayout.Add(layout, CompanionLayout.Section("What is preserved", TextLabel("Character records and Appearance Manager's saved armor appearances/loadouts are retained. Missing cosmetic mods do not block merging; matching cosmetics are needed for the intended in-game appearance. Only byte-identical records are deduplicated."),
            TextLabel("Conflicting metadata or unknown layouts are never silently stripped. Save the original ZIP if a merge is unavailable. Downloads remain in memory until the window closes or the Journey changes.")));
        DownloadButton.Click += async (_, _) => await Download();
        SaveZipButton.Click += async (_, _) => await ChooseSave(false);
        SaveMergedButton.Click += async (_, _) => await ChooseSave(true);
        cancelButton.Click += (_, _) => operationCancel?.Cancel();
        FeedbackText.Text = "No files downloaded. Nothing is downloaded or installed automatically.";
        Buttons();
    }

    private static Label TextLabel(string text = "") => CompanionLayout.Text(text);

    internal void SetContext(JsonObject status, bool ownerBusy)
    {
        parentBusy = ownerBusy;
        string current = status["credential_stored"]?.GetValue<bool>() == true ? status["journey_id"]?.GetValue<string>() ?? "" : "";
        if (current != journey)
        {
            download = null;
            ResultText.Text = "";
            FeedbackText.Text = current.Length == 0 ? "Connect a Journey on the Journey tab first." : "Ready to download this Journey's authorized files.";
        }
        journey = current;
        journeyName = status["journey_title"]?.GetValue<string>();
        journeyTitle = JourneyProjection.DisplayTitle(journeyName);
        JourneyText.Text = journey.Length == 0 ? "No active Journey credential." : "Journey: " + journeyTitle + Environment.NewLine + "Journey ID: " + journey;
        Buttons();
    }

    private void Buttons()
    {
        bool idle = !IsBusy && !parentBusy && !stopping.IsCancellationRequested;
        DownloadButton.Enabled = idle && journey.Length != 0;
        SaveZipButton.Enabled = idle && download != null;
        SaveMergedButton.Enabled = idle && download?.MergedPool != null;
        cancelButton.Enabled = IsBusy;
        progress.Visible = IsBusy;
    }

    internal void SetParentBusy(bool value) { parentBusy = value; Buttons(); }

    internal string SuggestedMergedFileName => MergedFileName(journeyName, journey);

    internal static string MergedFileName(string? title, string journey)
    {
        var invalid = Path.GetInvalidFileNameChars();
        string safe = string.Concat((title ?? "").Select(c => invalid.Contains(c) || char.IsControl(c) ? "-" : c.ToString()));
        safe = string.Join(" ", safe.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries)).Trim(' ', '.', '-');
        // Bound the suggested component without splitting a UTF-16 surrogate pair.
        if (safe.Length > 100)
        {
            safe = safe[..100];
            if (char.IsHighSurrogate(safe[^1])) safe = safe[..^1];
            safe = safe.TrimEnd(' ', '.', '-');
        }
        if (safe.Length == 0) safe = "Journey-" + journey[..Math.Min(journey.Length, 8)];
        return "TNB-" + safe + ".bin";
    }

    internal Task Download()
    {
        if (journey.Length == 0) return Task.CompletedTask;
        string expected = journey, title = journeyTitle;
        return Begin(async cancel =>
        {
            download = null; ResultText.Text = "";
            var result = await Task.Run(() => connection.DownloadCharacterPools(expected, "The Name Beneath - " + title, cancel), cancel);
            if (IsDisposed || stopping.IsCancellationRequested) return;
            if (connection.Journey != expected) throw new BridgeError("journey_mismatch");
            download = result;
            ResultText.Text = $"Verified {result.Files} attached file(s), {result.SourceBytes:N0} source bytes. File count is not a character count." +
                (result.MergedPool == null ? "" : Environment.NewLine + $"Merged pool ready: {result.Characters} character(s); {result.Duplicates} byte-identical duplicate record(s) removed.");
            FeedbackText.Text = result.MergeProblem ?? "Ready to save. The original ZIP is unchanged; the merged pool is a separate importable file. Game import still needs verification.";
        }, "Downloading and verifying the complete ZIP...");
    }

    private async Task ChooseSave(bool merged)
    {
        if (download == null || IsBusy || parentBusy) return;
        byte[]? content = merged ? download.MergedPool : download.OriginalZip;
        if (content == null) return;
        string extension = merged ? ".bin" : ".zip";
        using var dialog = new SaveFileDialog
        {
            Title = merged ? "Save merged Character Pool (new file only)" : "Save original Journey ZIP (new file only)",
            Filter = merged ? "XCOM Character Pool (*.bin)|*.bin" : "ZIP archive (*.zip)|*.zip",
            DefaultExt = extension[1..], AddExtension = true, OverwritePrompt = false, CheckPathExists = true,
            FileName = merged ? SuggestedMergedFileName : "TNB-" + journey[..Math.Min(journey.Length, 8)] + "-" + DateTime.Now.ToString("yyyyMMdd-HHmmss") + extension,
            InitialDirectory = merged && Directory.Exists(CharacterPoolFiles.ImportDirectory) ? CharacterPoolFiles.ImportDirectory : Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)
        };
        if (dialog.ShowDialog(this) != DialogResult.OK) return;
        string destination = dialog.FileName;
        await Begin(async cancel =>
        {
            await Task.Run(() => CharacterPoolFiles.SaveNew(destination, content, extension, cancel), cancel);
            if (!IsDisposed && !stopping.IsCancellationRequested) FeedbackText.Text = "Saved: " + destination + (merged ? Environment.NewLine + "Import it through XCOM's Character Pool menu. No campaign soldier was changed." : "");
        }, "Saving a new file...");
    }

    private Task Begin(Func<CancellationToken, Task> action, string message)
    {
        if (IsBusy || parentBusy || stopping.IsCancellationRequested) return Task.CompletedTask;
        activeOperation = Run(action, message);
        return activeOperation;
    }
    private async Task Run(Func<CancellationToken, Task> action, string message)
    {
        IsBusy = true;
        operationCancel = CancellationTokenSource.CreateLinkedTokenSource(stopping);
        BusyChanged?.Invoke(true); Buttons(); FeedbackText.Text = message;
        try { await action(operationCancel.Token); }
        catch (Exception error) { if (!IsDisposed && !stopping.IsCancellationRequested) FeedbackText.Text = CharacterPoolMessages.Error(error); }
        finally
        {
            operationCancel.Dispose(); operationCancel = null;
            IsBusy = false;
            if (!IsDisposed) { BusyChanged?.Invoke(false); Buttons(); }
        }
    }
    internal Task CancelAndWait() { operationCancel?.Cancel(); return activeOperation; }

    protected override void Dispose(bool disposing)
    {
        if (disposing) { operationCancel?.Cancel(); download = null; }
        base.Dispose(disposing);
    }
}
