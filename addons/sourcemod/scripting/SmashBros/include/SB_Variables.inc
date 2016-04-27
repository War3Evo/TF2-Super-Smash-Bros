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

//DAMAGE SYSTEM
//would you like to see the damage stack print out?
//#define DEBUG
new Handle:FHOnSB_TakeDmgAllPre;
new Handle:FHOnSB_TakeDmgAll;

new Handle:g_OnSBEventPostHurtFH;
new Handle:PyroSB_ChanceModifierCvar;
new Handle:HeavySB_ChanceModifierCvar;

new g_CurDamageType=-99;
new g_CurInflictor=-99; //variables from sdkhooks, natives retrieve them if needed

new Float:g_CurDMGModifierPercent=-99.9;

new g_CurLastActualDamageDealt=-99;

new bool:g_CanSetDamageMod=false; //default false, you may not change damage percent when there is none to change
new bool:g_CanDealDamage=true; //default true, you can initiate damage out of nowhere
//for deal damage only

new dummyresult;

//global
new ownerOffset;

new damagestack=0;

new Float:ChanceModifier[MAXPLAYERSCUSTOM];

//cvar handle
new Handle:ChanceModifierSentry;
new Handle:ChanceModifierSentryRocket;


