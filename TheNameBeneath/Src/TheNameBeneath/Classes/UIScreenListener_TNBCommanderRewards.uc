// Read-only decoration of the game's existing supply collection alert.
class UIScreenListener_TNBCommanderRewards extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    class'TNB_CommanderRewardPresentation'.static.ShowSupplyReceipt(UIAlert(Screen));
}

defaultproperties
{
    ScreenClass=class'UIAlert'
}
