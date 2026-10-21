using System.Reflection;

namespace TheNameBeneath.Companion;

internal static class CompanionBranding
{
    internal const string IconResource = "TheNameBeneath.Companion.Icon";

    internal static Icon LoadIcon(int width = 32, int height = 32)
    {
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(IconResource)
            ?? throw new InvalidOperationException("Companion icon resource missing");
        using var source = new Icon(stream, width, height);
        return (Icon)source.Clone();
    }
}
