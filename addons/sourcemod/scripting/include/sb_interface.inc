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


/**
 * File: sb_interface.inc
 * Description: The file to be included for creating races and whatnot.
 * Author(s): El Diablo
 *
 *
 * LISTS NATIVES AND FORWARDS, BUT NOT ACTUALLY DEFINES THE CODE
 */

#pragma semicolon 1

#undef REQUIRE_EXTENSIONS
//#include <sdktools>
//#include <tf2>
//#include <tf2_stocks>
//#include <gamemode>
#include <sourcemod>
//#include <clients>
#include <morecolors>
#include <sb_constants>
#include <tf2_stocks>
#include <sdktools_trace>

stock dummy; //variable for dummies! Use this where ever u want for a dummy return
stock dummyreturn;
stock String:dummystr[32]; //just a dummy string!

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
	GlobalOptionalNatives();
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
			LogError("AskPluginLoad2Custom did not return true, possible failure");
		}
	}
	return APLRes_Success;
}
/**********************
 * Implement this if you have natives/forwards
 */
forward bool:SBInitNativesForwards();

/**********************
 * Implement this if you need AskPluginLoad2Custom
 */
forward APLRes:AskPluginLoad2VIPCustom(Handle:plugin,bool:late,String:error[],err_max);


//We mark some natives optional so different plugins can still startup
/**********************
 * CALL THIS IN ASKPLUGINLOAD if you are using any of these or have native errors
 */

stock GlobalOptionalNatives()
{
	// DAMAGE SYSTEM
	MarkNativeAsOptional("SB_DamageModPercent");
	MarkNativeAsOptional("SB_GetDamageType");
	MarkNativeAsOptional("SB_GetDamageInflictor");
	MarkNativeAsOptional("SB_GetSBDamageDealt");
	MarkNativeAsOptional("SB_GetDamageStack");
	MarkNativeAsOptional("SB_ChanceModifier");
	MarkNativeAsOptional("SB_IsOwnerSentry");

	MarkNativeAsOptional("SB_GetCountDownTimer");

	MarkNativeAsOptional("SB_GetGamePlaying");
}

/*
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 * Natives and misc stocks
 */

/*
 * End's the current round, allows specifying the winning
 * team and more.
 * This function currently works in TF2 only (it uses the game_round_win entity).
 *
 * @param team			The winning Team, pass 0 for Sudden Death mode (no winning team)
 * @param forceMapReset If to force the map to reset during the force respawn after the round is over.
 * @param switchTeams	If to switch the teams when the game is going to be reset.
 * @return				True on success, false otherwise
 */
stock bool:Game_EndRound(team=0, bool:forceMapReset=false, bool:switchTeams=false)
{
	new game_round_win = FindEntityByClassname(-1, "game_round_win");

	if (game_round_win == -1) {
		game_round_win = CreateEntityByName("game_end");

		if (game_round_win == -1) {
			ThrowError("Unable to find or create entity \"game_round_win\"");
		}
	}

	DispatchKeyValue(game_round_win, "TeamNum"			, (team			? "true" : "false"));
	DispatchKeyValue(game_round_win, "force_map_reset"	, (forceMapReset? "true" : "false"));
	DispatchKeyValue(game_round_win, "switch_teams"		, (switchTeams	? "true" : "false"));

	return AcceptEntityInput(game_round_win, "RoundWin");
}

native bool:SB_GetGamePlaying();

native SB_GetCountDownTimer();

native SB_SpawnPlayer(int client);


/* is a normal engine cvar empty (zero length, "") ? */
stock bool:CvarEmpty(Handle:sourcemod_convar) {
	static String:zzstr[32];
	return (GetConVarString(sourcemod_convar, zzstr, sizeof(zzstr))&&strlen(zzstr)<1);

}

//=============================================================================
// Get Damage Details
//=============================================================================

//get the actual damage dealt from SB_DealDamage, because real damage is different after taking account to magic/physical armor
//u wana call this immediately after SB_DealDamage cuz this is a single global variable. when someone else calls SB_DealDamage it will be changed
native SB_GetSBDamageDealt();

//get the depth of the damage stack, usually 1 or more
native SB_GetDamageStack();

/*
 * forces the damage to be multiplied by @num
 * shall only be done inside SDKHOOKS damage forward (when damage hasnt been dealt yet)
 * @noreturn
 */
native SB_DamageModPercent(Float:num);

//return the game damagetype (burn, laser, etc) of the last damage (TakeDmg forward)
native SB_GetDamageType();
//get inflictor of the last damage (TakeDmg forward) (ie sentry gun  is a different object than the attacker itself)
native SB_GetDamageInflictor();

//=============================================================================
// Is client Sentry Owner?
//=============================================================================

/**
 * Basically checks to see if this is a Owner's sentry.
 *
 * best use inside OnSBTakeDmgBullet or OnSBTakeDmgBullet or SDKHooks calls that have inflictors
 * where you can use this code:
 *  new inflictor = SBGetDamageInflictor();
 *  then pass the inflictor as the entity below:
 *
 * @param client: client you wish to check as the owner
 * @param UseInternalInflictor: true if you wish the native to grab the SBGetDamageInflictor for you.
 *         ^ only use if you are using inside a OnSBTakeDamage function type, else use your own
 *         (Default true)
 * @param ExternalInflictor: entity you wish to check that maybe a sentry / optional
 *        Make sure you put UseInternalInflictor as false.
 *
 * @param return: true if the client is the sentry owner and the entity is the owned sentry
 *
 */
native bool:SB_IsOwnerSentry(client,bool:UseInternalInflictor=true,ExternalInflictor=0);

//=============================================================================
// Chance Modifier
//=============================================================================

//helper, directly uses last inflictor and damagetype
// Acts like a DPS limiter
native Float:SB_ChanceModifier(attacker);

stock bool:SBIsDamageFromMelee(const String:weapon[])
{
	return (// Logfile names
			StrEqual(weapon, "shovel") ||
			StrEqual(weapon, "wrench") ||
			StrEqual(weapon, "bat") ||
			StrEqual(weapon, "bonesaw") ||
			StrEqual(weapon, "bottle") ||
			StrEqual(weapon, "club") ||
			StrEqual(weapon, "fireaxe") ||
			StrEqual(weapon, "fists") ||
			StrEqual(weapon, "sandman") ||
			StrEqual(weapon, "pickaxe") ||
			StrEqual(weapon, "sword") ||
			StrEqual(weapon, "demoshield") ||
			StrEqual(weapon, "taunt_scout") ||
			StrEqual(weapon, "taunt_sniper") ||
			StrEqual(weapon, "taunt_pyro") ||
			StrEqual(weapon, "taunt_demoman") ||
			StrEqual(weapon, "taunt_heavy") ||
			StrEqual(weapon, "taunt_spy") ||
			StrEqual(weapon, "taunt_soldier")||
			StrEqual(weapon, "annihilator") ||
			StrEqual(weapon, "ubersaw") ||
			StrEqual(weapon, "axtinguisher") ||
			StrEqual(weapon, "gloves") ||
			StrEqual(weapon, "sandman") ||
			StrEqual(weapon, "unique_pickaxe") ||
			StrEqual(weapon, "robot_arm") ||
			StrEqual(weapon, "sledgehammer") ||
			StrEqual(weapon, "paintrain") ||
			StrEqual(weapon, "southern_hospitality") ||
			StrEqual(weapon, "wrench_golden") ||
			StrEqual(weapon, "tribalkukri") ||
			StrEqual(weapon, "battleaxe") ||
			StrEqual(weapon, "battleneedle") ||
			StrEqual(weapon, "powerjack") ||
			StrEqual(weapon, "holy_mackerel") ||
			StrEqual(weapon, "eternal_reward") ||
			StrEqual(weapon, "bushwacka") ||
			StrEqual(weapon, "gloves_running_urgently") ||
			StrEqual(weapon, "fryingpan") ||
			StrEqual(weapon, "headtaker") ||
			StrEqual(weapon, "ullapool_caber") ||
			StrEqual(weapon, "warrior_spirit") ||
			StrEqual(weapon, "candy_cane") ||
			StrEqual(weapon, "boston_basher") ||
			StrEqual(weapon, "back_scratcher") ||
			StrEqual(weapon, "claidheamohmor") ||
			StrEqual(weapon, "wrench_jag") ||
			StrEqual(weapon, "steel_fists") ||
			StrEqual(weapon, "lava_axe") ||
			StrEqual(weapon, "lava_bat") ||
			StrEqual(weapon, "warfan") ||
			StrEqual(weapon, "kunai") ||
			StrEqual(weapon, "demokatana") ||
			StrEqual(weapon, "shahanshah") ||
			StrEqual(weapon, "persian_persuader") ||
			StrEqual(weapon, "solemn_vow") ||
			StrEqual(weapon, "market_gardener") ||
			StrEqual(weapon, "saxxy") ||
			StrEqual(weapon, "eviction_notice") ||
			StrEqual(weapon, "disciplinary_action") ||
			StrEqual(weapon, "atomizer") ||
			StrEqual(weapon, "scout_sword") ||
			StrEqual(weapon, "mailbox") ||
			StrEqual(weapon, "big_earner") ||
			StrEqual(weapon, "the_maul") ||
			StrEqual(weapon, "nonnonviolent_protest") ||
			StrEqual(weapon, "nessieclub") ||
			StrEqual(weapon, "unarmed_combat") ||
			StrEqual(weapon, "voodoo_pin") ||
			StrEqual(weapon, "apocofists") ||
			StrEqual(weapon, "eureka_effect") ||
			StrEqual(weapon, "thirddegree") ||
			StrEqual(weapon, "scotland_shard") ||
			StrEqual(weapon, "sharp_dresser") ||
			StrEqual(weapon, "wrap_assassin") ||
			StrEqual(weapon, "spy_cicle") ||
			StrEqual(weapon, "holiday_punch") ||
			StrEqual(weapon, "black_rose") ||
			StrEqual(weapon, "lollichop") ||
			StrEqual(weapon, "unique_pickaxe_escape") ||
			StrEqual(weapon, "freedom_staff") ||
			// Weapon names
			StrEqual(weapon, "tf_weapon_bat") ||
			StrEqual(weapon, "tf_weapon_bat_wood") ||
			StrEqual(weapon, "tf_weapon_bat_fish") ||
			StrEqual(weapon, "tf_weapon_shovel") ||
			StrEqual(weapon, "saxxy") ||
			StrEqual(weapon, "tf_weapon_bat_giftwrap") ||
			StrEqual(weapon, "tf_weapon_fireaxe") ||
			StrEqual(weapon, "tf_weapon_sword") ||
			StrEqual(weapon, "tf_weapon_bottle") ||
			StrEqual(weapon, "tf_weapon_stickbomb") ||
			StrEqual(weapon, "tf_weapon_katana") ||
			StrEqual(weapon, "tf_weapon_fists") ||
			StrEqual(weapon, "tf_weapon_wrench") ||
			StrEqual(weapon, "tf_weapon_robot_arm") ||
			StrEqual(weapon, "tf_weapon_bonesaw") ||
			StrEqual(weapon, "tf_weapon_club") ||
			StrEqual(weapon, "tf_weapon_knife")
			);
	//return false;
}

 //=======================================================================
//                                 TF2 Stocks
//=======================================================================

//	new days=RoundToFloor(time/86400.0);
//	new hours=RoundToFloor((time % 86400 )/3600.0) ;
//	new minutes=RoundToFloor((time % 86400 % 3600) / 60.0);
//	new seconds=time % 86400 % 3600 % 60;
/*
stock sb_seconds(time) {
	return time % 86400 % 3600 % 60;
}
stock sb_minutes(time) {
	return RoundToFloor((time % 86400 % 3600) / 60.0);
}
stock sb_hours(time) {
	return RoundToFloor((time % 86400 )/3600.0);
}
stock sb_days(time) {
	return RoundToFloor(time/86400.0);
}*/
stock bool:SB_SetHealth(entity, health)
{
	new currenthp = GetEntProp(entity, Prop_Data, "m_iHealth");

	if (currenthp == health)
	{
		return false;
	}

	SetEntProp(entity, Prop_Data, "m_iHealth", health);
	ChangeEdictState(entity, 0);

	if (currenthp < health)
	{
		return true;
	}

	return false;
}

new ignoreClient;
public bool:AimTargetFilter(entity,contentsMask)
{
	return !(entity==ignoreClient);
}

stock bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(SB_ValidPlayer(entityhit)&&SB_ValidPlayer(data)&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}

//SB_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0,Function:FilterFunction=INVALID_FUNCTION,SkillID=0);

stock SB_GetTargetInViewCone(client,Float:max_distance=0.0,bool:include_friendlys=false,Float:cone_angle=23.0)
{
	if(SB_ValidPlayer(client))
	{
		if(max_distance<0.0)	max_distance=0.0;
		if(cone_angle<0.0)	cone_angle=0.0;

		new Float:PlayerEyePos[3];
		new Float:PlayerAimAngles[3];
		new Float:PlayerToTargetVec[3];
		new Float:OtherPlayerPos[3];
		GetClientEyePosition(client,PlayerEyePos);
		GetClientEyeAngles(client,PlayerAimAngles);
		new Float:ThisAngle;
		new Float:playerDistance;
		new Float:PlayerAimVector[3];
		GetAngleVectors(PlayerAimAngles,PlayerAimVector,NULL_VECTOR,NULL_VECTOR);
		new bestTarget=0;
		new Float:bestTargetDistance;
		//new PreviousTarget=bestTarget;
		//new Float:PreviousTargetDistance=bestTargetDistance;

		for(new i=1;i<=MaxClients;i++)
		{
			if(cone_angle<=0.0)	break;
			if(SB_ValidPlayer(i,true)&& client!=i)
			{
				if(!include_friendlys && GetClientTeam(client) == GetClientTeam(i))
				{
					continue;
				}
				GetClientEyePosition(i,OtherPlayerPos);
				playerDistance = GetVectorDistance(PlayerEyePos,OtherPlayerPos);
				if(max_distance>0.0 && playerDistance>max_distance)
				{
					continue;
				}
				SubtractVectors(OtherPlayerPos,PlayerEyePos,PlayerToTargetVec);
				ThisAngle=ArcCosine(GetVectorDotProduct(PlayerAimVector,PlayerToTargetVec)/(GetVectorLength(PlayerAimVector)*GetVectorLength(PlayerToTargetVec)));
				ThisAngle=ThisAngle*360/2/3.14159265;
				//PreviousTarget=bestTarget;
				//PreviousTargetDistance=bestTargetDistance;
				if(ThisAngle<=cone_angle)
				{
					ignoreClient=client;
					TR_TraceRayFilter(PlayerEyePos,OtherPlayerPos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
					if(TR_DidHit())
					{
						new entity=TR_GetEntityIndex();
						if(entity!=i)
						{
							continue;
						}
					}
					if(bestTarget>0)
					{
						if(playerDistance<bestTargetDistance)
						{
							bestTarget=i;
							bestTargetDistance=playerDistance;
						}
					}
					else
					{
						bestTarget=i;
						bestTargetDistance=playerDistance;
					}
				}
			}
		}
		if(bestTarget==0) //still no target, use direct trace
		{
			new Float:endpos[3];
			if(max_distance>0.0){
				ScaleVector(PlayerAimVector,max_distance);
			}
			else{

				ScaleVector(PlayerAimVector,56756.0);
				AddVectors(PlayerEyePos,PlayerAimVector,endpos);
				TR_TraceRayFilter(PlayerEyePos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
				if(TR_DidHit())
				{
					new entity=TR_GetEntityIndex();
					if(entity>0 && entity<=MaxClients && IsClientConnected(entity) && IsPlayerAlive(entity) && GetClientTeam(client)!=GetClientTeam(entity) )
					{
						bestTarget=entity;
					}
				}
			}
		}
		return bestTarget;
	}
	return 0;
}

stock bool:Spying(client)
{
	// Can a class really be disguised if not SPY?  or cloaked if not spy??
	if(TF2_GetPlayerClass(client)==TFClass_Spy)
	{
		return (TF2_IsPlayerInCondition(client,TFCond_Disguising)||TF2_IsPlayerInCondition(client,TFCond_Disguised) || TF2_IsPlayerInCondition(client,TFCond_Cloaked));
	}
	return false;
}


stock SB_IsUbered(client)
{
	new m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond") ;
	new cond = GetEntData(client, m_nPlayerCond);
	if(cond & 32)
	{
		return true;
	}
	return false;
}

stock Float:TF2_GetClassSpeed(TFClassType:class)
{
		switch (class)
		{
				case TFClass_Scout:     return 400.0;
				case TFClass_Soldier:   return 240.0;
				case TFClass_DemoMan:   return 280.0;
				case TFClass_Medic:     return 320.0;
				case TFClass_Pyro:      return 300.0;
				case TFClass_Spy:       return 300.0;
				case TFClass_Engineer:  return 300.0;
				case TFClass_Sniper:    return 300.0;
				case TFClass_Heavy:     return 230.0;
		}
		return 0.0;
}
stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if( client > 0 )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}
stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if( StrEqual(classname, "CWeaponMedigun") )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}
stock TF_SetUberLevel(client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}
stock Float:TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100.0;
	else
		return 0.0;
}
stock TF_SetCloakLevel(client, Float:cloaklevel)
{
	//new index = GetPlayerWeaponSlot(client, 1);
	//if (index > 0)
	if (VValidPlayer(client))
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloaklevel);
}
stock Float:TF_GetCloakLevel(client)
{
	//new index = GetPlayerWeaponSlot(client, 1);
	if (VValidPlayer(client))
		return GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	else
		return 0.0;
}

/**
 * Prints a message in the chat area with [SmashBros] pre-appended.
 * Support color tags: {default}, {green}, {lightgreen}, {red}, {blue}, {olive}.
 *
 * @param client      Client index, pass 0 for message to all.
 * @param szMessage   Message (formatting rules).
 * @return            No return
 */
stock SB_ChatMessage(client, const String:szMessage[], any:...)
{
	if (client == 0)
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
				Format(szBuffer, sizeof(szBuffer), "{green}[%s]{default} %s", GAME_TITLE, szBuffer);
				CPrintToChat(i, szBuffer);
			}
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
		Format(szBuffer, sizeof(szBuffer), "{green}[%s]{default} %s", GAME_TITLE, szBuffer);
		CPrintToChat(client, szBuffer);
	}
}

stock bool:SB_IS_PLAYER(x)
{
	if(x>0&&x<=MaxClients)
	return true;
	return false;
}

stock SB_DP(const String:szMessage[], any:...)
{

	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
	PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);

}

stock bool SB_FakeKillFeed_TEST(int victim, int attacker, bool bfirstblood)
{
	if(attacker > 32 || attacker <=0) attacker = victim;
	new Handle:event = CreateEvent("player_death");
	SetEventBool(event, "sourcemod", true);							//claims sourcemod based event
	if(!attacker)
	{
		new String:cAssister[64];
		new String:arg3[64];
		//GetClientName(attacker,STRING(arg3));
		Format(cAssister, sizeof(cAssister), "d%s", arg3);
		SetEventString(event, "assister_fallback", cAssister);
	}
	else
	{
		new String:cAssister[64];
		new String:arg3[64];
		GetClientName(attacker,STRING(arg3));
		Format(cAssister, sizeof(cAssister), "b%s", arg3);
		SetEventString(event, "assister_fallback", cAssister);
		SetEventInt(event, "attacker", GetClientUserId(attacker));
	}
	SetEventInt(event, "userid", GetClientUserId(victim));
	int deathFlags;
	if(bfirstblood)
	{
		deathFlags += TF_DEATHFLAG_FIRSTBLOOD;
	}
	SetEventInt(event, "death_flags", deathFlags);
	FireEvent(event);
}

stock bool SB_FakeKillFeed(int victim, int attacker, int assister=0, int inflictor_entindex=0, bool headshot=false)
{
	//environmental_death player_death
	Handle fakeEvent = CreateEvent("player_death", true);
	if (fakeEvent != null) // event succeed!
	{
		//char sWeapon[32];
		if(attacker > 32 || attacker <=0) attacker = victim;

		PrintToChatAll("victim %d, attacker %d",victim,attacker);

		//GetClientWeapon(attacker, STRING(sWeapon));

/*		This code is for reference only and do not use here

		This code is for capture in player_death capturing events:

		We should not trigger event_player_death related things if it was an event fired by sourcemod or if it is a deadringer (fake) death.
		stock bool:IsValidEventDeath(Handle:hEvent)
		{
		    return !( (GetEventBool(hEvent, "sourcemod") || (GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER)) );
		}
*/
		SetEventBool(fakeEvent, "sourcemod", true);							//claims sourcemod based event

		SetEventInt(fakeEvent, "userid", GetClientUserId(victim)); 								//user ID who died
		PrintToChatAll("userid %d",GetClientUserId(victim));

		SetEventInt(fakeEvent, "victim_entindex", victim);
		PrintToChatAll("victim_entindex %d",victim);


		SetEventInt(fakeEvent, "assister", -1);
		SetEventInt(fakeEvent, "kill_streak_total", 1);
		SetEventInt(fakeEvent, "kill_streak_wep", 1);
		SetEventInt(fakeEvent, "attacker", GetClientUserId(attacker)); 							//user ID who killed
		SetEventInt(fakeEvent, "inflictor_entindex", attacker); 		//ent index of inflictor (a sentry, for example)
		SetEventBool(fakeEvent, "silent_kill", true);

		/*
		if(assister)
		{
			SetEventInt(fakeEvent, "assister", GetClientUserId(assister)); 							//user ID of assister
			PrintToChatAll("assister %d",GetClientUserId(assister));
		}
		else
		{
			SetEventInt(fakeEvent, "assister", -1); 							//user ID of assister
			PrintToChatAll("assister -1");
		}*/

		/*
		SetEventInt(fakeEvent, "attacker", GetClientUserId(attacker)); 							//user ID who killed
		PrintToChatAll("attacker %d",GetClientUserId(attacker));

		if(inflictor_entindex <= 0) inflictor_entindex = attacker;
		if(inflictor_entindex)
		{
			SetEventInt(fakeEvent, "inflictor_entindex", inflictor_entindex); 		//ent index of inflictor (a sentry, for example)
			PrintToChatAll("inflictor_entindex %d",inflictor_entindex);
		}*/

		//SetEventInt(fakeEvent, "weapon_def_index", 13);

		//SetEventString(fakeEvent, "weapon", "world");
		//SetEventInt(fakeEvent, "customkill", TF_CUSTOM_SUICIDE );
		//SetEventString( fakeEvent, "weapon_logclassname", "world" );
		//SetEventInt(fakeEvent, "death_flags", TF_DEATHFLAG_KILLERDOMINATION );

		/*
		SetEventString(fakeEvent, "weapon", sWeapon); 											//weapon name killer used
		PrintToChatAll("weapon %s",sWeapon);
		SetEventString(fakeEvent, "weapon_logclassname", sWeapon); 								//weapon name that should be printed on the log
		PrintToChatAll("weapon_logclassname %s",sWeapon);
		*/

		//SetEventBool(fakeEvent, "headshot", headshot);
		//PrintToChatAll("headshot %s",headshot?"true":"false");
		//SetEventBool(fakeEvent, "silent_kill", false);
		//PrintToChatAll("heasilent_kill false");

		FireEvent(fakeEvent);
		return true;
	}
	//PrintToChatAll("Event Failed");
	return false;
}

// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS

//when player spawns, fires only in SB mode
forward OnSB_EventSpawn(client);

// Fires after EventSpawn
forward OnSB_EventSpawn_Post(client);


//when player dies, fires only in SB mode
//Distance in feet
//forward OnSBEventDeath(victim, attacker, distance, attacker_hpleft, String:weapon[32]);
//forward OnSB_EventDeath(victim, attacker, distance, attacker_hpleft);
forward void OnSB_EventDeath(int victim, int attacker, int assister, int distance, int attacker_hpleft, Handle event);

//very generic damage event
//derrived from the game engine's posthurt event
//FRIENDLY FIRE IS NOT FILTERED
forward OnSBEventPostHurt(victim,attacker,dmgamount,const String:weapon[32]);


//=============================================================================
// Fowards
//=============================================================================

/**
 * Called when a an entity takes damage, requires SDK Hooks until SM natively supports this.
 * @param victim: Victim entity.
 * @param attacker: Attacker entity.
 * @param damage: How much damage is done.
 * @noreturn
 *
 * order of execution is
 * damageallpre
 * bulletpre (if bullet)
 * damageall
 * bullet  (if bullet)
 */
//FF triggers this function!!! even though it didnt damage any teammate
//THIS is a theoretical damage given by the engine, if u want real damage dealt use the hurt-event
//use natives to retrieve inflictor and game damagetype
//becareful when using this, u should only use this to reduce incoming damage. if you want to return damge, only use on bullet (first trigger damage)(below) or check IsBullet
//you may set damage mod percent HERE
//you may NOT DAMAGE IN HERE
forward OnSB_TakeDmgAllPre(victim,attacker,Float:damage,damagecustom);

//you may NOT set damage mod percent HERE
//you may DAMAGE in here, however damage will be engine theoretical damage, not actual damage dealt
forward OnSB_TakeDmgAll(victim,attacker,Float:damage);


forward OnSB_RoundEnd();

forward OnSB_SpawnPlayer(int client);



stock void CalculateTeamScores(int &RedTeam, int &BlueTeam)
{
	int TheLives = 0;

	for(int i=1;i<MaxClients;i++)
	{
		if(SB_ValidPlayer(i,true))
		{
			TheLives = SB_GetPlayerProp(i,iLives);
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
