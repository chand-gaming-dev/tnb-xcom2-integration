class TNB_DejaVuProbeCommandlet extends Commandlet;

event int Main(string Params)
{
    local int Whole, Remainder, Index;
    local XComGameState_Unit Unit;
    local array<SoldierClassAbilityType> Earned;
    local XComLWTuple Tuple;
    local Texture2D Icon;
    local array<X2DataTemplate> Templates;
    local X2AbilityTemplate AbilityTemplate;
    local bool OldLegacyGrant;
    local int OldPercent;
    for (Index = 0; Index < 20; Index++) class'TNB_DejaVuService'.static.Accrue(1, 5, Whole, Remainder);
    if (Whole != 1 || Remainder != 0) return 1;
    Whole = 0;
    for (Index = 0; Index < 10; Index++) class'TNB_DejaVuService'.static.Accrue(1, 5, Whole, Remainder);
    for (Index = 0; Index < 10; Index++) class'TNB_DejaVuService'.static.Accrue(1, 10, Whole, Remainder);
    if (Whole != 1 || Remainder != 500000) return 2;
    class'TNB_DejaVuService'.static.Accrue(100, 0, Whole, Remainder);
    class'TNB_DejaVuService'.static.Accrue(-100, 5, Whole, Remainder);
    if (Whole != 1 || Remainder != 500000) return 3;
    Whole = 0; Remainder = 0;
    for (Index = 0; Index < 80; Index++) class'TNB_DejaVuService'.static.Accrue(0.25, 5, Whole, Remainder);
    if (Whole != 1 || Remainder != 0) return 4;
    Unit = new class'XComGameState_Unit';
    class'TNB_DejaVuService'.static.Bank(Unit, 30, 5);
    if (class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_Whole') != 1 || class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_Remainder') != 500000) return 5;
    if (class'TNB_DejaVuService'.static.CreditText(Unit) != "1.50") return 14;
    Unit.SetUnitFloatValue('TNB_DV_LinkGrant', 1, eCleanup_Never);
    class'TNB_DejaVuService'.static.AddLinkedAbility(Earned, Unit);
    class'TNB_DejaVuService'.static.AddLinkedAbility(Earned, Unit);
    if (Earned.Length != 1 || Earned[0].AbilityName != 'TNB_DejaVu') return 6;
    Whole = 0; Remainder = 0;
    for (Index = 0; Index < 120; Index++)
        class'TNB_DejaVuService'.static.Accrue(class'TNB_DejaVuService'.static.AssistCredit(Index, 1, 6), 5, Whole, Remainder);
    if (Whole != 1 || Remainder != 0 || class'TNB_DejaVuService'.static.AssistCredit(0, 1, 0) != 0) return 7;
    // Fresh tuples model repeated independent native/UI queries, not new awards.
    for (Index = 0; Index < 3; Index++)
    {
        Tuple = new class'XComLWTuple'; Tuple.Id = 'OverrideTotalNumKills';
        Tuple.Data.Add(1); Tuple.Data[0].kind = XComLWTVInt; Tuple.Data[0].i = 10;
        class'X2EventListener_TNBDejaVu'.static.PromotionCredit(Tuple, Unit, none, Tuple.Id, none);
        if (Tuple.Data[0].i != 11 || class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_Remainder') != 500000) return 8;
    }
    Unit = new class'XComGameState_Unit';
    if (class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_Whole') != 0) return 9;
    Earned.Length = 0;
    class'TNB_DejaVuService'.static.AddLinkedAbility(Earned, Unit);
    if (Earned.Length != 0) return 10;
    Templates = class'X2Ability_TNBDejaVu'.static.CreateTemplates();
    if (Templates.Length != 1) return 11;
    AbilityTemplate = X2AbilityTemplate(Templates[0]);
    if (AbilityTemplate == none || AbilityTemplate.DataName != 'TNB_DejaVu' || AbilityTemplate.bCrossClassEligible || AbilityTemplate.IconImage != "img:///UILibrary_TNB.TNB_DejaVu") return 12;
    Icon = Texture2D(DynamicLoadObject("UILibrary_TNB.TNB_DejaVu", class'Texture2D', true));
    if (Icon == none || Icon.SizeX != 512 || Icon.SizeY != 512) return 13;
    if (class'TNB_DejaVuService'.static.LinkingPreview(0, false, false) != "" || class'TNB_DejaVuService'.static.LinkingPreview(0, true, true) != "") return 15;
    if (InStr(class'TNB_DejaVuService'.static.LinkingPreview(5, false, false), "+5% XCOM promotion XP") == INDEX_NONE || InStr(class'TNB_DejaVuService'.static.LinkingPreview(17, false, false), "+17%") == INDEX_NONE) return 16;
    if (InStr(class'TNB_DejaVuService'.static.LinkingPreview(5, true, false), "Inactive") == INDEX_NONE) return 17;
    if (InStr(class'TNB_DejaVuService'.static.LinkingPreview(5, false, true), "not grant a second copy") == INDEX_NONE) return 18;
    if (class'TNB_DejaVuService'.static.LinkingResult(false, 5, false) != "" || class'TNB_DejaVuService'.static.LinkingResult(false, 100, true) != "") return 19;
    if (class'TNB_DejaVuService'.static.LinkingResult(true, 5, false) != "Deja Vu granted: +5% XCOM promotion XP" || InStr(class'TNB_DejaVuService'.static.LinkingResult(true, 17, false), "+17%") == INDEX_NONE) return 20;
    if (class'TNB_DejaVuService'.static.LinkingResult(true, 0, false) != "Deja Vu - bonus XP disabled (0%)" || InStr(class'TNB_DejaVuService'.static.LinkingResult(true, 5, true), "inactive") == INDEX_NONE) return 21;
    Unit = new class'XComGameState_Unit';
    if (class'TNB_DejaVuService'.static.LinkResultFor(Unit) != "") return 22;
    Unit.SetUnitFloatValue('TNB_DV_LinkGrant', 1, eCleanup_Never);
    // This plain saved grant must be displayable before any native ability query.
    if (class'TNB_DejaVuService'.static.LinkResultFor(Unit) == "") return 23;
    OldLegacyGrant = class'TNB_DejaVuConfig'.default.bAutomaticLinkGrant;
    OldPercent = class'TNB_DejaVuConfig'.default.BonusPercent;
    class'TNB_DejaVuConfig'.default.bAutomaticLinkGrant = false;
    class'TNB_DejaVuConfig'.default.BonusPercent = 0;
    Unit = new class'XComGameState_Unit';
    class'TNB_DejaVuService'.static.GrantAtLink(Unit);
    if (class'TNB_DejaVuService'.static.Value(Unit, 'TNB_DV_LinkGrant') != 1 || class'TNB_DejaVuService'.static.LinkPreviewFor(Unit) != "" || InStr(class'TNB_DejaVuService'.static.Description(), "disabled (0%)") == INDEX_NONE) return 24;
    class'TNB_DejaVuService'.static.Bank(Unit, 30, 5);
    class'TNB_DejaVuService'.static.Bank(Unit, 100, 0);
    if (class'TNB_DejaVuService'.static.CreditText(Unit) != "1.50") return 25;
    class'TNB_DejaVuConfig'.default.BonusPercent = 17;
    if (InStr(class'TNB_DejaVuService'.static.Description(), "17%") == INDEX_NONE || InStr(class'TNB_DejaVuService'.static.LinkResultFor(Unit), "+17%") == INDEX_NONE) return 26;
    class'TNB_DejaVuConfig'.default.bAutomaticLinkGrant = OldLegacyGrant;
    class'TNB_DejaVuConfig'.default.BonusPercent = OldPercent;
    `log("TNB_DEJA_VU_CHECKS_PASSED: fractional bank, rates, zero, assist conversion, personal values, non-stacking grants, read-only repeat queries");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
