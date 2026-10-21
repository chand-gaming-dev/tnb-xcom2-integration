// Pure snapshots and comparisons. History/delegate ownership lives only on the world's pump.
class TNB_SoldierConditionObserver extends TNB_EventTypes;

static function bool BecameActive(SoldierObservation Previous, SoldierObservation Current, name Condition)
{
    return Current.Negative.Find(Condition) != INDEX_NONE && Previous.Negative.Find(Condition) == INDEX_NONE;
}

static function bool WasCured(SoldierObservation Previous, SoldierObservation Current, name Condition)
{
    return Previous.Negative.Find(Condition) != INDEX_NONE && Current.Negative.Find(Condition) == INDEX_NONE &&
        Current.Cured.Find(Condition) != INDEX_NONE && Previous.Cured.Find(Condition) == INDEX_NONE;
}

static function bool Snapshot(XComGameState_Unit Unit, out SoldierObservation Result, optional XComGameState_TNBSoldierLink PendingLink)
{
    local XComGameState_TNBSoldierLink Link;
    local XComGameState_TNBCampaignLink Campaign;
    local SoldierObservation Empty;
    local int Index;
    Result = Empty;
    Link = PendingLink;
    if (Link == none) Link = class'XComGameState_TNBSoldierLink'.static.ForUnit(Unit);
    if (Link == none) return false;
    Campaign = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Campaign == none || Link.CampaignID != Campaign.CampaignID || Link.Snapshot.JourneyID != Campaign.Journey.JourneyID) return false;
    Result.UnitID = Unit.ObjectID;
    Result.InstanceID = Link.Snapshot.InstanceID;
    Result.LinkToken = Link.UnitToken;
    Result.Rank = Unit.GetRank();
    Result.bWounded = Unit.IsInjured();
    Result.bDead = Unit.IsDead();
    Result.Cured = Unit.CuredTraits;
    Result.Acquired = Unit.AcquiredTraits;
    for (Index = 0; Index < Unit.NegativeTraits.Length; Index++)
        if (Unit.AcquiredTraits.Find(Unit.NegativeTraits[Index].TraitName) != INDEX_NONE)
            Result.Negative.AddItem(Unit.NegativeTraits[Index].TraitName);
    Result.CapturedLocal = class'TNB_EventFactory'.static.CaptureClock();
    return true;
}

static function string Identity(SoldierObservation Observation)
{
    // Intent tokens are NOT occurrence identity: re-linking after rewind must not mint more awards.
    return "unit:" $ Observation.UnitID $ ":" $ Observation.InstanceID;
}

// A history gap is not evidence of an injury, recovery, promotion or condition change.
// Preserve occurrence counters, but never claim continuity/causal refs across lost frames.
static function SoldierObservation RebaselineAfterGap(SoldierObservation Previous, SoldierObservation Current)
{
    local ConditionEpisode Episode;
    local name Condition;
    local int Index;
    if (Previous.InstanceID == Current.InstanceID && Previous.LinkToken == Current.LinkToken)
    {
        Current.WoundSequence = Previous.WoundSequence;
        Current.Episodes = Previous.Episodes;
        Current.Rank = Max(Previous.Rank, Current.Rank);
    }
    Current.WoundKey = "";
    for (Index = 0; Index < Current.Episodes.Length; Index++)
    {
        Current.Episodes[Index].Key = "";
        Current.Episodes[Index].bAcquisitionKnown = false;
        Current.Episodes[Index].bClosed = true;
    }
    foreach Current.Negative(Condition)
    {
        Index = Current.Episodes.Find('TemplateName', Condition);
        if (Index == INDEX_NONE)
        {
            Episode.TemplateName = Condition; Episode.Sequence = 0; Episode.Key = "";
            Episode.bAcquisitionKnown = false; Episode.bClosed = false;
            Current.Episodes.AddItem(Episode);
        }
        else Current.Episodes[Index].bClosed = false;
    }
    return Current;
}

static function JsonObject ConditionDetails(name TemplateName, string EpisodeKey, bool bBaseline)
{
    local JsonObject Details;
    local X2TraitTemplate Template;
    Details = new class'JsonObject';
    Details.SetStringValue("condition_kind", "negative_soldier_trait");
    Details.SetStringValue("condition_template", string(TemplateName));
    Details.SetStringValue("condition_episode", Left(EpisodeKey, 500));
    Details.SetBoolValue("acquisition_predates_observation", bBaseline);
    Template = X2TraitTemplate(class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager().FindEventListenerTemplate(TemplateName));
    Details.SetBoolValue("template_available", Template != none);
    if (Template != none) Details.SetStringValue("condition_label", class'TNB_EventFactory'.static.SafeText(Template.TraitFriendlyName));
    // Do not infer Infirmary treatment from removal alone or alter canonical Traits.
    Details.SetStringValue("recovery_source", "native_state_transition");
    return Details;
}

static function Observe(XComGameState Pending, XComGameState_TNBEventLedger Ledger, SoldierObservation Current, optional bool bBaseline, optional bool bPhysical, optional bool bOnlyPhysical, optional bool bFinalDeath, optional string MissionKey)
{
    local SoldierObservation Previous;
    local ConditionEpisode Episode;
    local array<string> Instances;
    local JsonObject Facts, Details, Replacements;
    local name Condition, Acquired;
    local X2TraitTemplate Template;
    local string Key, Base;
    local int Index, EpisodeIndex;
    if (Ledger == none || Current.InstanceID == "") return;
    Index = Ledger.Soldiers.Find('UnitID', Current.UnitID);
    if (Index == INDEX_NONE || Ledger.Soldiers[Index].InstanceID != Current.InstanceID || Ledger.Soldiers[Index].LinkToken != Current.LinkToken || bBaseline)
    {
        // The link itself, and old ranks/wounds/conditions, never become gameplay events.
        foreach Current.Negative(Condition)
        {
            Episode.TemplateName = Condition; Episode.Sequence = 0; Episode.Key = ""; Episode.bAcquisitionKnown = false; Episode.bClosed = false;
            Current.Episodes.AddItem(Episode);
        }
        if (Index == INDEX_NONE) Ledger.Soldiers.AddItem(Current);
        else Ledger.Soldiers[Index] = Current;
        return;
    }
    Previous = Ledger.Soldiers[Index];
    // Native rank-up capture may already be ahead of retained historical frames.
    // Ranks are promotion high-water marks for this link, not a respec/reset event stream.
    Current.Rank = Max(Current.Rank, Previous.Rank);
    if (!bPhysical)
    {
        Current.bWounded = Previous.bWounded;
        if (!bFinalDeath) Current.bDead = Previous.bDead;
    }
    if (bOnlyPhysical)
    {
        Current.Rank = Previous.Rank;
        Current.Negative = Previous.Negative;
        Current.Cured = Previous.Cured;
        Current.Acquired = Previous.Acquired;
    }
    Current.Episodes = Previous.Episodes;
    Current.WoundKey = Previous.WoundKey;
    Current.WoundSequence = Previous.WoundSequence;
    Base = Identity(Current);
    Instances.AddItem(Current.InstanceID);
    if (Current.Rank > Previous.Rank)
    {
        if (!class'TNB_PromotionCaptureService'.static.Queue(Pending, Ledger, Current, Previous.Rank)) Current.Rank = Previous.Rank;
    }
    if (Current.bWounded && !Previous.bWounded && !Current.bDead)
    {
        Current.WoundSequence++;
        Current.WoundKey = Base $ ":wound:" $ Current.WoundSequence;
        Facts = new class'JsonObject'; Facts.SetStringValue("injury_code", "xcom2_physical_wound");
        class'TNB_EventFactory'.static.Queue(Pending, Ledger, Current.WoundKey, "threadline.character.injured", "XCOM soldier wounded", Facts, Instances, MissionKey,, Current.CapturedLocal);
    }
    if (!Current.bWounded && Previous.bWounded && !Current.bDead)
    {
        Key = Base $ ":wound_recovery:" $ Current.WoundSequence;
        Facts = new class'JsonObject'; Facts.SetStringValue("recovery", "full");
        if (Previous.WoundKey != "" && Len(Previous.WoundKey) <= 128) Facts.SetStringValue("injury_ref", Previous.WoundKey);
        class'TNB_EventFactory'.static.Queue(Pending, Ledger, Key, "threadline.character.recovered", "XCOM soldier recovered from physical wounds", Facts, Instances, MissionKey,, Current.CapturedLocal);
    }
    if (Current.bDead && !Previous.bDead)
    {
        Facts = new class'JsonObject'; Facts.SetStringValue("local_finality", "dead");
        class'TNB_EventFactory'.static.Queue(Pending, Ledger, Base $ ":final_death", "threadline.character.died", "XCOM soldier died", Facts, Instances, MissionKey,, Current.CapturedLocal);
    }
    foreach Current.Negative(Condition)
    {
        if (!BecameActive(Previous, Current, Condition)) continue;
        EpisodeIndex = Current.Episodes.Find('TemplateName', Condition);
        if (EpisodeIndex == INDEX_NONE)
        {
            Episode.TemplateName = Condition; Episode.Sequence = 0; Episode.Key = ""; Episode.bAcquisitionKnown = false; Episode.bClosed = true;
            Current.Episodes.AddItem(Episode); EpisodeIndex = Current.Episodes.Length - 1;
        }
        if (!Current.Episodes[EpisodeIndex].bClosed) continue; // Reappearing data without a confirmed cure is the same episode.
        Current.Episodes[EpisodeIndex].Sequence++;
        Current.Episodes[EpisodeIndex].bClosed = false;
        Key = Base $ ":condition:" $ Condition $ ":" $ Current.Episodes[EpisodeIndex].Sequence;
        Current.Episodes[EpisodeIndex].Key = Key;
        Current.Episodes[EpisodeIndex].bAcquisitionKnown = true;
        Facts = new class'JsonObject'; Facts.SetStringValue("injury_code", "xcom2_negative_trait");
        Details = ConditionDetails(Condition, Key, false);
        class'TNB_EventFactory'.static.Queue(Pending, Ledger, Key, "threadline.character.injured", "XCOM negative soldier condition acquired:" @ string(Condition), Facts, Instances,, Details, Current.CapturedLocal);
    }
    foreach Previous.Negative(Condition)
    {
        // An absent/disabled mod template or a changed pending list is not a cure.
        if (!WasCured(Previous, Current, Condition)) continue;
        EpisodeIndex = Current.Episodes.Find('TemplateName', Condition);
        if (EpisodeIndex == INDEX_NONE) continue;
        Episode = Current.Episodes[EpisodeIndex];
        Current.Episodes[EpisodeIndex].bClosed = true;
        Key = Base $ ":condition_cured:" $ Condition $ ":" $ Episode.Sequence;
        Facts = new class'JsonObject'; Facts.SetStringValue("recovery", "full");
        if (Episode.bAcquisitionKnown && Len(Episode.Key) <= 128) Facts.SetStringValue("injury_ref", Episode.Key);
        Details = ConditionDetails(Condition, Episode.Key, !Episode.bAcquisitionKnown);
        Replacements = new class'JsonObject';
        foreach Current.Acquired(Acquired)
        {
            if (Previous.Acquired.Find(Acquired) != INDEX_NONE) continue;
            Template = X2TraitTemplate(class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager().FindEventListenerTemplate(Acquired));
            if (Template != none && Template.bPositiveTrait && Replacements.ValueArray.Length < 50) Replacements.ValueArray.AddItem(string(Acquired));
        }
        if (Replacements.ValueArray.Length > 0) Details.SetObject("observed_positive_local_traits", Replacements);
        class'TNB_EventFactory'.static.Queue(Pending, Ledger, Key, "threadline.character.recovered", "XCOM negative soldier condition cured:" @ string(Condition), Facts, Instances,, Details, Current.CapturedLocal);
    }
    Ledger.Soldiers[Index] = Current;
}
