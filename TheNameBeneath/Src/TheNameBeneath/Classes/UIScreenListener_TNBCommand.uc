// Stateless menu extension. Never retain a Screen, World, History or request here.
class UIScreenListener_TNBCommand extends UIScreenListener dependson(UIAvengerShortcuts);

var localized string MenuLabel, MenuHelp;

event OnInit(UIScreen Screen) { RegisterMenu(UIAvengerHUD(Screen)); }
event OnReceiveFocus(UIScreen Screen) { RegisterMenu(UIAvengerHUD(Screen)); }

static function UIAvengerShortcutSubMenuItem MenuEntry()
{
    local UIAvengerShortcutSubMenuItem Item;
    Item.Id = 'TNB_CommandJourney';
    Item.Message.Label = default.MenuLabel != "" ? default.MenuLabel : "The Name Beneath";
    Item.Message.Description = default.MenuHelp != "" ? default.MenuHelp : "View saved commander bonuses, or review and connect a Journey. Nothing is applied without confirmation.";
    Item.Message.Urgency = eUIAvengerShortcutMsgUrgency_Low;
    Item.Message.OnItemClicked = OpenFromCommand;
    return Item;
}

// Operates only on Highlander's UI menu descriptors. Other mods' entries/order
// are preserved; repeated init/focus and even stale duplicate IDs remain harmless.
static function UpsertEntry(out array<UIAvengerShortcutSubMenuItem> Entries)
{
    local UIAvengerShortcutSubMenuItem Item;
    local int Index, Found;
    Item = MenuEntry(); Found = INDEX_NONE;
    for (Index = 0; Index < Entries.Length; Index++)
    {
        if (Entries[Index].Id != Item.Id) continue;
        if (Found == INDEX_NONE) { Entries[Index] = Item; Found = Index; }
        else { Entries.Remove(Index, 1); Index--; }
    }
    if (Found == INDEX_NONE) Entries.AddItem(Item);
}

static function RegisterMenu(UIAvengerHUD HUD)
{
    local array<UIAvengerShortcutSubMenuItem> Entries;
    if (HUD == none || HUD.bIsRemoved || HUD.bDeleteMe || HUD.Shortcuts == none || HUD.Shortcuts.bDeleteMe) return;
    if (HUD.Shortcuts.ModSubMenus.Length <= eUIAvengerShortcutCat_CommandersQuarters) return;
    // UE3 cannot pass an array nested in a dynamic-array element by reference.
    Entries = HUD.Shortcuts.ModSubMenus[eUIAvengerShortcutCat_CommandersQuarters].SubMenuItems;
    UpsertEntry(Entries);
    HUD.Shortcuts.ModSubMenus[eUIAvengerShortcutCat_CommandersQuarters].SubMenuItems = Entries;
    HUD.Shortcuts.UpdateCategories();
}

static function bool AllowedTopScreen(bool IsHUD, bool IsGrid, bool IsFacility)
{
    return IsHUD || IsGrid || IsFacility;
}

static function bool CanOpenFromCommand(UIAvengerHUD HUD, UIScreen Current)
{
    local WorldInfo World;
    World = class'WorldInfo'.static.GetWorldInfo();
    if (World == none || HUD == none || HUD.bIsRemoved || HUD.bDeleteMe || Current == none || Current.bIsRemoved || Current.bDeleteMe) return false;
    if (`HQPRES == none || `HQGAME == none || HUD != `HQPRES.m_kAvengerHUD || HUD.WorldInfo != World || Current.WorldInfo != World) return false;
    if (HUD.Movie == none || HUD.Movie != `HQPRES.Get2DMovie() || Current.Movie != HUD.Movie || HUD.Movie.Stack.GetCurrentScreen() != Current) return false;
    if (!AllowedTopScreen(Current == HUD, UIFacilityGrid(Current) != none, UIFacility(Current) != none)) return false;
    if (class'TNB_ReportingSafety'.static.BlockReason(World, `XCOMHISTORY) != "") return false;
    return !`HQPRES.IsBusy() && !`HQPRES.UIIsShowingDialog() && class'UITNBCampaignJourney'.static.CanOpen(Current);
}

static function OpenFromCommand(optional StateObjectReference Facility)
{
    local UIAvengerHUD HUD;
    local UIScreen Current;
    // Resolve everything from the active presentation at click time, never a
    // previous save's delegate data. Existing Open handles offline saved reports
    // and the unlinked explicit preview/confirmation flow without repeating grants.
    if (class'WorldInfo'.static.GetWorldInfo() == none || `HQPRES == none) return;
    HUD = `HQPRES.m_kAvengerHUD;
    if (HUD == none || HUD.Movie == none) return;
    Current = HUD.Movie.Stack.GetCurrentScreen();
    if (CanOpenFromCommand(HUD, Current)) class'UITNBCampaignJourney'.static.Open(Current);
}

defaultproperties
{
    ScreenClass=class'UIAvengerHUD'
}
