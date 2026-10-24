class UITNBCharacterPicker extends UISimpleCommodityScreen dependson(TNB_Types, UIDialogueBox);

struct PickerRow
{
    var name Action;
    var string CharacterID;
    var string RosterID;
    var string CharacterName;
    var bool bDisabled;
};

var UIArmory_MainMenu Armory;
var StateObjectReference UnitRef;
var TNB_LoopbackClient Request;
var TNB_Types.JourneyContext Journey;
var array<PickerRow> Rows;
var array<string> PreviousCursors;
var string Cursor, NextCursor;
var PickerRow SelectedCharacter;
var JsonObject RecoveryReceipt;
var bool bBusy, bAwaitingConfirmation;
var localized string LoadingText, SelectText, DetailsText, RetryText, LinkTitle, LinkWarning, LinkedTitle, EmptyText, NextText, PreviousText, ResumeText, FailedText, SaveReminder, MissingCompanionFeature, NotStartedText, LedgerConflictText;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
    super.InitScreen(InitController, InitMovie, InitName);
    if (!StillOpen()) { CloseScreen(); return; }
    m_strSubTitleTitle = class'TNB_Types'.static.EscapeUI(CurrentUnit().GetFullName());
    TitleHeader.SetText(m_strTitle, m_strSubTitleTitle);
    if (class'XComGameState_TNBSoldierLink'.static.ForUnit(CurrentUnit()) != none) ShowLinkReport();
    else if (!class'TNB_SoldierEffectService'.static.CanBeginLink(CurrentUnit())) Fail("saved_link_effect_ledger_conflict_no_stats_reapplied");
    else if (class'XComGameState_TNBCampaignLink'.static.Get() == none) Fail("connect_campaign_from_The_Name_Beneath_in_Mod_Config_Menu_first");
    else StartRequest("ping", PingComplete);
}

simulated function GetItems() {}

private function XComGameState_Unit CurrentUnit()
{
    return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
}

private function bool StillOpen()
{
    return !bIsRemoved && Armory != none && !Armory.bIsRemoved && Armory.UnitReference.ObjectID == UnitRef.ObjectID && class'TNB_SoldierEffectService'.static.Eligible(CurrentUnit());
}

private function JsonObject Arguments()
{
    local JsonObject Args;
    local XComGameState_TNBLinkIntent Intent;
    Args = new class'JsonObject';
    Args.SetStringValue("expected_journey_id", Journey.JourneyID);
    Args.SetStringValue("campaign_id", class'TNB_CampaignService'.static.CampaignID());
    Args.SetIntValue("unit_id", UnitRef.ObjectID);
    Intent = class'XComGameState_TNBLinkIntent'.static.ForUnit(CurrentUnit());
    if (Intent != none)
    {
        Args.SetStringValue("unit_token", Intent.UnitToken);
        Args.SetStringValue("unit_fingerprint", Intent.UnitFingerprint);
        Args.SetStringValue("character_id", Intent.CharacterID);
        Args.SetStringValue("roster_entry_id", Intent.RosterEntryID);
    }
    return Args;
}

private function StartRequest(string Operation, delegate<TNB_LoopbackClient.Reply> Callback, optional JsonObject Args)
{
    if (!StillOpen() || Request != none) return;
    bBusy = true;
    Rows.Length = 0; arrItems.Length = 0;
    AddRow('None', LoadingText, "", true);
    PopulateData();
    Request = Spawn(class'TNB_LoopbackClient');
    if (Request == none) { Fail("companion_client_unavailable"); return; }
    Request.BeginRequest(Operation, Callback, Args);
}

function PingComplete(JsonObject Data, string ErrorCode)
{
    local XComGameState_TNBCampaignLink Campaign;
    local JsonObject Args;
    Request = none;
    if (!StillOpen()) return;
    if (ErrorCode != "") { Fail(ErrorCode); return; }
    if (!class'TNB_PolicyTests'.static.Run()) { Fail("mapping_policy_self_test_failed"); return; }
    if (class'XComGameState_TNBSoldierLink'.static.ForUnit(CurrentUnit()) != none) { ShowLinkReport(); return; }
    if (!class'TNB_SoldierEffectService'.static.CanBeginLink(CurrentUnit())) { Fail("saved_link_effect_ledger_conflict_no_stats_reapplied"); return; }
    if (Data == none || Data.GetIntValue("armory_link_version") != 2) { Fail(MissingCompanionFeature); return; }
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    Args = new class'JsonObject';
    if (Campaign == none) { Fail("connect_campaign_from_The_Name_Beneath_in_Mod_Config_Menu_first"); return; }
    Args.SetStringValue("expected_journey_id", Campaign.Journey.JourneyID);
    StartRequest("journey_context", ContextComplete, Args);
}

function ContextComplete(JsonObject Data, string ErrorCode)
{
    local XComGameState_TNBCampaignLink Campaign;
    Request = none;
    if (!StillOpen()) return;
    if (ErrorCode != "") { Fail(ErrorCode); return; }
    if (!class'TNB_Types'.static.ReadJourney(Data, Journey)) { Fail("journey_response_invalid"); return; }
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Campaign != none)
    {
        if (Campaign.SchemaVersion != 1 || Campaign.Journey.JourneyID != Journey.JourneyID || Campaign.Journey.CommanderID != Journey.CommanderID || !Campaign.bOneTimeEffectsCommitted) { Fail("campaign_journey_mismatch"); return; }
        class'XComGameState_TNBJourneyLabel'.static.Observe(Data);
        StartRequest("activation_status", RecoveryComplete, Arguments());
        return;
    }
    Fail("connect_campaign_from_The_Name_Beneath_in_Mod_Config_Menu_first");
}

function RecoveryComplete(JsonObject Data, string ErrorCode)
{
    local XComGameState_TNBLinkIntent Intent;
    Request = none;
    if (!StillOpen()) return;
    if (ErrorCode != "") { Fail(ErrorCode); return; }
    if (Data == none || Data.GetStringValue("journey_id") != Journey.JourneyID || Data.GetIntValue("feature_version") != 2) { Fail("journey_mismatch"); return; }
    RecoveryReceipt = Data.GetObject("receipt");
    Intent = class'XComGameState_TNBLinkIntent'.static.ForUnit(CurrentUnit());
    // Only an intent in this loaded save can resume. A receipt from another save
    // timeline is history, not permission to restore a link or restrict the picker.
    if (Intent != none)
    {
        if (Journey.JourneyStatus != "started" && (RecoveryReceipt == none || RecoveryReceipt.GetObject("instance") == none)) { Fail(NotStartedText); return; }
        if (RecoveryReceipt != none && RecoveryReceipt.GetStringValue("unit_fingerprint") != class'TNB_SoldierEffectService'.static.Fingerprint(CurrentUnit())) { Fail("original_soldier_fingerprint_mismatch"); return; }
        if (RecoveryReceipt != none && Intent != none && (RecoveryReceipt.GetStringValue("unit_token") != Intent.UnitToken || RecoveryReceipt.GetStringValue("character_id") != Intent.CharacterID)) { Fail("receipt_mismatch"); return; }
        SelectedCharacter.Action = 'Resume';
        SelectedCharacter.CharacterID = Intent.CharacterID;
        SelectedCharacter.RosterID = Intent.RosterEntryID;
        SelectedCharacter.CharacterName = Intent.CharacterName;
        bBusy = false; Rows.Length = 0; arrItems.Length = 0;
        AddRow('Resume', ResumeText, class'TNB_Types'.static.EscapeUI(SelectedCharacter.CharacterName) $ "\n" $ LinkWarning);
        PopulateData();
        return;
    }
    if (RecoveryReceipt != none) { Fail("receipt_without_saved_intent"); return; }
    if (Journey.JourneyStatus != "started") { Fail(NotStartedText); return; }
    LoadPage();
}

private function LoadPage()
{
    local JsonObject Args;
    Args = Arguments(); Args.SetStringValue("cursor", Cursor);
    StartRequest("roster", RosterComplete, Args);
}

function RosterComplete(JsonObject Data, string ErrorCode)
{
    local JsonObject Items, Entry;
    local string CharacterName, ID, Description;
    local bool Reserved;
    Request = none;
    if (!StillOpen()) return;
    if (ErrorCode != "") { Fail(ErrorCode); return; }
    if (Data == none || Data.GetStringValue("journey_id") != Journey.JourneyID || Data.GetIntValue("feature_version") != 1) { Fail("journey_mismatch"); return; }
    Items = Data.GetObject("items");
    if (Items == none || Items.ObjectArray.Length > 5) { Fail("roster_response_invalid"); return; }
    bBusy = false; Rows.Length = 0; arrItems.Length = 0;
    foreach Items.ObjectArray(Entry)
    {
        if (Entry == none || Entry.GetStringValue("character_id") == "" || Entry.GetStringValue("roster_entry_id") == "") { Fail("roster_response_invalid"); return; }
        ID = Entry.GetStringValue("character_id"); CharacterName = Entry.GetStringValue("name");
        Reserved = class'TNB_SoldierEffectService'.static.IsReserved(ID, UnitRef.ObjectID);
        Description = "Character ID: " $ class'TNB_Types'.static.EscapeUI(ID) $ "\n" $ LinkWarning;
        AddRow('Character', class'TNB_Types'.static.EscapeUI(CharacterName) $ (Reserved ? " (already reserved)" : ""), Description, Reserved);
        Rows[Rows.Length - 1].CharacterID = ID; Rows[Rows.Length - 1].RosterID = Entry.GetStringValue("roster_entry_id"); Rows[Rows.Length - 1].CharacterName = CharacterName;
    }
    if (Items.ObjectArray.Length == 0) AddRow('None', EmptyText, "", true);
    Description = class'TNB_DejaVuService'.static.LinkPreviewFor(CurrentUnit());
    if (Description != "")
    {
        AddRow('Details', "Local linking bonus: Deja Vu", Description);
        arrItems[arrItems.Length - 1].Image = class'TNB_EffectPresentation'.static.AbilityImage('TNB_DejaVu');
    }
    NextCursor = Data.GetStringValue("next_cursor");
    if (NextCursor != "" && (NextCursor == Cursor || PreviousCursors.Find(NextCursor) != INDEX_NONE)) { Fail("roster_cursor_cycle"); return; }
    if (PreviousCursors.Length > 0) AddRow('Previous', PreviousText, "");
    if (NextCursor != "") AddRow('Next', NextText, "");
    PopulateData();
}

private function AddRow(name Action, string Caption, string Description, optional bool Disabled)
{
    local PickerRow Row;
    local Commodity Item;
    Row.Action = Action; Row.bDisabled = Disabled;
    Item.Title = Caption; Item.Desc = Description; Item.Image = class'UIUtilities_Image'.const.UnknownAbilityIcon;
    Rows.AddItem(Row); arrItems.AddItem(Item);
}

private function AddEffectRow(ResolvedEffect Effect, bool Committed)
{
    local string Caption, Description;
    Caption = class'TNB_Types'.static.EscapeUI(Effect.SourceName) $ ": " $ class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.Summary(Effect)) $ " [" $ class'TNB_EffectPresentation'.static.StatusBadge(Effect.Status, Committed) $ "]";
    Description = string(Effect.SourceKind) $ ": " $ class'TNB_Types'.static.EscapeUI(Effect.SourceName) $ "\n";
    Description $= class'TNB_Types'.static.EscapeUI(class'TNB_EffectPresentation'.static.Summary(Effect));
    Description $= "\nLink-time result: " $ class'TNB_EffectPresentation'.static.StatusText(Effect.Status, Committed);
    if (Effect.EffectKind == 'Ability') Description $= "\n\n" $ class'TNB_EffectPresentation'.static.AbilityDetails(Effect, CurrentUnit());
    if (Effect.Note != "") Description $= "\n" $ class'TNB_Types'.static.EscapeUI(Effect.Note);
    Description $= "\nDefinition: " $ class'TNB_Types'.static.EscapeUI(Effect.SourceID) $ " v" $ Effect.SourceVersion $ "\nMapping: " $ string(Effect.MappingKey);
    if (Committed && (Effect.EffectKind == 'Stat' || Effect.EffectKind == 'ResourceOnce' || Effect.EffectKind == 'AvatarOnce' || Effect.EffectKind == 'StaffOnce')) Description $= "\nActual applied delta: " $ ((Effect.AppliedMagnitude > 0) ? "+" : "") $ Effect.AppliedMagnitude;
    AddRow('Details', Caption, Description);
    if (Effect.EffectKind == 'Ability') arrItems[arrItems.Length - 1].Image = class'TNB_EffectPresentation'.static.AbilityImage(Effect.Target);
}

simulated function bool MeetsItemReqs(int ItemIndex)
{
    return !bBusy && ItemIndex >= 0 && ItemIndex < Rows.Length && !Rows[ItemIndex].bDisabled;
}
simulated function bool CanAffordItem(int ItemIndex) { return MeetsItemReqs(ItemIndex); }
simulated function string GetButtonString(int ItemIndex)
{
    if (ItemIndex >= 0 && ItemIndex < Rows.Length && Rows[ItemIndex].Action == 'Details') return DetailsText;
    return SelectText;
}

simulated function OnPurchaseClicked(UIList ContainerList, int ItemIndex)
{
    local TDialogueBoxData Dialog;
    local string LocalBonus;
    if (!StillOpen() || bAwaitingConfirmation || !CanAffordItem(ItemIndex)) return;
    iSelectedItem = ItemIndex;
    switch (Rows[ItemIndex].Action)
    {
        case 'Details': Message(arrItems[ItemIndex].Title, arrItems[ItemIndex].Desc); return;
        case 'Retry': StartRequest("ping", PingComplete); return;
        case 'Next': PreviousCursors.AddItem(Cursor); Cursor = NextCursor; LoadPage(); return;
        case 'Previous': Cursor = PreviousCursors[PreviousCursors.Length - 1]; PreviousCursors.Remove(PreviousCursors.Length - 1, 1); LoadPage(); return;
        case 'Character': SelectedCharacter = Rows[ItemIndex];
        case 'Resume':
            Dialog.strTitle = LinkTitle;
            Dialog.strText = class'TNB_Types'.static.EscapeUI(CurrentUnit().GetFullName()) $ " paired with " $ class'TNB_Types'.static.EscapeUI(SelectedCharacter.CharacterName) $ "\nCharacter ID: " $ class'TNB_Types'.static.EscapeUI(SelectedCharacter.CharacterID) $ "\n\n" $ LinkWarning;
            LocalBonus = class'TNB_DejaVuService'.static.LinkPreviewFor(CurrentUnit());
            if (LocalBonus != "") Dialog.strText $= "\n\n" $ LocalBonus;
            Dialog.fnCallback = LinkConfirmed;
            break;
        default: return;
    }
    Dialog.eType = eDialog_Alert;
    Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
    Dialog.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;
    bAwaitingConfirmation = true;
    Movie.Pres.UIRaiseDialog(Dialog);
}

function LinkConfirmed(name Action)
{
    local XComGameState_TNBLinkIntent Intent;
    local string RecoveryToken;
    bAwaitingConfirmation = false;
    if (Action != 'eUIAction_Accept' || !StillOpen()) return;
    if (Journey.JourneyStatus != "started" && (RecoveryReceipt == none || RecoveryReceipt.GetObject("instance") == none)) { Fail(NotStartedText); return; }
    if (RecoveryReceipt != none) RecoveryToken = RecoveryReceipt.GetStringValue("unit_token");
    Intent = class'TNB_SoldierEffectService'.static.Reserve(CurrentUnit(), SelectedCharacter.CharacterID, SelectedCharacter.RosterID, SelectedCharacter.CharacterName, RecoveryToken);
    if (Intent == none) { Fail("pairing_reservation_conflict"); return; }
    StartRequest("activate", ActivationComplete, Arguments());
}

function ActivationComplete(JsonObject Data, string ErrorCode)
{
    local TNB_Types.CharacterSnapshot Snapshot;
    local XComGameState_TNBLinkIntent Intent;
    local JsonObject Args;
    Request = none;
    if (!StillOpen()) return;
    if (ErrorCode != "") { Fail(ErrorCode); return; }
    if (!class'TNB_Types'.static.ReadSnapshot(Data, Snapshot)) { Fail("snapshot_response_invalid"); return; }
    Intent = class'XComGameState_TNBLinkIntent'.static.ForUnit(CurrentUnit());
    if (Intent == none) { Fail("link_intent_missing"); return; }
    if (!class'TNB_SoldierEffectService'.static.Commit(UnitRef.ObjectID, Intent.UnitToken, Snapshot, ErrorCode)) { Fail(ErrorCode); return; }
    Args = Arguments(); Args.SetStringValue("instance_id", Snapshot.InstanceID);
    StartRequest("activation_ack", Acknowledged, Args);
}

function Acknowledged(JsonObject Data, string ErrorCode)
{
    Request = none;
    if (!StillOpen()) return;
    CloseScreen();
    class'UITNBSoldierProfile'.static.Open(Armory, UnitRef, "Character linked. " $ SaveReminder $ ((ErrorCode != "") ? " Companion acknowledgement pending; the recovery receipt remains available." : ""));
}

private function ShowLinkReport()
{
    if (class'XComGameState_TNBSoldierLink'.static.ForUnit(CurrentUnit()) == none) { Fail("saved_link_missing"); return; }
    CloseScreen();
    class'UITNBSoldierProfile'.static.Open(Armory, UnitRef);
}

private function Fail(string ErrorCode)
{
    bBusy = false; bAwaitingConfirmation = false; Request = none;
    Rows.Length = 0; arrItems.Length = 0;
    AddRow('Retry', RetryText, FailedText $ class'TNB_Types'.static.EscapeUI(Repl(ErrorCode, "_", " ")) $ "\nAn interrupted activation can only resume the original pairing.");
    if (InStr(ErrorCode, "saved_link_effect_ledger_conflict") == 0) arrItems[0].Desc = LedgerConflictText;
    PopulateData();
    Message(m_strTitle, arrItems[0].Desc);
}

private function Message(string Title, string Body)
{
    local TDialogueBoxData Dialog;
    Dialog.eType = eDialog_Normal; Dialog.strTitle = Title; Dialog.strText = Body;
    Dialog.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;
    Movie.Pres.UIRaiseDialog(Dialog);
}

simulated function OnRemoved()
{
    if (Request != none) Request.CancelRequest();
    Request = none;
    super.OnRemoved();
}

defaultproperties
{
    InputState=eInputState_Consume
    bHideOnLoseFocus=false
    bConsumeMouseEvents=true
    bUseSimpleCard=true
}
