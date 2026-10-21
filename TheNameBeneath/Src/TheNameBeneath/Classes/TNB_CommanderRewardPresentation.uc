// Native saved popup queue and read-only receipt presentation. No actors are
// retained, no timer is created and no independent state is submitted here.
class TNB_CommanderRewardPresentation extends TNB_Types dependson(X2StrategyGameRulesetDataStructures);

var localized string ScroungerTitle, ScroungerBody, ReceiptLabel;
var localized string BaseSuppliesText, TotalReceivedText, ModifierText;
var localized string AdditionalSuppliesText, LostSuppliesText;

// Commandlet hosts and untranslated languages may not load this mod's .int.
// Keep fallbacks in code: UE3 forbids localized properties in defaultproperties.
static function string LocalizedText(name Key)
{
    switch (Key)
    {
        case 'ScroungerTitle': return default.ScroungerTitle != "" ? default.ScroungerTitle : "The Name Beneath - Scrounger";
        case 'ScroungerBody': return default.ScroungerBody != "" ? default.ScroungerBody : "While rummaging around the Avenger, you uncover a forgotten {ItemName}. It has been added to your inventory.";
        case 'ReceiptLabel': return default.ReceiptLabel != "" ? default.ReceiptLabel : "The Name Beneath - Supplies received";
        case 'BaseSuppliesText': return default.BaseSuppliesText != "" ? default.BaseSuppliesText : "Base supplies";
        case 'TotalReceivedText': return default.TotalReceivedText != "" ? default.TotalReceivedText : "Total received";
        case 'ModifierText': return default.ModifierText != "" ? default.ModifierText : "Commander modifier";
        case 'AdditionalSuppliesText': return default.AdditionalSuppliesText != "" ? default.AdditionalSuppliesText : "Your commander recovered additional supplies at the drop site.";
        case 'LostSuppliesText': return default.LostSuppliesText != "" ? default.LostSuppliesText : "Some supplies were scattered, lost, or taken before recovery.";
    }
    return "";
}

// Caller supplies the already-normalized/escaped native item label used by the
// alert title. Substitute once; do not escape again or expose native font tags.
static function string ScroungerRewardBody(string SafeItemName)
{
    return Repl(LocalizedText('ScroungerBody'), "{ItemName}", SafeItemName);
}

static function string ItemDisplayName(string NativeName)
{
    local int Index;
    local bool bInsideTag;
    local string Character, PlainName;
    // Native item templates may already return colored HTML. Strip that markup
    // before escaping the remaining name, rather than displaying escaped tags.
    for (Index = 0; Index < Min(Len(NativeName), 4096); Index++)
    {
        Character = Mid(NativeName, Index, 1);
        if (Character == "<") { bInsideTag = true; continue; }
        if (Character == ">" && bInsideTag) { bInsideTag = false; continue; }
        if (!bInsideTag) PlainName $= Character;
    }
    return class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.SingleLine(PlainName));
}

static function int CollectionFlyoverAmount(int NativeAmount, int Original, int Adjustment)
{
    // No flyover for instant collection; preserve unrelated mods' custom amounts.
    // Calling again with an already-adjusted amount must never add the bonus twice.
    if (Original <= 0 || Original > 10000000 || NativeAmount != Original || Adjustment < -Original || Adjustment > 100000000) return NativeAmount;
    return Original + Adjustment;
}

static function string CollectionBody(string NativeBody, int Adjustment)
{
    if (Adjustment > 0) return NativeBody $ "\n\n" $ LocalizedText('AdditionalSuppliesText');
    if (Adjustment < 0) return NativeBody $ "\n\n" $ LocalizedText('LostSuppliesText');
    return NativeBody;
}

static function string ResourceSources(array<string> Names)
{
    local string Label, SourceName;
    foreach Names(SourceName)
    {
        if (Label != "") Label $= " / ";
        Label $= class'TNB_Types'.static.EscapeUI(class'TNB_Types'.static.Compact(class'TNB_Types'.static.SingleLine(SourceName), 48));
        if (Len(Label) >= 160) break;
    }
    return Label == "" ? LocalizedText('ModifierText') : Label;
}

static function string SignedAmount(int Value)
{
    return Value > 0 ? "+" $ Value : string(Value);
}

static function string ReceiptText(XComGameState_TNBCommanderRewards Receipt)
{
    if (Receipt == none) return "";
    return LocalizedText('BaseSuppliesText') $ ": " $ Receipt.BaseSupplies $ "\n" $
        Receipt.SourceLabel $ " (" $ class'TNB_EffectPresentation'.static.Percentage(Receipt.BasisPoints) $ "): " $ SignedAmount(Receipt.BonusSupplies) $ "\n" $
        LocalizedText('TotalReceivedText') $ ": " $ Receipt.TotalSupplies;
}

static function DynamicPropertySet ScroungerPopup(name ItemTemplate, int Month)
{
    local DynamicPropertySet Properties;
    // A custom primary route lets us wait until the native monthly report is done.
    class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(Properties, 'TNB_ScroungerReward', 'eAlert_ItemReceived', none, false, true, true, false);
    class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(Properties, 'ItemTemplate', ItemTemplate);
    class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(Properties, 'TNBMonth', Month);
    class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(Properties, 'SoundToPlay', "Geoscape_ItemComplete");
    return Properties;
}

static function QueueScrounger(XComGameState Pending, name ItemTemplate, int Month)
{
    local DynamicPropertySet Properties;
    if (Pending == none || ItemTemplate == '' || Month <= 0) return;
    Properties = ScroungerPopup(ItemTemplate, Month);
    // ALWAYS supply the native award transaction. QueueDynamicPopup must not
    // allocate or submit its own change state from inside this event callback.
    class'XComPresentationLayerBase'.static.QueueDynamicPopup(Properties, Pending);
}

static function bool PopupReady(bool bHasPresentation, bool bHasResistance, bool bMonthlyReportPending)
{
    return bHasPresentation && bHasResistance && !bMonthlyReportPending;
}

static function bool DisplayQueuedPopup(DynamicPropertySet Properties)
{
    local XComGameState_HeadquartersResistance Resistance;
    local UITNBScroungerReward Alert;
    if (Properties.PrimaryRoutingKey != 'TNB_ScroungerReward') return false;
    if (class'TNB_ReportingSafety'.static.BlockReason(class'WorldInfo'.static.GetWorldInfo(), `XCOMHISTORY) != "") return false;
    Resistance = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));
    if (!PopupReady(`HQPRES != none, Resistance != none, Resistance == none || Resistance.bEndOfMonthNotify)) return false;
    // Native presentation has already checked side-view/geoscape idle. The
    // monthly report and other modal screens are never interrupted by this path.
    Alert = `HQPRES.Spawn(class'UITNBScroungerReward', `HQPRES);
    if (Alert == none) return false;
    Alert.DisplayPropertySet = Properties;
    Alert.eAlertName = 'eAlert_ItemReceived';
    `HQPRES.ScreenStack.Push(Alert);
    return true;
}

static function string ReturnToHQText(UIAlert Alert)
{
    local XComGameState_HeadquartersXCom HQ;
    local XComGameState_Haven Haven;
    local XGParamTag ParamTag;
    HQ = class'UIUtilities_Strategy'.static.GetXComHQ();
    if (HQ != none)
        foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Haven', Haven)
            if (Haven.Region == HQ.StartingRegion) break;
    if (Haven == none) return Alert.m_strAccept;
    // Same label expansion as native UIAlert.GetReturnToHQString (private).
    ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
    ParamTag.StrValue0 = Haven.GetDisplayName();
    return `XEXPAND.ExpandString(Alert.m_strPOIReturnToHQ);
}

static function ShowSupplyReceipt(UIAlert Alert)
{
    local XComGameState_TNBCommanderRewards Receipt;
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_ResourceCache Cache;
    local XComGameState_HeadquartersResistance Resistance;
    local bool bInstant;
    if (Alert == none || (Alert.eAlertName != 'eAlert_ResourceCacheComplete' && Alert.eAlertName != 'eAlert_InstantResourceCache') || Alert.LibraryPanel == none) return;
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    Receipt = class'XComGameState_TNBCommanderRewards'.static.Get();
    Cache = XComGameState_ResourceCache(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache', true));
    Resistance = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));
    if (Link == none || Receipt == none || Cache == none || Resistance == none) return;
    if (!Receipt.Matches(Link.CampaignID, Cache.ObjectID, Resistance.NumMonths, Cache.NumScansCompleted, Cache.bNeedsScan)) return;
    bInstant = Alert.eAlertName == 'eAlert_InstantResourceCache';
    // Update only the existing panel's data. Do not rebuild buttons, move the
    // camera, change callback/return behavior, spawn a popup or touch history.
    Alert.LibraryPanel.MC.BeginFunctionOp("UpdateData");
    Alert.LibraryPanel.MC.QueueString(bInstant ? Alert.m_strInstantResourceCacheTitle : Alert.m_strResourceCacheCompleteTitle);
    Alert.LibraryPanel.MC.QueueString(Cache.GetDisplayName());
    Alert.LibraryPanel.MC.QueueString(CollectionBody(bInstant ? Alert.m_strInstantResourceCacheBody : `XEXPAND.ExpandString(Alert.m_strResourceCacheCompleteBody), Receipt.BonusSupplies));
    Alert.LibraryPanel.MC.QueueString("");
    Alert.LibraryPanel.MC.QueueString(bInstant ? "" : LocalizedText('ReceiptLabel'));
    Alert.LibraryPanel.MC.QueueString(bInstant ? "" : ReceiptText(Receipt));
    Alert.LibraryPanel.MC.QueueString(Cache.GetUIButtonIcon());
    Alert.LibraryPanel.MC.QueueString(bInstant ? Alert.m_strPOIImage : Alert.m_strResourceCacheCompleteImage);
    Alert.LibraryPanel.MC.QueueString(bInstant ? Alert.m_strCarryOn : ReturnToHQText(Alert));
    Alert.LibraryPanel.MC.QueueString(bInstant ? "" : Alert.m_strIgnore);
    if (bInstant)
    {
        Alert.LibraryPanel.MC.QueueString(LocalizedText('ReceiptLabel'));
        Alert.LibraryPanel.MC.QueueString(ReceiptText(Receipt));
    }
    Alert.LibraryPanel.MC.EndOp();
}

