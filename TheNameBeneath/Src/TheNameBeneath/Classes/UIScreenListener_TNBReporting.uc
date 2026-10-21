// Stateless bootstrap only; no popup and no retained Screen/Actor/World reference.
class UIScreenListener_TNBReporting extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    if (`HQGAME != none || `TACTICALRULES != none) class'TNB_EventPump'.static.Ensure();
}

defaultproperties
{
    ScreenClass=none
}
