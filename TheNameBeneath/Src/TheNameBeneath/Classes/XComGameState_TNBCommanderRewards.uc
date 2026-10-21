// Display receipt only. All amounts are captured in the original collection
// transaction; opening a popup never changes inventory, bonuses or history.
class XComGameState_TNBCommanderRewards extends XComGameState_BaseObject;

var string CampaignID;
var int CacheID, ResistanceMonth, CompletedScans;
var int BaseSupplies, BonusSupplies, TotalSupplies, BasisPoints;
var string SourceLabel;
var array<string> CollectionKeys;

static function XComGameState_TNBCommanderRewards Get(optional XComGameState Pending)
{
    local XComGameState_TNBCommanderRewards Receipt;
    if (Pending != none)
        foreach Pending.IterateByClassType(class'XComGameState_TNBCommanderRewards', Receipt) return Receipt;
    return XComGameState_TNBCommanderRewards(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TNBCommanderRewards', true));
}

static function XComGameState_TNBCommanderRewards Edit(XComGameState Pending)
{
    local XComGameState_TNBCommanderRewards Receipt;
    if (Pending == none) return none;
    Receipt = Get(Pending);
    if (Receipt == none) return XComGameState_TNBCommanderRewards(Pending.CreateNewStateObject(class'XComGameState_TNBCommanderRewards'));
    return XComGameState_TNBCommanderRewards(Pending.ModifyStateObject(class'XComGameState_TNBCommanderRewards', Receipt.ObjectID));
}

function bool HasCollection(string Campaign, int Cache, int Month, string Key)
{
    return CampaignID == Campaign && CacheID == Cache && ResistanceMonth == Month && CollectionKeys.Find(Key) != INDEX_NONE;
}

function bool RecordCollection(string Campaign, int Cache, int Month, int Scans, string Key, int Original, int Bonus, int Rate, string Source)
{
    if (Campaign == "" || Cache <= 0 || Month < 0 || Scans < 0 || Key == "" || Original <= 0 || Original > 10000000 || Bonus < -Original || Bonus > 100000000) return false;
    if (HasCollection(Campaign, Cache, Month, Key)) return false;
    if (CampaignID != Campaign || CacheID != Cache || ResistanceMonth != Month)
    {
        CampaignID = Campaign; CacheID = Cache; ResistanceMonth = Month;
        BaseSupplies = 0; BonusSupplies = 0; TotalSupplies = 0; CollectionKeys.Length = 0;
    }
    // A native drop has very few installments; refuse corrupt/unbounded receipts.
    if (CollectionKeys.Length >= 64 || BaseSupplies > 100000000 - Original || TotalSupplies > 100000000 - (Original + Bonus)) return false;
    CollectionKeys.AddItem(Key);
    CompletedScans = Scans;
    BaseSupplies += Original; BonusSupplies += Bonus; TotalSupplies += Original + Bonus;
    BasisPoints = Rate; SourceLabel = Source;
    return true;
}

function bool Matches(string Campaign, int Cache, int Month, int Scans, bool bNeedsScan)
{
    return CampaignID == Campaign && CacheID == Cache && ResistanceMonth == Month && CompletedScans == Scans && !bNeedsScan && CollectionKeys.Length > 0 && BaseSupplies > 0 && TotalSupplies == BaseSupplies + BonusSupplies;
}
