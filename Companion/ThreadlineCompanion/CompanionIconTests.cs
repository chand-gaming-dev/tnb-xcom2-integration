using System.Reflection;

namespace ThreadlineCompanion;

internal static class CompanionIconTests
{
    internal static void CheckWindowAndExecutable(Form window)
    {
        using var data = Assembly.GetExecutingAssembly().GetManifestResourceStream(CompanionBranding.IconResource)
            ?? throw new BridgeError("icon_resource_missing");
        using var reader = new BinaryReader(data);
        if (reader.ReadUInt16() != 0 || reader.ReadUInt16() != 1 || reader.ReadUInt16() != 6)
            throw new BridgeError("icon_header_invalid");
        int[] expectedSizes = [16, 32, 48, 64, 128, 256];
        foreach (int size in expectedSizes)
        {
            byte width = reader.ReadByte(), height = reader.ReadByte();
            if ((width == 0 ? 256 : width) != size || width != height) throw new BridgeError("icon_frame_missing");
            reader.ReadBytes(14);
        }
        using var expectedIcon = CompanionBranding.LoadIcon();
        using var expected = expectedIcon.ToBitmap();
        using var displayed = (window.Icon ?? throw new BridgeError("icon_window_missing")).ToBitmap();
        SameOpaquePixels(expected, displayed);
        string executable = Environment.ProcessPath ?? throw new BridgeError("icon_executable_unavailable");
        if (!string.Equals(Path.GetFileNameWithoutExtension(executable), "dotnet", StringComparison.OrdinalIgnoreCase))
        {
            using var extracted = Icon.ExtractAssociatedIcon(executable) ?? throw new BridgeError("icon_executable_missing");
            using var shell = extracted.ToBitmap();
            // Windows shell icon dimensions follow desktop DPI, not necessarily the 32px form icon.
            using var shellExpectedIcon = CompanionBranding.LoadIcon(extracted.Width, extracted.Height);
            using var shellExpected = shellExpectedIcon.ToBitmap();
            SameOpaquePixels(shellExpected, shell);
        }
    }

    private static void SameOpaquePixels(Bitmap expected, Bitmap actual)
    {
        if (actual.Size != expected.Size) throw new BridgeError("icon_dimensions_differ");
        int compared = 0;
        for (int y = 0; y < expected.Height; y++)
            for (int x = 0; x < expected.Width; x++)
            {
                Color a = expected.GetPixel(x, y), b = actual.GetPixel(x, y);
                if (a.A != 255) continue; // Native icon extraction can normalize transparent border pixels.
                if (b.A != 255 || Math.Abs(a.R - b.R) > 2 || Math.Abs(a.G - b.G) > 2 || Math.Abs(a.B - b.B) > 2)
                    throw new BridgeError("icon_artwork_differs");
                compared++;
            }
        if (compared < expected.Width * expected.Height / 2) throw new BridgeError("icon_artwork_missing");
    }
}
