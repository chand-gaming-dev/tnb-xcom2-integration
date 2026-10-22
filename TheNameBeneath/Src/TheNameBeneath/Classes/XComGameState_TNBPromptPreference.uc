// Campaign-local reminder preference; deliberately does not create a Journey link.
class XComGameState_TNBPromptPreference extends XComGameState_BaseObject;

var string CampaignID;
var bool bSuppressReminder;

static function bool IsSuppressed()
{
    local XComGameState_TNBPromptPreference Preference;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBPromptPreference', Preference)
        if (Preference.CampaignID == class'TNB_CampaignService'.static.CampaignID()) return Preference.bSuppressReminder;
    return false;
}

static function SetSuppressed(bool Suppress)
{
    local XComGameState Change;
    local XComGameState_TNBPromptPreference Preference, Existing;
    if (`HQPRES == none) return;
    if (class'TNB_ReportingSafety'.static.BlockReason(class'WorldInfo'.static.GetWorldInfo(), `XCOMHISTORY) != "") return;
    if (class'TNB_CampaignService'.static.CampaignID() == "") return;
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_TNBPromptPreference', Preference)
        if (Preference.CampaignID == class'TNB_CampaignService'.static.CampaignID()) { Existing = Preference; break; }
    if (Existing != none && Existing.bSuppressReminder == Suppress) return;
    if (Existing == none && !Suppress) return;
    Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("The Name Beneath: campaign reminder preference");
    if (Existing == none) Preference = XComGameState_TNBPromptPreference(Change.CreateNewStateObject(class'XComGameState_TNBPromptPreference'));
    else Preference = XComGameState_TNBPromptPreference(Change.ModifyStateObject(class'XComGameState_TNBPromptPreference', Existing.ObjectID));
    Preference.CampaignID = class'TNB_CampaignService'.static.CampaignID();
    Preference.bSuppressReminder = Suppress;
    `XCOMGAME.GameRuleset.SubmitGameState(Change);
}
