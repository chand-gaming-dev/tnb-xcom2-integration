namespace ThreadlineCompanion;

// Standard accessible Windows controls, shared spacing and a restrained light palette.
internal static class CompanionLayout
{
    internal static readonly Color Ink = Color.FromArgb(34, 53, 48);
    internal static readonly Color Accent = Color.FromArgb(34, 76, 64);
    internal static TableLayoutPanel Page(Control owner)
    {
        var host = new Panel { Dock = DockStyle.Fill, AutoScroll = true, BackColor = Color.FromArgb(245, 247, 246) };
        var page = new TableLayoutPanel { Dock = DockStyle.Top, AutoSize = true, Padding = new Padding(20), ColumnCount = 1 };
        page.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        host.Controls.Add(page); owner.Controls.Add(host);
        return page;
    }
    internal static void Add(TableLayoutPanel page, Control child)
    {
        child.Dock = DockStyle.Top;
        child.Margin = new Padding(0, 0, 0, 16);
        page.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        page.Controls.Add(child, 0, page.RowCount++);
    }
    internal static GroupBox Section(string title, params Control[] children)
    {
        var box = new GroupBox { Text = title, AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink, Padding = new Padding(16, 24, 16, 12), BackColor = Color.White, ForeColor = Ink };
        var content = new TableLayoutPanel { Dock = DockStyle.Top, AutoSize = true, ColumnCount = 1 };
        content.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        foreach (var child in children)
        {
            child.Dock = DockStyle.Top; child.Margin = new Padding(0, 0, 0, 10);
            content.RowStyles.Add(new RowStyle(SizeType.AutoSize)); content.Controls.Add(child, 0, content.RowCount++);
        }
        box.Controls.Add(content);
        return box;
    }
    internal static Label Text(string text, int width = 700) => new() { Text = text, AutoSize = true, MaximumSize = new Size(width, 0), UseMnemonic = false, ForeColor = Ink };
    internal static FlowLayoutPanel Buttons(params Button[] buttons)
    {
        var row = new FlowLayoutPanel { Dock = DockStyle.Top, AutoSize = true, WrapContents = true, Padding = Padding.Empty };
        foreach (var button in buttons)
        {
            button.AutoSize = true; button.Padding = new Padding(10, 5, 10, 5); button.Margin = new Padding(0, 0, 10, 6);
            row.Controls.Add(button);
        }
        return row;
    }
}
