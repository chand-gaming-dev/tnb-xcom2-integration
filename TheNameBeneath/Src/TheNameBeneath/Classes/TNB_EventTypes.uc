// Save-compatible plain data only. Never put actors, templates or delegates here.
class TNB_EventTypes extends Object;

struct ConditionEpisode
{
    var name TemplateName;
    var int Sequence;
    var string Key;
    var bool bAcquisitionKnown;
    var bool bClosed;
};

struct SoldierObservation
{
    var int UnitID;
    var string InstanceID;
    var string LinkToken;
    var int Rank;
    var bool bWounded;
    var bool bDead;
    var array<name> Negative;
    var array<name> Cured;
    var array<name> Acquired;
    var string WoundKey;
    var int WoundSequence;
    var string CapturedLocal;
    var array<ConditionEpisode> Episodes;
};

struct MissionObservation
{
    var string Key;
    var int ObjectID;
    var name Source;
    var string Kind;
    var string Label;
    var array<int> UnitIDs;
    var array<string> Instances;
    var bool bStarted;
    var bool bCompleted;
    var bool bCleanup;
    var bool bWon;
    var bool bAborted;
    var string CompletedLocal;
    var string ParentKey;
    var string AmbushResult;
    var string Diagnostic;
};

struct PendingReport
{
    var string Key;
    var string CaptureJSON;
    var string EventID;
    var string State;
};

struct BondOccurrence
{
    var string PairKey;
    var int Episode;
    var int SourceHistoryIndex;
    var int FromLevel;
    var int ToLevel;
};

// Frozen before tactical-to-strategy wound reduction/recovery can change unit status.
struct MissionInjurySnapshot
{
    var string MissionKey;
    var int RosterCount;
    var int Injuries;
    var bool bKnown;
};

// Mod-owned metadata, not a field/component on XCOM's mission-site object.
struct TacticalMissionAttempt
{
    var string AttemptID;
    var string Key;
    var string SourceMissionKey;
};

struct CaptivityObservation
{
    var int UnitID;
    var string InstanceID;
    var bool bCaptured;
    var int CaptureSequence;
    var int FreedomSequence;
    var int ObservedHistoryIndex;
};
