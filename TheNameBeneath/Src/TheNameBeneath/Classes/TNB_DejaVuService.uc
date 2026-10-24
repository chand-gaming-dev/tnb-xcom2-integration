// Bank only newly earned personal promotion credit. Query hooks never write history.
class TNB_DejaVuService extends Object;

static function bool Owns(XComGameState_Unit Unit)
{
    return Unit != none && Unit.IsSoldier() && Unit.HasAbilityFromAnySource('TNB_DejaVu');
}

static function int Value(XComGameState_Unit Unit, name Key)
{
    local UnitValue Stored;
    if (Unit != none && Unit.GetUnitValue(Key, Stored)) return Max(0, Round(Stored.fValue));
    return 0;
}

// Split fixed-point bank keeps the remainder below 1,000,000 (exact float integer).
// Percent changes affect only subsequent awards; zero never deletes earned credit.
static function Accrue(float Credit, int Percent, out int Whole, out int Remainder)
{
    local float Bonus;
    local int Integral;
    if (Credit <= 0 || Percent <= 0 || Whole < 0 || Remainder < 0 || Remainder >= 1000000) return;
    Bonus = Credit * float(Clamp(Percent, 0, 100)) / 100.0;
    if (Bonus > 1000000.0) return;
    Integral = int(Bonus);
    Remainder += Round((Bonus - float(Integral)) * 1000000.0);
    Whole = Min(1000000, Whole + Integral + Remainder / 1000000);
    Remainder = Remainder % 1000000;
}

static function Bank(XComGameState_Unit Unit, float Credit, int Percent)
{
    local int Whole, Remainder;
    if (Unit == none || Credit <= 0 || Percent <= 0) return;
    Whole = Value(Unit, 'TNB_DV_Whole');
    Remainder = Value(Unit, 'TNB_DV_Remainder');
    Accrue(Credit, Percent, Whole, Remainder);
    Unit.SetUnitFloatValue('TNB_DV_Whole', Whole, eCleanup_Never);
    Unit.SetUnitFloatValue('TNB_DV_Remainder', Remainder, eCleanup_Never);
}

// Award assist promotion credit when native conversion earns a whole credit,
// not 1/N each kill (which would bank unearned, still-incomplete assists).
static function int AssistCredit(float Previous, float Incoming, int AssistsPerKill)
{
    if (AssistsPerKill <= 0 || Incoming <= 0) return 0;
    return Max(0, Round(Previous + Incoming) / AssistsPerKill - Round(Previous) / AssistsPerKill);
}

// Call only with the native caller's mutable pending state, never a submitted state.
static function Award(XComGameState Pending, XComGameState_Unit Unit, float Credit)
{
    local XComGameState_Unit Mutable;
    if (Pending == none || Unit == none || Credit <= 0 || class'X2ExperienceConfig'.default.bUseFullXpSystem) return;
    Mutable = XComGameState_Unit(Pending.GetGameStateForObjectID(Unit.ObjectID));
    if (Mutable == none) Mutable = Unit;
    if (!Owns(Mutable) || !Mutable.CanEarnXp() || class'TNB_DejaVuConfig'.default.BonusPercent <= 0) return;
    Mutable = XComGameState_Unit(Pending.ModifyStateObject(Mutable.Class, Mutable.ObjectID));
    Bank(Mutable, Credit, class'TNB_DejaVuConfig'.default.BonusPercent);
}

static function GrantAtLink(XComGameState_Unit Unit)
{
    if (Unit != none && class'TNB_DejaVuConfig'.default.bAutomaticLinkGrant)
        Unit.SetUnitFloatValue('TNB_DV_LinkGrant', 1, eCleanup_Never);
}

static function AddLinkedAbility(out array<SoldierClassAbilityType> Earned, XComGameState_Unit Unit)
{
    local SoldierClassAbilityType Ability;
    if (Value(Unit, 'TNB_DV_LinkGrant') != 1 || Earned.Find('AbilityName', 'TNB_DejaVu') != INDEX_NONE) return;
    Ability.AbilityName = 'TNB_DejaVu'; Ability.ApplyToWeaponSlot = eInvSlot_Unknown;
    Earned.AddItem(Ability);
}

static function string Description()
{
    if (class'X2ExperienceConfig'.default.bUseFullXpSystem)
        return "You can't quite shake the feeling you've been here before.\n\nInactive: this overhaul uses a replacement full-XP system. Deja Vu supports WOTC kill-credit promotion progression.";
    return "You can't quite shake the feeling you've been here before.\n\nGain " $ Clamp(class'TNB_DejaVuConfig'.default.BonusPercent, 0, 100) $ "% additional promotion credit from personal kills, assists and ordinary covert-action XP. Fractions accumulate. No extra Ability Points or online XP; guaranteed promotion rewards are not multiplied.";
}

static function string LinkingPreview(bool AutomaticGrant, int Percent, bool FullXpSystem, bool AlreadyOwned)
{
    local string Body;
    if (!AutomaticGrant) return "";
    Body = "Local linking bonus: Deja Vu\nYou can't quite shake the feeling you've been here before.\n";
    if (AlreadyOwned) Body $= "Already owned; linking will not grant a second copy.\n";
    if (FullXpSystem) return Body $ "Inactive with this overhaul's replacement full-XP system.";
    return Body $ "+" $ Clamp(Percent, 0, 100) $ "% XCOM promotion XP from personal kills, assists and ordinary covert actions; fractions accumulate. No extra Ability Points or online XP. Configurable in MCM.";
}

static function string LinkPreviewFor(XComGameState_Unit Unit)
{
    return LinkingPreview(class'TNB_DejaVuConfig'.default.bAutomaticLinkGrant, class'TNB_DejaVuConfig'.default.BonusPercent, class'X2ExperienceConfig'.default.bUseFullXpSystem, Owns(Unit));
}

// Result text is based on the committed link receipt, not today's auto-grant
// checkbox. Turning that checkbox off cannot erase an earlier soldier's grant.
static function string LinkingResult(bool Granted, int Percent, bool FullXpSystem)
{
    if (!Granted) return "";
    if (FullXpSystem) return "Deja Vu granted - XP bonus inactive for this overhaul";
    return "Deja Vu granted: +" $ Clamp(Percent, 0, 100) $ "% XCOM promotion XP";
}

static function string LinkResultFor(XComGameState_Unit Unit)
{
    return LinkingResult(Value(Unit, 'TNB_DV_LinkGrant') == 1, class'TNB_DejaVuConfig'.default.BonusPercent, class'X2ExperienceConfig'.default.bUseFullXpSystem);
}

static function string CreditText(XComGameState_Unit Unit)
{
    local int Fraction;
    Fraction = Value(Unit, 'TNB_DV_Remainder') / 10000;
    return Value(Unit, 'TNB_DV_Whole') $ "." $ ((Fraction < 10) ? "0" : "") $ Fraction;
}
