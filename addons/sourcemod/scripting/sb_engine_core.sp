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

#pragma dynamic 600000

#pragma semicolon 1

#include <sourcemod>
#include <sb_interface>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <sb_addon_fc>
#include <updater>

#define JENKINS_UPDATE_URL "DEVELOP"

#define UPDATE_URL "http://107.161.29.8:8080/job/TF2-Super-Smash-Bros%20%28" ... JENKINS_UPDATE_URL ... "%29/lastSuccessfulBuild/artifact/addons/sourcemod/updatefile.txt"

#include "SmashBros/include/SB_Constants.inc"
#include "SmashBros/include/SB_Variables.inc"

#include "SmashBros/SB_001_AddCommandListener.sp"
#include "SmashBros/SB_001_CreateConVar.sp"
#include "SmashBros/SB_001_CreateTimer.sp"
#include "SmashBros/SB_001_HookEvent.sp"
#include "SmashBros/SB_001_OnAllPluginsLoaded.sp"
#include "SmashBros/SB_001_OnClientConnected.sp"
#include "SmashBros/SB_001_OnClientDisconnected.sp"
#include "SmashBros/SB_001_OnClientPutInServer.sp"
#include "SmashBros/SB_001_OnConditionAdded.sp"
#include "SmashBros/SB_001_OnGameFrame.sp"
#include "SmashBros/SB_001_OnMapEnd.sp"
#include "SmashBros/SB_001_OnMapStart.sp"
#include "SmashBros/SB_001_OnPluginStart.sp"
#include "SmashBros/SB_001_PrecacheModel.sp"
#include "SmashBros/SB_001_RegConsoleCmd.sp"
#include "SmashBros/SB_001_SDKHook.sp"

#include "SmashBros/SB_Engine_Calculations.sp"
#include "SmashBros/SB_Engine_DamageSystem.sp"
#include "SmashBros/SB_Engine_Display.sp"
#include "SmashBros/SB_Engine_Effects.sp"
#include "SmashBros/SB_Engine_InitForwards.sp"
#include "SmashBros/SB_Engine_InitNatives.sp"
#include "SmashBros/SB_Engine_Internal_OnSB_EventDeath.sp"
#include "SmashBros/SB_Engine_Internal_OnSB_EventSpawn.sp"
#include "SmashBros/SB_Engine_Internal_OnSB_RoundEnd.sp"
#include "SmashBros/SB_Engine_Internal_OnSB_SpawnPlayer.sp"
#include "SmashBros/SB_Engine_Libraries.sp"
#include "SmashBros/SB_Engine_Sound.sp"
#include "SmashBros/SB_Engine_Updater.sp"
#include "SmashBros/SB_Engine_Weapon_Manager.sp"
//#include "SmashBros/"
//#include "SmashBros/"
//#include "SmashBros/"
//#include "SmashBros/"
//#include "SmashBros/"
//#include "SmashBros/"


public Plugin:myinfo = {
	name = "Smash Bros Core Engine",
	author = "El Diablo",
	description = "SB Core Plugins",
	version = PLUGIN_VERSION,
	url = "www.war3evo.info"
}


/**********************
 * CAUTION, THIS INTERFACE NOW HANDLES AskPluginLoad2VIPCustom BECAUSE IT IS REQUIRED TO HANDLE CERTAIN TASKS
 * It acually simplifies things for you:
 * Determines game mode
 * Mark Natives optional
 * Calls your own functions (hackish way) if you have them:
 * InitNativesForwards()
 * AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max);
 * So if you want to do something in AskPluginLoad2, implement public AskPluginLoad2Custom(...) instead.
 */
public APLRes:AskPluginLoad2(Handle:plugin,bool:late,String:error[],err_max)
{
	if(late==true)
	{
		bLateLoad = true;
		/*
		//bLateLoad = true;

		// To help reloading plugin
		MarkNativeAsOptional("SB_DamageModPercent");
		MarkNativeAsOptional("SB_GetDamageType");
		MarkNativeAsOptional("SB_GetDamageInflictor");
		MarkNativeAsOptional("SB_GetSBDamageDealt");
		MarkNativeAsOptional("SB_GetDamageStack");
		MarkNativeAsOptional("SB_ChanceModifier");
		MarkNativeAsOptional("SB_IsOwnerSentry");

		MarkNativeAsOptional("SB_GetCountDownTimer");

		MarkNativeAsOptional("SB_GetGamePlaying");

		MarkNativeAsOptional("SB_SetPlayerProp");
		MarkNativeAsOptional("SB_GetPlayerProp");

		MarkNativeAsOptional("SB_SpawnPlayer");

		MarkNativeAsOptional("SB_ApplyWeapons");
		*/
	}
	else
	{
		bLateLoad = false;
	}

	//GlobalOptionalNatives();
	/*
	new Function:func;
	func=GetFunctionByName(plugin, "SBInitNativesForwards");
	if(func!=INVALID_FUNCTION) { //non sb plugins dont have this function
		Call_StartFunction(plugin, func);
		Call_Finish(dummy);
		if(!dummy) {
			LogError("InitNativesForwards did not return true, possible failure");
		}
	}
	func=GetFunctionByName(plugin, "AskPluginLoad2SBCustom");
	if(func!=INVALID_FUNCTION) { //non sb plugins dont have this function
		Call_StartFunction(plugin, func);
		Call_PushCell(plugin);
		Call_PushCell(late);
		Call_PushString(error);
		Call_PushCell(err_max);
		Call_Finish(dummy);
		if(APLRes:dummy==APLRes_SilentFailure) {
			return APLRes_SilentFailure;
		}
		if(APLRes:dummy!=APLRes_Success) {
			LogError("AskPluginLoad2SBCustom did not return true, possible failure");
		}
	}*/
	APLRes CheckSuccess = APLRes_Success;
	CheckSuccess = Load2SBCustom();

	RegPluginLibrary("smashbros");
	return CheckSuccess;
}
//=============================================================================
// AskPluginLoad2SBCustom
//=============================================================================
public APLRes Load2SBCustom()
{

	//PrintToServer("<< Smashbros is Loading >>");
	PrintToServer("");
	PrintToServer("");
	PrintToServer("  .|'''.|  '||    ||'     |      .|'''.|  '||'  '||'    '||''|.   '||''|.    ..|''||    .|'''.|  ");
	PrintToServer("  ||..  '   |||  |||     |||     ||..  '   ||    ||      ||   ||   ||   ||  .|'    ||   ||..  '  ");
	PrintToServer("   ''|||.   |'|..'||    |  ||     ''|||.   ||''''||      ||'''|.   ||''|'   ||      ||   ''|||.  ");
	PrintToServer(" .     '||  | '|' ||   .''''|.  .     '||  ||    ||      ||    ||  ||   |.  '|.     || .     '|| ");
	PrintToServer(" |'....|'  .|. | .||. .|.  .||. |'....|'  .||.  .||.    .||...|'  .||.  '|'  ''|...|'  |'....|'  ");
	PrintToServer("");
	PrintToServer("");

	CreateConVar("Super_Smash_Bros_version", PLUGIN_VERSION, "Smash Bros version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if(!SB_Engine_InitNatives())
	{
		LogError("[SmashBros] There was a failure in creating the native based functions, definately halting.");
		return APLRes_Failure;
	}

	PrintToServer("PASSED SB_Engine_InitNatives");

	if(!SB_Engine_InitForwards())
	{
		LogError("[SmashBros] There was a failure in creating the forward based functions, definately halting.");
		return APLRes_Failure;
	}

	PrintToServer("PASSED SB_Engine_InitForwards");

	return APLRes_Success;
}

public ResetClientVars(i)
{
	respawn[i]=0.0;
	// don't set lives here (doing it where sb_engine_display)
	//SB_SetPlayerProp(i,iLives,0);
	SetPlayerProp(i,iDamage,0);
	//killPlayer[i]=false;
	//allowSpawn[i]=false;
	//fragcount[i]=0;
	//classRotation[i]=GetRandomInt(1,9);
	//nextclass[i]=TFClass_Unknown;
}

public OnRoundEnd()
{

}

/*
public Action:teamplay_round_start(Handle:event,  const String:name[], bool:dontBroadcast) {
	for(new i=1;i<=MaxClients;++i){
		ResetClientVars(i);
	}
}*/

//CreateTimer(1.2,instaspawn,victim);
/*
public Action:instaspawn(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client) && !IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
}*/

public Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2)
{
	//Distance between two 3d points
	float dx = x1-x2;
	float dy = y1-y2;
	float dz = z1-z2;

	return(SquareRoot(dx*dx + dy*dy + dz*dz));
}


public void CalculateTeamScores(int &RedTeam, int &BlueTeam)
{
	int TheLives = 0;

	for(int i=1;i<MaxClients;i++)
	{
		if(SB_ValidPlayer(i,true))
		{
			TheLives = GetPlayerProp(i,iLives);
			if(TheLives>0)
			{
				if(GetClientTeam(i)==TEAM_RED)
				{
					RedTeam+=TheLives;
				}
				else if(GetClientTeam(i)==TEAM_BLUE)
				{
					BlueTeam+=TheLives;
				}
			}
		}
	}
}
