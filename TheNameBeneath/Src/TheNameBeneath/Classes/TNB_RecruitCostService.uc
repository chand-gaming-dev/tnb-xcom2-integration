class TNB_RecruitCostService extends Object;

static function Install()
{
    local X2DarkEventTemplate Template;
    Template = X2DarkEventTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('DarkEvent_MidnightRaids'));
    InstallOn(Template);
}

static function InstallOn(X2DarkEventTemplate Template)
{
    local TNB_RecruitCostHook Hook;
    if (Template == none || Template.OnActivatedFn == none || Template.OnDeactivatedFn == none) return;
    // Do not wrap our own previous delegate chain again if another mod replaces
    // only one callback later. Report unsupported registration rather than recurse.
    Hook = TNB_RecruitCostHook(FindObject(PathName(Template) $ ".TNB_RecruitCostHook", class'TNB_RecruitCostHook'));
    if (Hook != none) return;
    Hook = new(Template, "TNB_RecruitCostHook") class'TNB_RecruitCostHook';
    Hook.OriginalActivated = Template.OnActivatedFn;
    Hook.OriginalDeactivated = Template.OnDeactivatedFn;
    Hook.BoundActivated = Hook.Activate;
    Hook.BoundDeactivated = Hook.Deactivate;
    Template.OnActivatedFn = Hook.BoundActivated;
    Template.OnDeactivatedFn = Hook.BoundDeactivated;
    `log("TNB_RECRUIT hook installed: " $ PathName(Hook) $ " template=" $ PathName(Template),, 'TheNameBeneath');
}

static function bool Ready()
{
    return ReadyFor(X2DarkEventTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('DarkEvent_MidnightRaids')));
}

static function bool ReadyFor(X2DarkEventTemplate Template)
{
    local TNB_RecruitCostHook Hook;
    if (Template == none) return false;
    Hook = TNB_RecruitCostHook(FindObject(PathName(Template) $ ".TNB_RecruitCostHook", class'TNB_RecruitCostHook'));
    return Hook != none && Template.OnActivatedFn == Hook.BoundActivated && Template.OnDeactivatedFn == Hook.BoundDeactivated;
}

static function float Factor(int BasisPoints)
{
    return 1.0 + float(Clamp(BasisPoints, -9900, 100000)) / 10000.0;
}

static function bool Eligible(XComGameState_TNBCampaignLink Link)
{
    return Link != none && Link.SchemaVersion == 1 && Link.bOneTimeEffectsCommitted && Link.bRecruitCostRegistered && Link.RecruitCostBasisPoints != 0;
}

// Field-only helpers also exercised by offline probes. They never read history.
static function bool RegisterFields(XComGameState_TNBCampaignLink Link, XComGameState_HeadquartersResistance Resistance)
{
    local int BasisPoints;
    if (Link == none || Resistance == none || Link.SchemaVersion != 1 || !Link.bOneTimeEffectsCommitted || Link.bRecruitCostRegistered) return false;
    BasisPoints = class'TNB_StrategyMappingService'.static.ActiveTotal(Link.Effects, 'RecruitCostPercent', 'Supplies');
    if (BasisPoints == 0) return false;
    Link.RecruitCostBasisPoints = Clamp(BasisPoints, -9900, 100000);
    Resistance.RecruitScalar *= Factor(Link.RecruitCostBasisPoints);
    Link.RecruitCostExpectedScalar = Resistance.RecruitScalar;
    Link.bRecruitCostRegistered = true;
    return true;
}

static function bool SuspendFields(XComGameState_TNBCampaignLink Link, XComGameState_HeadquartersResistance Resistance)
{
    if (!Eligible(Link) || Resistance == none) return false;
    // Strip only our known contribution before the preserved callback. Native
    // Midnight Raids overwrites the scalar; multiplicative callbacks also avoid
    // compounding. An unrelated external overwrite is not blindly divided.
    if (Abs(Resistance.RecruitScalar - Link.RecruitCostExpectedScalar) <= 0.00001 * FMax(1.0, Abs(Link.RecruitCostExpectedScalar)))
        Resistance.RecruitScalar /= Factor(Link.RecruitCostBasisPoints);
    else
        `log("TNB_RECRUIT external scalar change; preserving callback result, not guessing its composition.",, 'TheNameBeneath');
    return true;
}

static function ResumeFields(XComGameState_TNBCampaignLink Link, XComGameState_HeadquartersResistance Resistance)
{
    if (!Eligible(Link) || Resistance == none) return;
    Resistance.RecruitScalar *= Factor(Link.RecruitCostBasisPoints);
    Link.RecruitCostExpectedScalar = Resistance.RecruitScalar;
}

static function XComGameState_HeadquartersResistance ResistanceHQ(XComGameState Change)
{
    local XComGameState_HeadquartersResistance Resistance;
    if (Change == none) return none;
    foreach Change.IterateByClassType(class'XComGameState_HeadquartersResistance', Resistance) return Resistance;
    return XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));
}

static function bool Register(XComGameState Change, XComGameState_TNBCampaignLink Link)
{
    local XComGameState_HeadquartersResistance Resistance;
    if (Change == none || Link == none || !Ready()) return false;
    Resistance = ResistanceHQ(Change);
    if (Resistance == none) return false;
    Resistance = XComGameState_HeadquartersResistance(Change.ModifyStateObject(class'XComGameState_HeadquartersResistance', Resistance.ObjectID));
    return RegisterFields(Link, Resistance);
}

static function bool BeginCallback(XComGameState Change)
{
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_HeadquartersResistance Resistance;
    if (Change == none) return false;
    Link = class'XComGameState_TNBCampaignLink'.static.Get(Change);
    if (!Eligible(Link)) return false; // old links and unassociated campaigns unchanged
    Resistance = ResistanceHQ(Change);
    if (Resistance == none) return false;
    Link = XComGameState_TNBCampaignLink(Change.ModifyStateObject(class'XComGameState_TNBCampaignLink', Link.ObjectID));
    Resistance = XComGameState_HeadquartersResistance(Change.ModifyStateObject(class'XComGameState_HeadquartersResistance', Resistance.ObjectID));
    return SuspendFields(Link, Resistance);
}

static function EndCallback(XComGameState Change)
{
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_HeadquartersResistance Resistance;
    if (Change == none) return;
    // BeginCallback already added the writable copies to this native transaction.
    // Never mutate a historical object if a third-party callback removed them.
    foreach Change.IterateByClassType(class'XComGameState_TNBCampaignLink', Link) break;
    foreach Change.IterateByClassType(class'XComGameState_HeadquartersResistance', Resistance) break;
    ResumeFields(Link, Resistance);
}
