Handle sb_round_time;

Handle g_OnSB_EventSpawnFH;
Handle g_OnSB_EventSpawnFH_Post;
Handle g_OnSB_EventDeathFH;

Handle FHOnSB_SpawnPlayer;

Handle FHOnSB_RoundEnd;

float respawn[MAXPLAYERS+1];

//new dummyreturn; //for your not used return values
int bHasDiedThisFrame[MAXPLAYERSCUSTOM];

int p_properties[MAXPLAYERSCUSTOM][SBPlayerProp];

//new bool:started=false;
bool playing=false;

Handle hSpawnPlayer;


//new ignoreClient;

int CountDownTimer;
//new Float:RespawnTimer[MAXPLAYERS+1];


// Calculations Variables
int LastValidAttacker[MAXPLAYERSCUSTOM];
bool firstblood = false;

Handle sb_medichealself;
Handle sb_medicheal;
Handle sb_medicmegaheal;
Handle sb_angles;
Handle sb_upward_force;

int g_sb_medichealself;
int g_sb_medicheal;
int g_sb_medicmegaheal;
float g_fsb_angles;
float g_fsb_upward_force;

Handle sb_fc_bhop;

int iTotalScoreOffset = -1;

int iTotalScore[MAXPLAYERS+1];

bool bHopEnabled = false;

// SB_Engine_DamageSystem
// SB_Engine_DamageSystem
// SB_Engine_DamageSystem
// SB_Engine_DamageSystem
// SB_Engine_DamageSystem
// SB_Engine_DamageSystem

//would you like to see the damage stack print out?
//#define DEBUG
Handle FHOnSB_TakeDmgAllPre;
Handle FHOnSB_TakeDmgAll;

Handle g_OnSBEventPostHurtFH;
Handle PyroSB_ChanceModifierCvar;
Handle HeavySB_ChanceModifierCvar;

int g_CurDamageType=-99;
int g_CurInflictor=-99; //variables from sdkhooks, natives retrieve them if needed

float g_CurDMGModifierPercent=-99.9;

int g_CurLastActualDamageDealt=-99;
bool g_CanSetDamageMod=false; //default false, you may not change damage percent when there is none to change
bool g_CanDealDamage=true; //default true, you can initiate damage out of nowhere
//for deal damage only
int dummyresult;

//global
int ownerOffset;
int damagestack=0;
float ChanceModifier[MAXPLAYERSCUSTOM];

//cvar handle
Handle ChanceModifierSentry;
Handle ChanceModifierSentryRocket;


// SB_Engine_Display
// SB_Engine_Display
// SB_Engine_Display
// SB_Engine_Display
// SB_Engine_Display
// SB_Engine_Display
// SB_Engine_Display

TFClassType PlayerNextClass[MAXPLAYERSCUSTOM];

Handle sb_lives;
Handle sb_chatmsg;
Handle sb_chatmsg_balance;

Handle CountDownTimerMessage;
Handle TargetDamageMessage;
Handle YourDamageMessage;
Handle YourLivesMessage;

bool g_spec[MAXPLAYERS+1] = {true, ...};

bool displayedHelp[MAXPLAYERSCUSTOM];

bool NewMap = true;

//new Float:respawn[MAXPLAYERS+1];
int LastPersonAttacked[MAXPLAYERSCUSTOM];

//new bool:started=false;
//new bool:playing=false;





// NEW
bool bStopMovement[MAXPLAYERSCUSTOM];


bool bLateLoad = false;

int mBloodSpray;
int mBloodDrop;
