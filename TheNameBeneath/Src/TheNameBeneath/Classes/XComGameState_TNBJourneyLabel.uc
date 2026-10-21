// Cosmetic last-observed metadata only. No traits, rewards, reservations or event identity.
class XComGameState_TNBJourneyLabel extends XComGameState_BaseObject dependson(TNB_Types);

var string JourneyID, CommanderID, JourneyTitle, ObservedAt;

static function XComGameState_TNBJourneyLabel Get()
{
    return XComGameState_TNBJourneyLabel(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TNBJourneyLabel', true));
}

static function string Title(XComGameState_TNBCampaignLink Link)
{
    local XComGameState_TNBJourneyLabel Label;
    if (Link == none) return "";
    Label = Get();
    if (Label != none && Label.JourneyID == Link.Journey.JourneyID && Label.CommanderID == Link.Journey.CommanderID) return Label.JourneyTitle;
    return Link.Journey.JourneyTitle;
}

static function string SeenAt(XComGameState_TNBCampaignLink Link)
{
    local XComGameState_TNBJourneyLabel Label;
    Label = Get();
    if (Link == none) return "";
    if (Label != none && Label.JourneyID == Link.Journey.JourneyID && Label.CommanderID == Link.Journey.CommanderID) return Label.ObservedAt;
    return Link.Journey.TitleObservedAt;
}

static function Observe(JsonObject Data)
{
    local XComGameState_TNBCampaignLink Link;
    local XComGameState_TNBJourneyLabel Label;
    local XComGameState Change;
    local string NewTitle;
    if (Data == none || `HQGAME == none || `HQPRES == none) return;
    Link = class'XComGameState_TNBCampaignLink'.static.Get();
    if (Link == none || Link.CampaignID != class'TNB_CampaignService'.static.CampaignID() || Link.Journey.JourneyID != Data.GetStringValue("journey_id") || Link.Journey.CommanderID != Data.GetStringValue("commander_id")) return;
    NewTitle = Data.GetStringValue("journey_title");
    if (!class'TNB_Types'.static.ValidTitle(NewTitle)) return;
    Label = Get();
    if (Label != none && Label.JourneyID == Link.Journey.JourneyID && Label.CommanderID == Link.Journey.CommanderID && Label.JourneyTitle == NewTitle && Label.ObservedAt == Data.GetStringValue("title_observed_at")) return;
    Change = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("The Name Beneath: refresh cosmetic Journey label only");
    if (Label == none) Label = XComGameState_TNBJourneyLabel(Change.CreateNewStateObject(class'XComGameState_TNBJourneyLabel'));
    else Label = XComGameState_TNBJourneyLabel(Change.ModifyStateObject(class'XComGameState_TNBJourneyLabel', Label.ObjectID));
    Label.JourneyID = Link.Journey.JourneyID; Label.CommanderID = Link.Journey.CommanderID;
    Label.JourneyTitle = NewTitle; Label.ObservedAt = Data.GetStringValue("title_observed_at");
    `XCOMGAME.GameRuleset.SubmitGameState(Change);
}
