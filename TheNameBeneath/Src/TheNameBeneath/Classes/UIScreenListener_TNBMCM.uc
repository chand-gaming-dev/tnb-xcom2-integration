class UIScreenListener_TNBMCM extends UIScreenListener;

var TNB_MCMController Controller;

event OnInit(UIScreen Screen)
{
    if (MCM_API(Screen) == none) return;
    if (Controller != none) Controller.Cleanup();
    Controller = new class'TNB_MCMController';
    Controller.ParentScreen = Screen;
    MCM_API(Screen).RegisterClientMod(1, 0, Controller.BuildPage);
}

event OnRemoved(UIScreen Screen)
{
    if (Controller != none && Controller.ParentScreen == Screen)
    {
        Controller.Cleanup();
        Controller = none;
    }
}

defaultproperties
{
    ScreenClass=none
}
