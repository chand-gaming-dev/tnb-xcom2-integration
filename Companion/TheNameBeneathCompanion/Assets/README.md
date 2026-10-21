# Companion icon

PortalFavicon.svg is copied without modification from the private portal's
apps/portal/public/favicon.svg at the user's request. It is the portal's
green-and-gold favicon, not a newly designed variant.

Source SHA-256: 03A77C2199CF8D74EF5EE65BFA154EBA0738135A301C3D485CD32E013FB3F096.

Companion.ico contains PNG frames at 16, 32, 48, 64, 128 and 256 pixels, rendered from that vector source. The project uses it both as ApplicationIcon (Windows executable/Explorer) and as an embedded resource for the desktop window/taskbar icon.

Normal .NET builds use the checked-in ICO and need no Node, SVG renderer, loose
image file or portal connection. Optional regeneration uses a separate Node
tooling checkout with the sharp dependency installed:

```powershell
node .\.scripts\Build-CompanionIcon.mjs C:\tools\tnb-artwork
```

Run that command from this mod solution root. Regeneration overwrites only the generated Assets/Companion.ico; it does not modify the source portal assets. Hidden UI tests validate the six frame sizes and compare the rendered resource, window icon and executable-associated icon.
