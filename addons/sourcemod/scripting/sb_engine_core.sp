/*
 * =============================================================================
 * Smash Bros Interface Includes File
 * Includes, stocks, natives, and other resources required by Smash Bros Plugins
 *
 * (C)2014 El Diablo of www.war3evo.info                       All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License , version 3.0, as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#pragma semicolon 1

#include <sourcemod>
#include <sb_interface>
#include <tf2-weapon-restrictions>

Handle sb_round_time;
float old_sb_round_time;

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

public Plugin:myinfo = {
	name = "Smash Bros Core Engine",
	author = "El Diablo",
	description = "SB Core Plugins",
	version = PLUGIN_VERSION,
	url = "www.war3evo.info"
}

public bool SBInitNativesForwards()
{
	CreateNative("SB_GetCountDownTimer",Native_SB_GetCountDownTimer);

	CreateNative("SB_GetGamePlaying",Native_SB_GetGamePlaying);

	CreateNative("SB_SetPlayerProp",NSB_SetPlayerProp);
	CreateNative("SB_GetPlayerProp",NSB_GetPlayerProp);

	CreateNative("SB_SpawnPlayer",NSB_SpawnPlayer);

	FHOnSB_RoundEnd=CreateGlobalForward("OnSB_RoundEnd",ET_Ignore);

	// only triggered when native SB_SpawnPlayer is triggered
	FHOnSB_SpawnPlayer=CreateGlobalForward("OnSB_SpawnPlayer",ET_Ignore, Param_Cell);
	return true;
}

public OnPluginStart()
{
	CreateConVar("Super_Smash_Bros_version", PLUGIN_VERSION, "Smash Bros version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	sb_round_time = CreateConVar("sb_roundtime", "300.0", "Round Time in Seconds", FCVAR_PLUGIN);
	old_sb_round_time = GetConVarFloat(sb_round_time);
	HookConVarChange(sb_round_time, OnConVarChange);

	// Events for all games
	if(!HookEventEx("player_spawn",SB_PlayerSpawnEvent,EventHookMode_Pre)) //,EventHookMode_Pre
	{
		PrintToServer("[SmashBros] Could not hook the player_spawn event.");
	}
	if(!HookEventEx("player_death",SB_PlayerDeathEvent,EventHookMode_Pre))
	{
		PrintToServer("[SmashBros] Could not hook the player_death event.");
	}

	Handle hGameConf=INVALID_HANDLE;
	hGameConf=LoadGameConfigFile("sm-tf2.games");
	if(hGameConf)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"ForceRespawn");
		hSpawnPlayer=EndPrepSDKCall();
		CloseHandle(hGameConf);
	}
	else
	{
		PrintToServer("[SmashBros] Error, could not find configuration file for game.");
	}

	//HookEvent("teamplay_round_start", teamplay_round_start);

	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("arena_round_start", teamplay_round_active);

	HookEvent("teamplay_round_win", teamplay_round_win);
	HookEvent("teamplay_waiting_begins", teamplay_waiting_begins);

	g_OnSB_EventSpawnFH=CreateGlobalForward("OnSB_EventSpawn",ET_Hook,Param_Cell);
	g_OnSB_EventSpawnFH_Post=CreateGlobalForward("OnSB_EventSpawn_Post",ET_Ignore,Param_Cell);
	g_OnSB_EventDeathFH=CreateGlobalForward("OnSB_EventDeath",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == sb_round_time)
	{
		//CountDownTimer = GetTime() + RoundToFloor(GetConVarFloat(sb_round_time));
		if(playing)
		{
			if(old_sb_round_time==GetConVarFloat(sb_round_time))
			{
				return;
			}
			else if(old_sb_round_time>GetConVarFloat(sb_round_time))
			{
				CountDownTimer -= (old_sb_round_time - GetConVarFloat(sb_round_time));
				old_sb_round_time = GetConVarFloat(sb_round_time);
			}
			else
			{
				CountDownTimer += (GetConVarFloat(sb_round_time) - old_sb_round_time);
				old_sb_round_time = GetConVarFloat(sb_round_time);
			}
		}
	}
}

public OnMapEnd()
{
	playing=false;
}

public OnMapStart()
{
	playing=false;
}

public OnAllPluginsLoaded()
{
	// called after OnPluginStart from all plugins, even on late load
	if(LibraryExists("tf2weaponrestrictions"))
	{
		TF2WeaponRestrictions_SetRestriction("smashbros");
	}
}

public NSB_GetPlayerProp(Handle:plugin,numParams){
	int client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		return p_properties[client][SBPlayerProp:GetNativeCell(2)];
	}
	else
		return 0;
}
public NSB_SetPlayerProp(Handle:plugin,numParams){
	int client=GetNativeCell(1);
	if (client > 0 && client <= MaxClients)
	{
		p_properties[client][SBPlayerProp:GetNativeCell(2)]=GetNativeCell(3);
	}
}

public NSB_SpawnPlayer(Handle:plugin,numParams){
	int client=GetNativeCell(1);
	if (SB_ValidPlayer(client))
	{
		SDKCall(hSpawnPlayer,client);
		Call_StartForward(FHOnSB_SpawnPlayer);
		Call_PushCell(client);
		Call_Finish();
		return 1;
	}
	else
		return 0;
}

public OnClientConnected(client){
	ResetClientVars(client);
}

public OnClientDisconnected(client){
	ResetClientVars(client);
}

public OnClientPutInServer(client){
	respawn[client]=1.0;
	ResetClientVars(client);
}

public ResetClientVars(i){
	respawn[i]=0.0;
	// don't set lives here (doing it where sb_engine_display)
	//SB_SetPlayerProp(i,iLives,0);
	SB_SetPlayerProp(i,iDamage,0);
	//killPlayer[i]=false;
	//allowSpawn[i]=false;
	//fragcount[i]=0;
	//classRotation[i]=GetRandomInt(1,9);
	//nextclass[i]=TFClass_Unknown;
}

public OnRoundEnd(){

}

/*
public Action:teamplay_round_start(Handle:event,  const String:name[], bool:dontBroadcast) {
	for(new i=1;i<=MaxClients;++i){
		ResetClientVars(i);
	}
}*/

public Action teamplay_round_active(Handle event,  char[] name, bool dontBroadcast) {
	playing=true;
	old_sb_round_time = GetConVarFloat(sb_round_time);
	CountDownTimer = GetTime() + RoundToFloor(GetConVarFloat(sb_round_time));
}

public Action teamplay_round_win(Handle event,  char[] name, bool dontBroadcast) {
	playing=false;
	OnRoundEnd();
	for(int i=1;i<=MaxClients;++i){
		ResetClientVars(i);
	}
}

public Action:teamplay_waiting_begins(Handle event,  char[] name, bool dontBroadcast) {
	playing=false;
	OnRoundEnd();
}

//CreateTimer(1.2,instaspawn,victim);
/*
public Action:instaspawn(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client) && !IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
}*/

public void DoForward_OnSB_EventSpawn(client)
{
		Action returnVal = Plugin_Continue;
		Call_StartForward(g_OnSB_EventSpawnFH);
		Call_PushCell(client);
		Call_Finish(returnVal);

		if(returnVal != Plugin_Continue)
		{
			return;
		}

		Call_StartForward(g_OnSB_EventSpawnFH_Post);
		Call_PushCell(client);
		Call_Finish(dummyreturn);
}
public void DoForward_OnSB_EventDeath(int victim,int killer,int assister,int distance,int attacker_hpleft,Handle event){
		Call_StartForward(g_OnSB_EventDeathFH);
		Call_PushCell(victim);
		Call_PushCell(killer);
		Call_PushCell(assister);
		Call_PushCell(distance);
		Call_PushCell(attacker_hpleft);
		Call_PushCell(event);
		Call_Finish(dummyreturn);
}


public SB_PlayerSpawnEvent(Handle event,  char[] name, bool dontBroadcast)
{
	int userid=GetEventInt(event,"userid");
	if(userid>0)
	{
		int client=GetClientOfUserId(userid);
		if(SB_ValidPlayer(client,true))
		{

			if(!SB_GetPlayerProp(client,SpawnedOnce))
			{
				SB_SetPlayerProp(client,SpawnedOnce,true);
			}
			//forward to all other plugins last
			DoForward_OnSB_EventSpawn(client);

			SB_SetPlayerProp(client,bStatefulSpawn,false); //no longer a "stateful" spawn
		}
	}
}

public Action SB_PlayerDeathEvent(Handle event,  char[] name, bool dontBroadcast)
{
	int uid_victim = GetEventInt(event, "userid");
	int uid_attacker = GetEventInt(event, "attacker");
	int uid_assister = GetEventInt(event, "assister");

	int victimIndex = 0;
	int attackerIndex = 0;
	int assisterIndex = 0;

	int victim = GetClientOfUserId(uid_victim);
	int attacker = GetClientOfUserId(uid_attacker);
	//int assister = GetClientOfUserId(uid_assister);

	int distance=0;
	int attacker_hpleft=0;

	//new String:weapon[32];
	//GetEventString(event, "weapon", weapon, 32);
	//ReplaceString(weapon, 32, "WEAPON_", "");

	if(victim>0&&attacker>0)
	{
		//Get the distance
		float victimLoc[3];
		float attackerLoc[3];
		GetClientAbsOrigin(victim,victimLoc);
		GetClientAbsOrigin(attacker,attackerLoc);
		distance = RoundToNearest(FloatDiv(calcDistance(victimLoc[0],attackerLoc[0], victimLoc[1],attackerLoc[1], victimLoc[2],attackerLoc[2]),12.0));

		attacker_hpleft = GetClientHealth(attacker);

	}


	if(uid_attacker>0){
		attackerIndex=GetClientOfUserId(uid_attacker);
	}

	if(uid_victim>0){
		victimIndex=GetClientOfUserId(uid_victim);
	}

	if(uid_assister>0){
		assisterIndex=GetClientOfUserId(uid_assister);
	}

	bool deadringereath=false;
	if(uid_victim>0)
	{
		int deathFlags = GetEventInt(event, "death_flags");
		if (deathFlags & 32) //TF_DEATHFLAG_DEADRINGER
		{
			deadringereath=true;
			//PrintToChat(client,"SB debug: dead ringer kill");
			/*
			new assister=GetClientOfUserId(GetEventInt(event,"assister"));

			if(victimIndex!=attackerIndex && SB_ValidPlayer(attackerIndex))
			{
				if(GetClientTeam(attackerIndex)!=GetClientTeam(victimIndex))
				{
					decl String:weapon[64];
					GetEventString(event,"weapon",weapon,sizeof(weapon));
					new bool:is_hs,bool:is_melee;
					is_hs=(GetEventInt(event,"customkill")==1);
					//DP("wep %s",weapon);
					is_melee=SBIsDamageFromMelee(weapon);
				}
			}*/

		}
	}

	if(bHasDiedThisFrame[victimIndex]>0){
		return Plugin_Handled;
	}
	bHasDiedThisFrame[victimIndex]++;
	//lastly
	//DP("died? %d",bHasDiedThisFrame[victimIndex]);
	if(victimIndex&&!deadringereath) //forward to all other plugins last
	{

		//post death event actual forward
		//DoForward_OnSB_EventDeath(victimIndex,attackerIndex,SBVarArr[DeathRace],distance,attacker_hpleft,weapon);
		DoForward_OnSB_EventDeath(victimIndex,attackerIndex,assisterIndex,distance,attacker_hpleft,event);

		//DP("restore event %d",event);
		//then we allow change race AFTER death forward
		SB_SetPlayerProp(victimIndex,bStatefulSpawn,true);//next spawn shall be stateful
	}
	return Plugin_Continue;
}

public Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){
	//Distance between two 3d points
	float dx = x1-x2;
	float dy = y1-y2;
	float dz = z1-z2;

	return(SquareRoot(dx*dx + dy*dy + dz*dz));
}

public Native_SB_GetGamePlaying(Handle:plugin,numParams)
{
	return playing;
}

public Native_SB_GetCountDownTimer(Handle:plugin,numParams)
{
	return CountDownTimer;
}

TriggerEvent()
{
	playing = false;

	int dummyresult = 0;
	Call_StartForward(FHOnSB_RoundEnd);
	Call_Finish(dummyresult);
}

public OnGameFrame(){
	//if(!started) return;
	if(!playing) return;
	if(GetClientCount()<2) return;

	for(new i=1;i<MaxClients;i++){   // was MAXPLAYERSCUSTOM
		bHasDiedThisFrame[i]=0;
	}

	if(GetTime()>=CountDownTimer)
	{
		// trigger end of round
		TriggerEvent();
	}
}
