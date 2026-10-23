class TNB_RecruitCostHook extends Object;

var delegate<X2GameplayMutatorTemplate.OnActivatedDelegate> OriginalActivated;
var delegate<X2GameplayMutatorTemplate.OnDeactivatedDelegate> OriginalDeactivated;
var delegate<X2GameplayMutatorTemplate.OnActivatedDelegate> BoundActivated;
var delegate<X2GameplayMutatorTemplate.OnDeactivatedDelegate> BoundDeactivated;
var int Depth;
var bool bSuspended;

function Activate(XComGameState Change, StateObjectReference InRef, optional bool bReactivate = false)
{
    Enter(Change);
    if (OriginalActivated != none) OriginalActivated(Change, InRef, bReactivate);
    Leave(Change);
}

function Deactivate(XComGameState Change, StateObjectReference InRef)
{
    Enter(Change);
    if (OriginalDeactivated != none) OriginalDeactivated(Change, InRef);
    Leave(Change);
}

function Enter(XComGameState Change)
{
    if (Depth == 0) bSuspended = class'TNB_RecruitCostService'.static.BeginCallback(Change);
    Depth++;
}

function Leave(XComGameState Change)
{
    Depth--;
    if (Depth == 0)
    {
        if (bSuspended) class'TNB_RecruitCostService'.static.EndCallback(Change);
        bSuspended = false;
    }
}
