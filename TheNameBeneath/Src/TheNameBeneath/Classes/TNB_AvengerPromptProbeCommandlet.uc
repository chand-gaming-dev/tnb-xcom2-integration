// Pure production policy checks only. No campaign, UI world, socket or state writes.
class TNB_AvengerPromptProbeCommandlet extends Commandlet;

event int Main(string Params)
{
    local TNB_AvengerPromptData Data;
    if (!class'TNB_AvengerJourneyPrompt'.static.ReadyStatus(true, "synthetic-journey", "upcoming") ||
        !class'TNB_AvengerJourneyPrompt'.static.ReadyStatus(true, "synthetic-journey", "started")) return 1;
    if (class'TNB_AvengerJourneyPrompt'.static.ReadyStatus(false, "synthetic-journey", "started") ||
        class'TNB_AvengerJourneyPrompt'.static.ReadyStatus(true, "", "started") ||
        class'TNB_AvengerJourneyPrompt'.static.ReadyStatus(true, "synthetic-journey", "finished") ||
        class'TNB_AvengerJourneyPrompt'.static.ReadyStatus(true, "synthetic-journey", "unknown")) return 2;
    if (!class'TNB_AvengerJourneyPrompt'.static.EpochMatches(0, 0) || !class'TNB_AvengerJourneyPrompt'.static.EpochMatches(41, 41)) return 3;
    if (class'TNB_AvengerJourneyPrompt'.static.EpochMatches(-1, -1) || class'TNB_AvengerJourneyPrompt'.static.EpochMatches(41, 42) ||
        class'TNB_AvengerJourneyPrompt'.static.EpochMatches(42, 41)) return 4;
    if (!class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Accept', "campaign-a", "campaign-a", 4, 4, true, false)) return 5;
    if (class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Cancel', "campaign-a", "campaign-a", 4, 4, true, false) ||
        class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Closed', "campaign-a", "campaign-a", 4, 4, true, false) ||
        class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Accept', "campaign-a", "campaign-b", 4, 4, true, false) ||
        class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Accept', "", "", 4, 4, true, false)) return 6;
    if (class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Accept', "campaign-a", "campaign-a", 4, 5, true, false) ||
        class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Accept', "campaign-a", "campaign-a", -1, -1, true, false) ||
        class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Accept', "campaign-a", "campaign-a", 4, 4, false, false) ||
        class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed('eUIAction_Accept', "campaign-a", "campaign-a", 4, 4, true, true)) return 7;
    if (!class'TNB_AvengerJourneyPrompt'.static.RetryQuiet(0) || !class'TNB_AvengerJourneyPrompt'.static.RetryQuiet(19) ||
        class'TNB_AvengerJourneyPrompt'.static.RetryQuiet(20) || class'TNB_AvengerJourneyPrompt'.static.RetryQuiet(-1)) return 8;
    if (!class'TNB_CampaignService'.static.ShouldOfferReminder(false, false, false, true, true) ||
        class'TNB_CampaignService'.static.ShouldOfferReminder(true, false, false, true, true) ||
        class'TNB_CampaignService'.static.ShouldOfferReminder(false, true, false, true, true) ||
        class'TNB_CampaignService'.static.ShouldOfferReminder(false, false, true, true, true)) return 9;
    Data = new class'TNB_AvengerPromptData';
    Data.CampaignID = "campaign-a"; Data.Generation = 4;
    if (Data.CampaignID != "campaign-a" || Data.Generation != 4 || Actor(Data.Outer) != none) return 10;
    if (class'UIScreenListener_TNBAvenger'.default.ScreenClass != class'UIFacilityGrid') return 11;
    `log("TNB_AVENGER_PROMPT_PASS: readiness, finished/unconfigured exclusion, epoch/campaign stale-answer guards, accept-only read-only handoff, bounded quiet retries, primitive callback data and stateless facility-grid listener.");
    return 0;
}

defaultproperties
{
    IsClient=false
    IsServer=false
    IsEditor=true
    LogToConsole=true
}
