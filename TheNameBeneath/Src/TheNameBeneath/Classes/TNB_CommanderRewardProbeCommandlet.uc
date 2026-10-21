// Offline tests of production receipt/month/queue policy. No live campaign,
// API, credentials, random item grants or presentation world is required.
class TNB_CommanderRewardProbeCommandlet extends Commandlet dependson(TNB_Types, X2StrategyGameRulesetDataStructures);

event int Main(string Params)
{
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_TNBCommanderRewards Receipt, Reloaded;
    local TNB_Types.ResolvedEffect Effect;
    local DynamicPropertySet Popup;
    local string Text;
    local array<string> SourceNames;
    if (!class'TNB_PolicyTests'.static.Run()) return 31;
    Link = new class'XComGameState_TNBCampaignLink';
    Effect.EffectKind = 'SupplyDropItem'; Effect.Status = "active";
    Link.Effects.AddItem(Effect);
    if (class'TNB_CommanderBonusService'.static.ScroungerDue(Link.bOneTimeEffectsCommitted, Link.HasScrounger(), Link.ScroungerMonths, 1)) return 1;
    Link.bOneTimeEffectsCommitted = true;
    if (!class'TNB_CommanderBonusService'.static.ScroungerDue(Link.bOneTimeEffectsCommitted, Link.HasScrounger(), Link.ScroungerMonths, 1)) return 2;
    // No income/cache/collection argument: a zero-income month is eligible.
    if (class'TNB_CommanderBonusService'.static.IncomingMonth(0) != 1 || class'TNB_CommanderBonusService'.static.IncomingMonth(1) != 2) return 3;
    Link.ScroungerMonths.AddItem(1);
    if (class'TNB_CommanderBonusService'.static.ScroungerDue(true, true, Link.ScroungerMonths, 1) || !class'TNB_CommanderBonusService'.static.ScroungerDue(true, true, Link.ScroungerMonths, 2)) return 4;
    if (class'TNB_CommanderBonusService'.static.ScroungerDue(true, true, Link.ScroungerMonths, 0) || class'TNB_CommanderBonusService'.static.ScroungerDue(false, true, Link.ScroungerMonths, 2)) return 5;
    Link.Effects[0].Status = "missing_template";
    if (class'TNB_CommanderBonusService'.static.ScroungerDue(Link.bOneTimeEffectsCommitted, Link.HasScrounger(), Link.ScroungerMonths, 2)) return 6;
    Popup = class'TNB_CommanderRewardPresentation'.static.ScroungerPopup('AimUpgrade_Bsc', 2);
    if (Popup.PrimaryRoutingKey != 'TNB_ScroungerReward' || Popup.SecondaryRoutingKey != 'eAlert_ItemReceived' || Popup.bDisplayImmediate || Popup.bDisplayInTacticalIdle || !Popup.bDisplayOnGeoscapeIdle || !Popup.bDisplayOnAvengerSideViewIdle) return 7;
    if (class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(Popup, 'ItemTemplate') != 'AimUpgrade_Bsc' || class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(Popup, 'TNBMonth') != 2) return 8;
    if (class'TNB_CommanderRewardPresentation'.static.PopupReady(true, true, true) || class'TNB_CommanderRewardPresentation'.static.PopupReady(false, true, false) || class'TNB_CommanderRewardPresentation'.static.PopupReady(true, false, false) || !class'TNB_CommanderRewardPresentation'.static.PopupReady(true, true, false)) return 9;
    Effect.EffectKind = 'ResourcePercent'; Effect.Target = 'Supplies'; Effect.Magnitude = 500; Effect.Status = "active"; Effect.SourceName = "Resourceful";
    Link.Effects.Length = 0; Link.Effects.AddItem(Effect);
    SourceNames.AddItem("Resourceful");
    if (class'TNB_CommanderRewardPresentation'.static.ResourceSources(SourceNames) != "Resourceful") return 10;
    if (class'TNB_CommanderBonusService'.static.BonusAmount(86, 500) != 4 || class'TNB_CommanderBonusService'.static.BonusAmount(86, -500) != -4 || class'TNB_CommanderBonusService'.static.BonusAmount(1, 500) != 0) return 11;
    Receipt = new class'XComGameState_TNBCommanderRewards';
    if (!Receipt.RecordCollection("campaign", 42, 1, 1, "cache:1:1", 86, 4, 500, "Resourceful")) return 12;
    if (Receipt.BaseSupplies != 86 || Receipt.BonusSupplies != 4 || Receipt.TotalSupplies != 90) return 13;
    if (Receipt.RecordCollection("campaign", 42, 1, 1, "cache:1:1", 90, 4, 500, "Resourceful") || Receipt.TotalSupplies != 90) return 14;
    if (!Receipt.Matches("campaign", 42, 1, 1, false) || Receipt.Matches("other", 42, 1, 1, false) || Receipt.Matches("campaign", 43, 1, 1, false) || Receipt.Matches("campaign", 42, 2, 1, false) || Receipt.Matches("campaign", 42, 1, 2, false) || Receipt.Matches("campaign", 42, 1, 1, true)) return 15;
    Text = class'TNB_CommanderRewardPresentation'.static.ReceiptText(Receipt);
    `log("TNB_COMMANDER_RECEIPT_TEXT=" $ Text);
    if (InStr(Text, "Base supplies: 86") == INDEX_NONE || InStr(Text, "Resourceful (+5%): +4") == INDEX_NONE || InStr(Text, "Total received: 90") == INDEX_NONE) return 16;
    if (!Receipt.RecordCollection("campaign", 42, 1, 2, "cache:1:2", 14, 0, 500, "Resourceful") || Receipt.BaseSupplies != 100 || Receipt.BonusSupplies != 4 || Receipt.TotalSupplies != 104) return 17;
    // Preserve actual installment rounding, not 5% recomputed on the total.
    Reloaded = new class'XComGameState_TNBCommanderRewards';
    Reloaded.CampaignID = Receipt.CampaignID; Reloaded.CacheID = Receipt.CacheID;
    Reloaded.ResistanceMonth = Receipt.ResistanceMonth; Reloaded.CompletedScans = Receipt.CompletedScans;
    Reloaded.BaseSupplies = Receipt.BaseSupplies; Reloaded.BonusSupplies = Receipt.BonusSupplies; Reloaded.TotalSupplies = Receipt.TotalSupplies;
    Reloaded.BasisPoints = Receipt.BasisPoints; Reloaded.SourceLabel = Receipt.SourceLabel; Reloaded.CollectionKeys = Receipt.CollectionKeys;
    if (!Reloaded.Matches("campaign", 42, 1, 2, false) || Reloaded.RecordCollection("campaign", 42, 1, 2, "cache:1:2", 14, 0, 500, "Resourceful")) return 18;
    if (!Receipt.RecordCollection("campaign", 42, 2, 0, "cache:2:0", 86, -4, -500, "Extravagant") || Receipt.TotalSupplies != 82 || Receipt.CollectionKeys.Length != 1) return 19;
    if (InStr(class'TNB_CommanderRewardPresentation'.static.ReceiptText(Receipt), "Extravagant (-5%): -4") == INDEX_NONE || !Receipt.Matches("campaign", 42, 2, 0, false)) return 20;
    if (Receipt.RecordCollection("campaign", 42, 2, 1, "invalid", 0, 0, 500, "bad") || Receipt.RecordCollection("campaign", 42, 2, 1, "invalid", 86, -87, 500, "bad")) return 21;
    SourceNames[0] = "<Resourceful> & Test";
    if (class'TNB_CommanderRewardPresentation'.static.ResourceSources(SourceNames) != "&lt;Resourceful&gt; &amp; Test") return 22;
    if (class'TNB_CommanderRewardPresentation'.static.LocalizedText('ScroungerTitle') != "The Name Beneath - Scrounger" || InStr(class'TNB_CommanderRewardPresentation'.static.LocalizedText('ScroungerBody'), "added to your inventory") == INDEX_NONE) return 23;
    if (class'TNB_CommanderRewardPresentation'.static.ItemDisplayName("<font color='#FFFF00'>Stock</font>") != "Stock") return 24;
    if (class'TNB_CommanderRewardPresentation'.static.ItemDisplayName("<font color='#FFFF00'><b>Hair Trigger</b></font>") != "Hair Trigger") return 25;
    if (class'TNB_CommanderRewardPresentation'.static.ItemDisplayName("<font>Scope & Stock</font>") != "Scope &amp; Stock" || class'TNB_CommanderRewardPresentation'.static.ItemDisplayName("<font>" $ Chr(38634) $ "</font>") != Chr(38634)) return 26;
    if (class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(86, 86, 4) != 90 || class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(86, 86, -4) != 82) return 27;
    if (class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(90, 86, 4) != 90 || class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(82, 86, -4) != 82) return 28;
    if (class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(0, 86, 4) != 0 || class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(999, 86, 4) != 999 || class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(1, 1, 0) != 1 || class'TNB_CommanderRewardPresentation'.static.CollectionFlyoverAmount(86, 86, -86) != 0) return 29;
    if (InStr(class'TNB_CommanderRewardPresentation'.static.CollectionBody("Native body", 4), "recovered additional supplies") == INDEX_NONE || InStr(class'TNB_CommanderRewardPresentation'.static.CollectionBody("Native body", -4), "scattered, lost, or taken") == INDEX_NONE || class'TNB_CommanderRewardPresentation'.static.CollectionBody("Native body", 0) != "Native body") return 30;
    Text = class'TNB_CommanderRewardPresentation'.static.ScroungerRewardBody("Laser Sight");
    if (Text != "While rummaging around the Avenger, you uncover a forgotten Laser Sight. It has been added to your inventory.") return 32;
    if (InStr(Text, "{ItemName}") != INDEX_NONE || InStr(Caps(Text), "SUPPLY") != INDEX_NONE || InStr(Caps(Text), "ROLLOVER") != INDEX_NONE) return 33;
    Text = class'TNB_CommanderRewardPresentation'.static.ScroungerRewardBody(class'TNB_CommanderRewardPresentation'.static.ItemDisplayName("<font color='#FFFF00'>Scope & " $ Chr(38634) $ "</font>"));
    if (InStr(Text, "Scope &amp; " $ Chr(38634)) == INDEX_NONE || InStr(Text, "&amp;amp;") != INDEX_NONE || InStr(Text, "<font") != INDEX_NONE || InStr(Text, "&lt;font") != INDEX_NONE) return 34;
    `log("TNB_SCROUNGER_COPY_PASS: localized/fallback in-character body substitutes the actual safe item name once, preserves Unicode/escaping, and omits supply collection and rollover mechanics.");
    `log("TNB_SUPPLY_DISPLAY_PASS: Stock/Hair Trigger native tag removal, safe escaping/Unicode, exact positive/negative/zero/partial flyover totals, idempotent correction, instant/custom display preservation and sign-specific flavor text.");
    `log("TNB_COMMANDER_REWARDS_PASS: monthly eligibility including zero income; legacy month numbering/dedup; queued non-immediate item popup and monthly-report deferral; receipt exact/negative/zero/partial rounding, duplicate/reload identity, stale receipt rejection, instant collection, escaping and localized copy.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
