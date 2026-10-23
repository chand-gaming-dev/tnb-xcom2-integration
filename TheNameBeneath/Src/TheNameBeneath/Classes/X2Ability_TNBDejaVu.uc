class X2Ability_TNBDejaVu extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;
    local X2AbilityTemplate Template;
    Template = PurePassive('TNB_DejaVu', "img:///UILibrary_TNB.TNB_DejaVu", false, 'eAbilitySource_Perk');
    // Available to explicit class/perk grants, not automatically added to AWC rolls.
    Template.bCrossClassEligible = false;
    Templates.AddItem(Template);
    return Templates;
}
