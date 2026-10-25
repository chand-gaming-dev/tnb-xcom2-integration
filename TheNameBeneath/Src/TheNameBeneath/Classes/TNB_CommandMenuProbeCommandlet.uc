// Offline menu policy/descriptor tests only. No live UI, sockets or history writes.
class TNB_CommandMenuProbeCommandlet extends Commandlet dependson(UIAvengerShortcuts);

event int Main(string Params)
{
    local array<UIAvengerShortcutSubMenuItem> Entries;
    local UIAvengerShortcutSubMenuItem Other, Item;
    local int Index;
    if (class'UIScreenListener_TNBCommand'.default.ScreenClass != class'UIAvengerHUD') return 1;
    Item = class'UIScreenListener_TNBCommand'.static.MenuEntry();
    if (Item.Id != 'TNB_CommandJourney' || Item.Message.Label != "The Name Beneath" || Item.Message.Description == "" || Item.Message.bDisabled || Item.Message.OnItemClicked == none) return 2;
    class'UIScreenListener_TNBCommand'.static.UpsertEntry(Entries);
    if (Entries.Length != 1 || Entries[0].Id != Item.Id) return 3;
    for (Index = 0; Index < 10; Index++) class'UIScreenListener_TNBCommand'.static.UpsertEntry(Entries);
    if (Entries.Length != 1) return 4;
    Entries.Length = 0;
    Other.Id = 'OtherModBefore'; Other.Message.Label = "Other mod before"; Other.Message.bDisabled = true;
    Entries.AddItem(Other);
    Item.Message.Label = "Stale label"; Item.Message.bDisabled = true; Entries.AddItem(Item);
    Other.Id = 'OtherModAfter'; Other.Message.Label = "Other mod after"; Entries.AddItem(Other);
    Entries.AddItem(Item); Entries.AddItem(Item);
    class'UIScreenListener_TNBCommand'.static.UpsertEntry(Entries);
    if (Entries.Length != 3 || Entries[0].Id != 'OtherModBefore' || Entries[2].Id != 'OtherModAfter') return 5;
    if (!Entries[0].Message.bDisabled || !Entries[2].Message.bDisabled || Entries[0].Message.Label != "Other mod before" || Entries[2].Message.Label != "Other mod after") return 6;
    if (Entries[1].Id != 'TNB_CommandJourney' || Entries[1].Message.Label != "The Name Beneath" || Entries[1].Message.bDisabled || Entries[1].Message.OnItemClicked == none) return 7;
    if (!class'UIScreenListener_TNBCommand'.static.AllowedTopScreen(true, false, false) ||
        !class'UIScreenListener_TNBCommand'.static.AllowedTopScreen(false, true, false) ||
        !class'UIScreenListener_TNBCommand'.static.AllowedTopScreen(false, false, true) ||
        class'UIScreenListener_TNBCommand'.static.AllowedTopScreen(false, false, false)) return 8;
    if (class'UIScreenListener_TNBCommand'.static.CanOpenFromCommand(none, none)) return 9;
    class'UIScreenListener_TNBCommand'.static.RegisterMenu(none);
    `log("TNB_COMMAND_MENU_PASS: Command descriptor/callback, idempotent registration, duplicate cleanup, other-mod preservation, allowed-screen policy and no-world guards. Native UI lifecycle/linking acceptance is separate.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
