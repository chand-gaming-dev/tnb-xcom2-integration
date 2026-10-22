// Stateless listener: NEVER retain a Screen, Actor, World, History or request here.
// Dialog callbacks carry only primitive campaign/epoch data, not a world reference.
class UIScreenListener_TNBAvenger extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    class'X2DLCInfo_TheNameBeneath'.static.InvalidateReminderCallbacks();
    class'TNB_AvengerJourneyPrompt'.static.Schedule(UIFacilityGrid(Screen), self);
}

event OnReceiveFocus(UIScreen Screen)
{
    class'TNB_AvengerJourneyPrompt'.static.Schedule(UIFacilityGrid(Screen), self);
}

event OnLoseFocus(UIScreen Screen)
{
    class'TNB_AvengerJourneyPrompt'.static.CancelFor(Screen);
}

event OnRemoved(UIScreen Screen)
{
    class'TNB_AvengerJourneyPrompt'.static.CancelFor(Screen);
    class'X2DLCInfo_TheNameBeneath'.static.InvalidateReminderCallbacks();
}

function InvitationAnswered(name Action, UICallbackData UserData)
{
    local TNB_AvengerPromptData Data;
    local UIFacilityGrid Grid;
    if (Action != 'eUIAction_Accept') { `log("TNB_PROMPT dismissed_no_changes",, 'TheNameBeneath'); return; }
    Data = TNB_AvengerPromptData(UserData);
    if (Data == none || !class'TNB_AvengerJourneyPrompt'.static.EpochMatches(Data.Generation, class'X2DLCInfo_TheNameBeneath'.static.ReminderGeneration()))
    { `log("TNB_PROMPT ignored_stale_answer",, 'TheNameBeneath'); return; }
    if (`HQPRES == none || `HQPRES.Get2DMovie() == none) return;
    Grid = UIFacilityGrid(`HQPRES.Get2DMovie().Stack.GetCurrentScreen());
    // Native UIDialogueBox invokes fnCallbackEx AFTER removing the invitation.
    if (!class'TNB_AvengerJourneyPrompt'.static.QuietGrid(Grid)) return;
    if (!class'TNB_AvengerJourneyPrompt'.static.AnswerAllowed(Action, Data.CampaignID, class'TNB_CampaignService'.static.CampaignID(), Data.Generation,
        class'X2DLCInfo_TheNameBeneath'.static.ReminderGeneration(), true, class'XComGameState_TNBCampaignLink'.static.Get() != none)) return;
    `log("TNB_PROMPT opening_existing_review",, 'TheNameBeneath');
    class'UITNBCampaignJourney'.static.Open(Grid);
}

defaultproperties
{
    ScreenClass=class'UIFacilityGrid'
}
