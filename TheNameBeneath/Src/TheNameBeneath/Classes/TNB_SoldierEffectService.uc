class TNB_SoldierEffectService extends TNB_Types;

static function bool Eligible(XComGameState_Unit Unit)
{
    return Unit != none && Unit.IsSoldier() && !Unit.IsDead() && !Unit.bCaptured;
}

// This policy is deliberately independent of the companion's historical receipts.
// A loaded committed link is immutable; a pre-link save can begin a fresh attempt.
static function string CommitDecision(bool HasAnyLink, bool HasValidLink, bool AppliedMarker, string ExistingInstance, string RequestedInstance)
{
    if (HasAnyLink)
    {
        if (HasValidLink && RequestedInstance != "" && ExistingInstance == RequestedInstance) return "unchanged";
        return "blocked";
    }
    return AppliedMarker ? "blocked" : "apply";
}

static function bool HasAppliedMarker(XComGameState_Unit Unit)
{
    local UnitValue Value;
    return Unit != none && Unit.GetUnitValue('TNB_LinkEffectsApplied', Value) && Value.fValue != 0;
}

static function XComGameState_TNBSoldierLink AnySavedLink(XComGameState_Unit Unit)
{
    local XComGameState_TNBSoldierLink Link;
    if (Unit == none) return none;
    Link = XComGameState_TNBSoldierLink(Unit.FindComponentObject(class'XComGameState_TNBSoldierLink'));
    if (Link != none) return Link;
    // An orphaned/invalid record is not permission to grant the same stats again.
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBSoldierLink', Link)
        if (Link.UnitRef.ObjectID == Unit.ObjectID) return Link;
    return none;
}

static function bool CanBeginLink(XComGameState_Unit Unit)
{
    local XComGameState_TNBLinkIntent Intent;
    Intent = class'XComGameState_TNBLinkIntent'.static.ForUnit(Unit);
    return Eligible(Unit) && AnySavedLink(Unit) == none && !HasAppliedMarker(Unit) && (Intent == none || !Intent.bCommitted);
}

static function bool IsReserved(string CharacterID, int ExceptUnitID)
{
    local XComGameState_TNBLinkIntent Intent;
    local XComGameState_TNBCampaignLink Campaign;
    local int Index;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Campaign != none)
    {
        Index = Campaign.ReservedCharacterIDs.Find(CharacterID);
        if (Index != INDEX_NONE && (Index >= Campaign.ReservedUnitIDs.Length || Campaign.ReservedUnitIDs[Index] != ExceptUnitID)) return true;
    }
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBLinkIntent', Intent)
        if (Intent.CharacterID == CharacterID && Intent.UnitRef.ObjectID != ExceptUnitID) return true;
    return false;
}

static function string Fingerprint(XComGameState_Unit Unit)
{
    if (Unit == none) return "";
    return Unit.ObjectID $ ":" $ string(Unit.GetMyTemplateName()) $ ":" $ Unit.PoolTimestamp $ ":" $ Unit.m_RecruitDate.m_iYear $ ":" $ Unit.m_RecruitDate.m_iMonth $ ":" $ Unit.m_RecruitDate.m_iDay $ ":" $ string(Unit.m_RecruitDate.m_fTime);
}

static function XComGameState_TNBLinkIntent Reserve(XComGameState_Unit Unit, string CharacterID, string RosterID, string CharacterName, optional string RecoveryToken)
{
    local XComGameState Change;
    local XComGameState_TNBLinkIntent Intent;
    local XComGameState_TNBCampaignLink Campaign;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    if (!CanBeginLink(Unit) || Campaign == none || !Campaign.bOneTimeEffectsCommitted || IsReserved(CharacterID, Unit.ObjectID)) return none;
    Intent = class'XComGameState_TNBLinkIntent'.static.ForUnit(Unit);
    if (Intent != none)
    {
        if (Intent.SchemaVersion == 1 && Intent.CharacterID == CharacterID && Intent.RosterEntryID == RosterID && Intent.UnitFingerprint == Fingerprint(Unit)) return Intent;
        return none;
    }
    Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("The Name Beneath: reserve permanent pairing");
    Unit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
    Intent = XComGameState_TNBLinkIntent(Change.CreateNewStateObject(class'XComGameState_TNBLinkIntent'));
    Intent.SchemaVersion = 1; Intent.UnitRef = Unit.GetReference(); Intent.UnitToken = (RecoveryToken == "") ? `FXSLIVE.GetGUID() : RecoveryToken;
    Intent.UnitFingerprint = Fingerprint(Unit);
    if (Intent.UnitToken == "") { `XCOMHISTORY.CleanupPendingGameState(Change); return none; }
    Intent.CampaignID = Campaign.CampaignID; Intent.JourneyID = Campaign.Journey.JourneyID;
    Intent.CharacterID = CharacterID; Intent.RosterEntryID = RosterID; Intent.CharacterName = CharacterName;
    Campaign = XComGameState_TNBCampaignLink(Change.ModifyStateObject(class'XComGameState_TNBCampaignLink', Campaign.ObjectID));
    if (Campaign.ReservedCharacterIDs.Find(CharacterID) == INDEX_NONE)
    {
        Campaign.ReservedCharacterIDs.AddItem(CharacterID);
        Campaign.ReservedUnitIDs.AddItem(Unit.ObjectID);
    }
    Unit.AddComponentObject(Intent);
    `XCOMGAME.GameRuleset.SubmitGameState(Change);
    return class'XComGameState_TNBLinkIntent'.static.ForUnit(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID)));
}

static function bool Commit(int UnitID, string UnitToken, CharacterSnapshot Snapshot, out string ErrorCode)
{
    local XComGameState Change;
    local XComGameState_Unit Unit;
    local XComGameState_TNBLinkIntent Intent;
    local XComGameState_TNBSoldierLink Link, RawLink, OtherLink;
    local XComGameState_TNBCampaignLink Campaign;
    local array<TNB_Types.ResolvedEffect> Effects;
    local TNB_Types.ResolvedEffect Effect;
    local ECharStatType Stat;
    local int Index, Other, Total;
    local float OldCurrent, OldMaximum, NewBase;
    local array<name> AppliedStats, Abilities;
    local array<SoldierClassAbilityType> ExistingAbilities;
    local string Decision, ExistingInstance;

    Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID));
    Intent = class'XComGameState_TNBLinkIntent'.static.ForUnit(Unit);
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    ErrorCode = "link_state_changed";
    if (!Eligible(Unit) || Campaign == none) return false;
    RawLink = AnySavedLink(Unit);
    Link = class'XComGameState_TNBSoldierLink'.static.ForUnit(Unit);
    if (Link != none) ExistingInstance = Link.Snapshot.InstanceID;
    Decision = CommitDecision(RawLink != none, Link != none, HasAppliedMarker(Unit), ExistingInstance, Snapshot.InstanceID);
    if (Decision == "blocked") { ErrorCode = "saved_link_effect_ledger_conflict"; return false; }
    if (Decision == "unchanged")
    {
        if (Link.UnitToken != UnitToken || Link.CampaignID != Campaign.CampaignID || Link.Snapshot.CharacterID != Snapshot.CharacterID || Link.Snapshot.JourneyID != Snapshot.JourneyID || Link.Snapshot.CommanderID != Snapshot.CommanderID) return false;
        ErrorCode = "";
        return true; // no mapping resolution, stat changes, ability grants or state submission
    }
    if (Intent == none || Intent.bCommitted || Intent.SchemaVersion != 1 || Intent.UnitToken != UnitToken || Intent.UnitRef.ObjectID != UnitID || Intent.UnitFingerprint != Fingerprint(Unit)) return false;
    if (Campaign.Journey.JourneyID != Snapshot.JourneyID || Campaign.Journey.CommanderID != Snapshot.CommanderID || Intent.JourneyID != Snapshot.JourneyID || Intent.CharacterID != Snapshot.CharacterID || Intent.RosterEntryID != Snapshot.RosterEntryID) return false;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBSoldierLink', OtherLink)
        if (OtherLink.UnitRef.ObjectID == UnitID || OtherLink.Snapshot.InstanceID == Snapshot.InstanceID || OtherLink.Snapshot.CharacterID == Snapshot.CharacterID) { ErrorCode = "character_already_linked"; return false; }
    if (IsReserved(Snapshot.CharacterID, UnitID)) { ErrorCode = "character_already_reserved_in_loaded_save"; return false; }
    Effects = class'TNB_MappingResolver'.static.Resolve('Character', Snapshot.Traits, Snapshot.Skills);
    if (Effects.Length > 512) { ErrorCode = "too_many_effects"; return false; }
    ExistingAbilities = Unit.GetEarnedSoldierAbilities();
    Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("The Name Beneath: commit character link and frozen effects");
    Unit = XComGameState_Unit(Change.ModifyStateObject(class'XComGameState_Unit', UnitID));
    // Marker, detailed ledger, link and stat deltas commit in the SAME transaction.
    // This second saved guard survives a different mod losing our component reference.
    Unit.SetUnitFloatValue('TNB_LinkEffectsApplied', 1.0, eCleanup_Never);
    for (Index = 0; Index < Effects.Length; Index++)
    {
        if (Effects[Index].Status != "resolved") continue;
        Effect = Effects[Index];
        if (Effect.EffectKind == 'Stat')
        {
            if (AppliedStats.Find(Effect.Target) != INDEX_NONE) continue;
            AppliedStats.AddItem(Effect.Target);
            Total = 0;
            foreach Effects(Effect)
                if (Effect.Status == "resolved" && Effect.EffectKind == 'Stat' && Effect.Target == Effects[Index].Target) Total += Effect.Magnitude;
            class'TNB_MappingResolver'.static.StatType(Effects[Index].Target, Stat);
            NewBase = Unit.GetBaseStat(Stat) + Total;
            for (Other = 0; Other < Effects.Length; Other++)
                if (Effects[Other].Status == "resolved" && Effects[Other].EffectKind == 'Stat' && Effects[Other].Target == Effects[Index].Target)
                {
                    Effects[Other].Status = (NewBase < ((Stat == eStat_HP || Stat == eStat_Mobility || Stat == eStat_SightRadius) ? 1 : -10000)) ? "skipped" : "applied";
                    if (Effects[Other].Status == "applied") Effects[Other].AppliedMagnitude = Effects[Other].Magnitude;
                    else Effects[Other].Note = "Combined delta would create an invalid base stat.";
                }
            if (Effects[Index].Status == "applied")
            {
                OldCurrent = Unit.GetCurrentStat(Stat);
                OldMaximum = Unit.GetMaxStat(Stat);
                Unit.SetBaseMaxStat(Stat, NewBase);
                // Healthy soldiers stay healthy; existing HP damage is never healed by a link.
                if (Stat == eStat_HP) Unit.SetCurrentStat(Stat, (OldCurrent >= OldMaximum) ? Unit.GetMaxStat(Stat) : FMin(OldCurrent, Unit.GetMaxStat(Stat)));
                else Unit.SetCurrentStat(Stat, OldCurrent + Total);
            }
        }
        else if (Effect.EffectKind == 'Ability')
        {
            if (Abilities.Find(Effect.Target) != INDEX_NONE || ExistingAbilities.Find('AbilityName', Effect.Target) != INDEX_NONE || Unit.HasAbilityFromAnySource(Effect.Target)) Effects[Index].Status = "already_present";
            else if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Effect.Target) == none) Effects[Index].Status = "missing_template";
            else { Effects[Index].Status = "available"; Abilities.AddItem(Effect.Target); }
        }
        else if (Effect.EffectKind == 'CombatIntelligence')
        {
            if (Unit.ComInt >= eComInt_Savant) Effects[Index].Status = "already_at_cap";
            else { Unit.ComInt = ECombatIntelligence(int(Unit.ComInt) + 1); Effects[Index].Status = "applied"; Effects[Index].AppliedMagnitude = 1; }
        }
    }
    Link = XComGameState_TNBSoldierLink(Change.CreateNewStateObject(class'XComGameState_TNBSoldierLink'));
    Link.SchemaVersion = 1; Link.UnitRef = Unit.GetReference(); Link.UnitToken = UnitToken; Link.CampaignID = Campaign.CampaignID;
    Link.Snapshot = Snapshot; Link.Effects = Effects; Link.MappingRevision = class'TNB_MappingConfig'.default.MappingRevision;
    Link.bEffectsCommitted = true;
    Unit.AddComponentObject(Link);
    Intent = XComGameState_TNBLinkIntent(Change.ModifyStateObject(class'XComGameState_TNBLinkIntent', Intent.ObjectID));
    Intent.bCommitted = true;
    class'TNB_EventCaptureService'.static.LinkedBaseline(Change, Unit, Link);
    `XCOMGAME.GameRuleset.SubmitGameState(Change);
    ErrorCode = "local_commit_failed";
    Link = class'XComGameState_TNBSoldierLink'.static.ForUnit(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitID)));
    if (Link == none || Link.Snapshot.InstanceID != Snapshot.InstanceID) return false;
    ErrorCode = "";
    return true;
}

static function AddAbilities(out array<SoldierClassAbilityType> Earned, XComGameState_Unit Unit)
{
    local XComGameState_TNBSoldierLink Link;
    local TNB_Types.ResolvedEffect Effect;
    local SoldierClassAbilityType Ability;
    Link = class'XComGameState_TNBSoldierLink'.static.ForUnit(Unit);
    if (Link == none) return;
    foreach Link.Effects(Effect)
    {
        if (Effect.EffectKind != 'Ability' || (Effect.Status != "available" && Effect.Status != "missing_template" && Effect.Status != "already_present")) continue;
        if (Earned.Find('AbilityName', Effect.Target) != INDEX_NONE || class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(Effect.Target) == none) continue;
        Ability.AbilityName = Effect.Target; Ability.ApplyToWeaponSlot = Effect.WeaponSlot; Ability.UtilityCat = Effect.UtilityCategory;
        Earned.AddItem(Ability);
    }
}

static function string Report(XComGameState_TNBSoldierLink Link)
{
    local string Body;
    local TNB_Types.ResolvedEffect Effect, Other;
    local array<name> Targets;
    local int Total;
    Body = "Linked character: " $ class'TNB_Types'.static.EscapeUI(Link.Snapshot.CharacterName) $ "\nSnapshot: " $ class'TNB_Types'.static.EscapeUI(Link.Snapshot.SnapshotID) $ " (v" $ Link.Snapshot.SnapshotVersion $ ")\n";
    Body $= class'TNB_MappingResolver'.static.Report(Link.Effects, true);
    foreach Link.Effects(Effect)
        if (Effect.EffectKind == 'Stat' && Effect.Status == "applied" && Targets.Find(Effect.Target) == INDEX_NONE)
        {
            Targets.AddItem(Effect.Target); Total = 0;
            foreach Link.Effects(Other) if (Other.Target == Effect.Target && Other.EffectKind == 'Stat' && Other.Status == "applied") Total += Other.AppliedMagnitude;
            Body $= "\nNet " $ string(Effect.Target) $ ": " $ ((Total > 0) ? "+" : "") $ Total;
        }
    return Body $ "\n\nThese are the frozen link-time effects, not a live refresh. Save the campaign to retain the link.";
}
