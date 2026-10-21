// Reload diagnostic: campaign setup is MCM-only. Do not create or retain a
// world actor on this long-lived listener, even when the campaign is unlinked.
// Keep the class so existing installations need no class/config removal.
class UIScreenListener_TNBAvenger extends UIScreenListener;

defaultproperties
{
    ScreenClass=class'UIAvengerHUD'
}
