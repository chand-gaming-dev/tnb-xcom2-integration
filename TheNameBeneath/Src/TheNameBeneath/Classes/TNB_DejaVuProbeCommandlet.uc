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
