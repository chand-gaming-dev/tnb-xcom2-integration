// Field/policy and delegate-chain tests; not a running native campaign.
class TNB_RecruitProbeCommandlet extends Commandlet dependson(TNB_Types, TNB_MappingConfig);

var int ActivatedCalls;
var int DeactivatedCalls;
var bool bSawReactivate;
var int RefID;
var TNB_RecruitCostHook Hook;

function PreservedActivation(XComGameState Change, StateObjectReference InRef, optional bool bReactivate = false)
{
    ActivatedCalls++; RefID = InRef.ObjectID; bSawReactivate = bReactivate;
    // Nested preserved callbacks must not re-enter the outer reconciliation.
    Hook.Deactivate(Change, InRef);
}

function PreservedDeactivation(XComGameState Change, StateObjectReference InRef)
{
    DeactivatedCalls++; RefID = InRef.ObjectID;
}

event int Main(string Params)
{
    local XComGameState_TNBCampaignLink Link, OldLink, CombinedLink;
    local XComGameState_HeadquartersResistance Resistance;
    local TNB_Types.ResolvedEffect Effect;
    local TNB_MappingConfig.MappingRow Row;
    local StateObjectReference Ref;
    local int Index;
    local X2DarkEventTemplate Template;
    Link = new class'XComGameState_TNBCampaignLink';
    OldLink = new class'XComGameState_TNBCampaignLink';
    Resistance = new class'XComGameState_HeadquartersResistance';
    Link.SchemaVersion = 1; Link.bOneTimeEffectsCommitted = true;
    OldLink.SchemaVersion = 1; OldLink.bOneTimeEffectsCommitted = true;
    Effect.EffectKind = 'RecruitCostPercent'; Effect.Target = 'Supplies'; Effect.Magnitude = 2500; Effect.Status = "active";
    Link.Effects.AddItem(Effect);
    Resistance.RecruitScalar = 1.0;
    if (class'TNB_RecruitCostService'.static.RegisterFields(OldLink, Resistance) || class'TNB_RecruitCostService'.static.Eligible(OldLink)) return 1;
    Link.bOneTimeEffectsCommitted = false;
    if (class'TNB_RecruitCostService'.static.RegisterFields(Link, Resistance)) return 2;
    Link.bOneTimeEffectsCommitted = true;
    if (!class'TNB_RecruitCostService'.static.RegisterFields(Link, Resistance) || Abs(Resistance.RecruitScalar - 1.25) > 0.0001) return 3;
    if (class'TNB_RecruitCostService'.static.RegisterFields(Link, Resistance) || Abs(Resistance.RecruitScalar - 1.25) > 0.0001) return 4;
    // The native getter rounds the discounted base times this scalar, once.
    if (Round(25.0 * Resistance.RecruitScalar) != 31 || Round(10.0 * Resistance.RecruitScalar) != 13 || Round(0.0 * Resistance.RecruitScalar) != 0) return 5;
    for (Index = 0; Index < 3; Index++)
    {
        if (!class'TNB_RecruitCostService'.static.SuspendFields(Link, Resistance) || Abs(Resistance.RecruitScalar - 1.0) > 0.0001) return 6;
        Resistance.RecruitScalar = 2.0; // native Midnight Raids activation/reset
        class'TNB_RecruitCostService'.static.ResumeFields(Link, Resistance);
        if (Abs(Resistance.RecruitScalar - 2.5) > 0.0001) return 7;
        class'TNB_RecruitCostService'.static.SuspendFields(Link, Resistance);
        Resistance.RecruitScalar = 1.0; // native expiry reset
        class'TNB_RecruitCostService'.static.ResumeFields(Link, Resistance);
        if (Abs(Resistance.RecruitScalar - 1.25) > 0.0001) return 8;
    }
    // Associate while Midnight Raids (or another existing scalar) is already active.
    Link.bRecruitCostRegistered = false; Resistance.RecruitScalar = 2.0;
    if (!class'TNB_RecruitCostService'.static.RegisterFields(Link, Resistance) || Abs(Resistance.RecruitScalar - 2.5) > 0.0001) return 9;
    class'TNB_RecruitCostService'.static.SuspendFields(Link, Resistance);
    Resistance.RecruitScalar *= 0.5; // preserve a multiplicative callback too
    class'TNB_RecruitCostService'.static.ResumeFields(Link, Resistance);
    if (Abs(Resistance.RecruitScalar - 1.25) > 0.0001) return 10;
    Resistance.RecruitScalar = 3.0; // an unknown external overwrite is not divided
    class'TNB_RecruitCostService'.static.SuspendFields(Link, Resistance);
    if (Abs(Resistance.RecruitScalar - 3.0) > 0.0001) return 11;
    Resistance.RecruitScalar = 1.0; // known native callback then restores composition
    class'TNB_RecruitCostService'.static.ResumeFields(Link, Resistance);
    if (Abs(Resistance.RecruitScalar - 1.25) > 0.0001) return 12;
    if (class'TNB_RecruitCostService'.static.BeginCallback(none) || class'TNB_RecruitCostService'.static.Register(none, Link)) return 13;
    if (class'TNB_RecruitCostService'.static.SuspendFields(OldLink, Resistance)) return 14;
    class'TNB_RecruitCostService'.static.ResumeFields(OldLink, Resistance);
    if (Abs(Resistance.RecruitScalar - 1.25) > 0.0001) return 15;
    Row.Key = 'test'; Row.Context = 'Commander'; Row.SourceKind = 'Trait'; Row.MinVersion = 2; Row.MaxVersion = 2; Row.bEnabled = true;
    Row.EffectKind = 'RecruitCostPercent'; Row.Target = 'Supplies'; Row.Magnitude = 2500;
    if (!class'TNB_MappingResolver'.static.ValidRow(Row)) return 16;
    Row.Target = 'Intel';
    if (class'TNB_MappingResolver'.static.ValidRow(Row)) return 17;
    if (class'TNB_EffectPresentation'.static.EffectColor(Effect) != eUIState_Bad || class'TNB_EffectPresentation'.static.TimingBadge(Effect.EffectKind) != "ONGOING" || InStr(class'TNB_EffectPresentation'.static.CommanderDetails(Effect), "Free recruits stay free") == INDEX_NONE) return 18;
    Hook = new class'TNB_RecruitCostHook';
    Hook.OriginalActivated = PreservedActivation; Hook.OriginalDeactivated = PreservedDeactivation;
    Ref.ObjectID = 42;
    Hook.Activate(none, Ref, true);
    if (ActivatedCalls != 1 || DeactivatedCalls != 1 || !bSawReactivate || RefID != 42 || Hook.Depth != 0 || Hook.bSuspended) return 19;
    Hook.Deactivate(none, Ref);
    if (DeactivatedCalls != 2 || Hook.Depth != 0) return 20;
    Template = new class'X2DarkEventTemplate';
    Template.OnActivatedFn = PreservedActivation; Template.OnDeactivatedFn = PreservedDeactivation;
    class'TNB_RecruitCostService'.static.InstallOn(Template);
    if (!class'TNB_RecruitCostService'.static.ReadyFor(Template)) return 21;
    class'TNB_RecruitCostService'.static.InstallOn(Template);
    Template.OnActivatedFn(none, Ref, true);
    if (ActivatedCalls != 2 || DeactivatedCalls != 3) return 22;
    Template.OnActivatedFn = PreservedActivation;
    if (class'TNB_RecruitCostService'.static.ReadyFor(Template)) return 23;
    class'TNB_RecruitCostService'.static.InstallOn(Template);
    if (class'TNB_RecruitCostService'.static.ReadyFor(Template)) return 24;
    CombinedLink = new class'XComGameState_TNBCampaignLink';
    CombinedLink.SchemaVersion = 1; CombinedLink.bOneTimeEffectsCommitted = true;
    Effect.Status = "disabled"; CombinedLink.Effects.AddItem(Effect);
    Resistance.RecruitScalar = 1.0;
    if (class'TNB_RecruitCostService'.static.RegisterFields(CombinedLink, Resistance)) return 25;
    CombinedLink.Effects[0].Status = "active";
    Effect.Status = "active"; Effect.Magnitude = -2500; CombinedLink.Effects.AddItem(Effect);
    if (class'TNB_RecruitCostService'.static.RegisterFields(CombinedLink, Resistance) || Abs(Resistance.RecruitScalar - 1.0) > 0.0001) return 26;
    CombinedLink.Effects[1].Magnitude = -500;
    if (!class'TNB_RecruitCostService'.static.RegisterFields(CombinedLink, Resistance) || CombinedLink.RecruitCostBasisPoints != 2000 || Abs(Resistance.RecruitScalar - 1.2) > 0.0001) return 27;
    Row.Target = 'Supplies'; Row.Magnitude = -10000;
    if (class'TNB_MappingResolver'.static.ValidRow(Row)) return 28;
    Row.Magnitude = -9900;
    if (!class'TNB_MappingResolver'.static.ValidRow(Row)) return 29;
    `log("TNB_RECRUIT_CHECKS_PASSED: frozen registration guard, price/discount/free-cost arithmetic, repeated native resets, active-at-association and multiplicative callback composition, external overwrite boundary, old-link/no-state guards, presentation and preserved/nested delegate arguments. Native history, UI and payment acceptance remains required.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
