// Pure offline presentation tests. No campaign mutation, HTTP or credentials.
class TNB_PresentationProbeCommandlet extends Commandlet dependson(TNB_Types);

event int Main(string Params)
{
    local JsonObject Data;
    local TNB_Types.JourneyContext Journey;
    local TNB_Types.CharacterSnapshot Snapshot;
    local TNB_Types.ResolvedEffect Effect;
    local string LongTitle, UnicodeTitle;
    local string Body, Path;
    local array<string> Icons;
    local int Index;
    if (!class'TNB_EffectPresentation'.static.RunChecks()) return 1;
    if (class'TNB_EffectPresentation'.static.CurrentAbilityLabel("missing_template", true) != "Granted by saved link - currently installed") return 30;
    if (class'TNB_EffectPresentation'.static.CurrentAbilityLabel("already_present", true) != "Already owned - currently installed") return 31;
    if (InStr(class'TNB_EffectPresentation'.static.CurrentAbilityLabel("available", false), "Currently unavailable") != 0) return 32;
    if (class'TNB_Types'.static.EscapeUI("<Name> & End") != "&lt;Name&gt; &amp; End") return 2;
    if (class'TNB_Types'.static.SingleLine("Line" $ Chr(10) $ "Two") != "Line Two") return 3;
    for (Index = 0; Index < 160; Index++) LongTitle $= "a";
    if (!class'TNB_Types'.static.ValidTitle(LongTitle) || class'TNB_Types'.static.ValidTitle(LongTitle $ "a") || class'TNB_Types'.static.ValidTitle("")) return 4;
    for (Index = 0; Index < 160; Index++) UnicodeTitle $= Chr(55356) $ Chr(57100);
    if (!class'TNB_Types'.static.ValidTitle(UnicodeTitle) || class'TNB_Types'.static.ValidTitle(UnicodeTitle $ "a")) return 13;
    if (class'TNB_Types'.static.Compact("<Long & Name>", 5) != "<Long...") return 14;
    Data = class'JsonObject'.static.DecodeJson("{\"feature_version\":1,\"journey_id\":\"journey\",\"commander_id\":\"commander\",\"journey_title\":\"<Resistance> & Resolve\",\"traits\":[],\"skills\":[]}");
    if (!class'TNB_Types'.static.ReadJourney(Data, Journey) || Journey.JourneyTitle != "<Resistance> & Resolve") return 5;
    Data.SetStringValue("journey_title", "");
    if (class'TNB_Types'.static.ReadJourney(Data, Journey)) return 6;
    // Titles are absent from the frozen character projection and are not required.
    Data.SetStringValue("character_id", "character"); Data.SetStringValue("roster_entry_id", "roster");
    Data.SetStringValue("instance_id", "instance"); Data.SetStringValue("snapshot_id", "snapshot");
    Data.SetStringValue("authorization_decision_id", "authorization"); Data.SetIntValue("snapshot_version", 3);
    if (!class'TNB_Types'.static.ReadSnapshot(Data, Snapshot) || Snapshot.JourneyID != "journey") return 7;
    Effect.EffectKind = 'Stat'; Effect.Target = 'eStat_Will'; Effect.Status = "applied"; Effect.Magnitude = 10; Effect.AppliedMagnitude = 4;
    if (class'TNB_EffectPresentation'.static.CommittedSummary(Effect) != "+4 Will") return 8;
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Good) return 9;
    Effect.AppliedMagnitude = -3;
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Bad) return 10;
    Effect.Status = "missing_template";
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Warning) return 11;
    if (class'TNB_EffectPresentation'.static.StatImage('eStat_HP') != "img:///UILibrary_Common.implants_health") return 12;
    Effect.Status = "applied"; Effect.AppliedMagnitude = 4; Effect.SourceID = "trait.test";
    Body = class'TNB_EffectPresentation'.static.SoldierDetails(Effect, none);
    if (Len(Body) > 200 || InStr(Body, "Definition:") != INDEX_NONE || InStr(Body, "+4 Will") == INDEX_NONE) return 15;
    if (InStr(class'TNB_EffectPresentation'.static.MappingDetails(Effect, "r2"), "trait.test") == INDEX_NONE) return 16;
    Effect.EffectKind = 'ResourcePercent'; Effect.Status = "active"; Effect.Magnitude = -500;
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Bad || class'TNB_EffectPresentation'.static.TimingBadge(Effect.EffectKind) != "ONGOING") return 17;
    Effect.Magnitude = 500;
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Good) return 18;
    Effect.EffectKind = 'AvatarOnce'; Effect.Status = "applied"; Effect.AppliedMagnitude = 1;
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Bad || class'TNB_EffectPresentation'.static.TimingBadge(Effect.EffectKind) != "ONE-TIME") return 19;
    Effect.AppliedMagnitude = -1;
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Good) return 20;
    if (class'TNB_EffectPresentation'.static.ReadableObservedAt("2026-10-20T02:14:34.4223541+00:00") != "2026-10-20 02:14:34 UTC") return 21;
    Icons.AddItem(class'UIUtilities_Image'.const.UnknownAbilityIcon);
    Icons.AddItem("img:///UILibrary_XPACK_StrategyImages.Invx_Supplies");
    Icons.AddItem("img:///UILibrary_XPACK_StrategyImages.Invx_Intel");
    Icons.AddItem(class'UIUtilities_Image'.const.AlertIcon_Engineering);
    Icons.AddItem(class'UIUtilities_Image'.const.AlertIcon_Science);
    Icons.AddItem(class'UIUtilities_Image'.const.EventQueue_Alien);
    Icons.AddItem(class'UIUtilities_Image'.const.LootIcon_Loot);
    foreach Icons(Path)
    {
        if (DynamicLoadObject(Mid(Path, 7), class'Texture2D', true) == none) { `log("TNB_ICON_MISSING=" $ Path); return 22; }
        `log("TNB_ICON_VERIFIED=" $ Path);
    }
    if (class'TNB_EffectPresentation'.static.SafeImage("img:///NotInstalled.BadIcon") != class'UIUtilities_Image'.const.UnknownAbilityIcon) return 23;
    `log("TNB_COMMANDER_UX_PASS: compact details, mapping drilldown, reward timing/colors, readable UTC and verified non-placeholder textures.");
    `log("TNB_PRESENTATION_PASS: Journey titles, HTML escaping, title-less snapshots, actual applied stats, positive/negative/unavailable states and core icons.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
