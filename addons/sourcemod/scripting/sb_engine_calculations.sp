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
#include <sdkhooks>

public Plugin:myinfo = {
	name = "Smash Bros Calculations Engine",
	author = "El Diablo",
	description = "SB Core Plugins",
	version = PLUGIN_VERSION,
	url = "www.war3evo.info"
}

int LastValidAttacker[MAXPLAYERSCUSTOM];
bool firstblood = false;

Handle sb_angles;
Handle sb_upward_force;

float g_fsb_angles;
float g_fsb_upward_force;

public OnPluginStart()
{
	HookEvent("teamplay_round_start", teamplay_round_active);
	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("arena_round_start", teamplay_round_active);

	RegConsoleCmd("allowengineering",SB_ENGINEERING,"allowengineering");

	sb_angles = CreateConVar("sb_angles", "50.0", "Advanced options", FCVAR_PLUGIN);
	g_fsb_angles = GetConVarFloat(sb_angles);

	sb_upward_force= CreateConVar("sb_upward_force", "1.5", "Advanced options", FCVAR_PLUGIN);
	g_fsb_upward_force = GetConVarFloat(sb_upward_force);

	HookConVarChange(sb_angles, OnConVarChange);
	HookConVarChange(sb_upward_force, OnConVarChange);

	//HookEvent("player_healed", Event_player_healed);

	HookEvent("player_builtobject", Event_Player_BuiltObject, EventHookMode_Pre);

	//HookEvent("player_healedbymedic", Event_player_healedbymedic, EventHookMode_Post);
	HookEvent("player_healonhit", Event_player_healonhit, EventHookMode_Post);
	//HookEvent("player_healed", Event_player_healed, EventHookMode_Post);

	AddCommandListener(Command_InterceptSuicide, "kill");
	AddCommandListener(Command_InterceptSuicide, "explode");

	CreateTimer(0.2, Timer_Uber_Regen, _, TIMER_REPEAT);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == sb_angles)
		g_fsb_angles = GetConVarFloat(sb_angles);
	else if(hConvar == sb_upward_force)
		g_fsb_upward_force = GetConVarFloat(sb_upward_force);
}

public Action Command_InterceptSuicide(int client, char[] command, int args)
{
	if(!SB_ValidPlayer(client,true) || !SB_GetGamePlaying())
	{
		return Plugin_Continue;
	}

	// Player used "kill" or "explode"

	// Suicide attempt was intercepted
	if(FakeDeath(client,client))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

//CreateTimer(1.2,instaspawn,victim);
/*
public Action:instaspawn(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client))
	{
		//TF2_RespawnPlayer(client);
		SDKCall(hSpawnPlayer,client);
	}
}*/

public bool FakeDeath(int victim, int attacker)
{
	if(SB_ValidPlayer(victim))
	{
		if(SB_GetPlayerProp(victim,iLives)>1)
		{
			SB_SetPlayerProp(victim,iLives,SB_GetPlayerProp(victim,iLives)-1);
			//CreateTimer(3.0,instaspawn,victim);

			int RedTeam, BlueTeam;
			CalculateTeamScores(RedTeam,BlueTeam);

			// fake death
			if(GetConVarBool(FindConVar("sb_chatmsg")))
			{
				SB_ChatMessage(0,"{default}[{yellow}Total Lives{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",RedTeam,BlueTeam);
			}

			SB_SpawnPlayer(victim);

			//PrintToChatAll("fake death start");
			//PrintToChatAll("victim = %d, attacker = %d",victim, attacker);
			/*
			Handle pack;
			if(CreateDataTimer(0.1,FakeKillFeedTimer,pack) != null)
			{
				WritePackCell(pack, victim);			// the hacker
				WritePackCell(pack, attacker);			// The Sentry Owner
			}*/
			if(attacker > 32)
			{
				if(attacker!=victim && LastValidAttacker[victim]>0)
				{
					attacker = LastValidAttacker[victim];
				}
				else
				{
					attacker = victim;
				}
			}
			if(!firstblood) firstblood=true;
			SB_FakeKillFeed_TEST(victim, attacker, firstblood);
			LastValidAttacker[victim]=0;
			//PrintToChatAll("fake death end");

			return true;
		}
	}
	return false;
}

public OnSB_TakeDmgAllPre(int victim, int attacker, float damage, int damagecustom)
{
	if(!SB_GetGamePlaying())
	{
		SB_DamageModPercent(0.0);
		return;
	}

	if(damage>0.0 && (attacker > 0 && attacker < 33))
	{
		LastValidAttacker[victim]=attacker;
	}

	bool DamageHandled = false;

	/*
	int inflictor = SB_GetDamageInflictor();

	if(attacker!=inflictor)
	{
		if(inflictor>0 && IsValidEdict(inflictor))
		{
			char ent_name[64];
			GetEdictClassname(inflictor,ent_name,64);
			//	DP("ent name %s",ent_name);
			if(StrContains(ent_name,"tf_projectile_rocket",false)==0)
			{
				SB_DP("tf_projectile_rocket");
				return;
			}
		}
	}*/

	//new passcheck = 0;

	//SB_DP("victim %d attacker %d damage %.2f",victim,attacker,damage);
	//SB_DP("SB_GetDamageType %d",SB_GetDamageType());
	//SB_DP("SB_GetDamageInflictor %d",SB_GetDamageInflictor());

	if(SB_GetDamageType()==DMG_CRUSH)
	{
		SB_DP("DMG_CRUSH");
	}

	//new iItemDefinitionIndex = GetEntProp(SB_GetDamageInflictor(), Prop_Send, "m_iItemDefinitionIndex");

	//else if(SB_GetDamageType()==DMG_CRUSH)
	//{
		//SB_DP("DMG_CRUSH");
	//}

	/*
	if(!(GetEntityFlags(victim) & FL_ONGROUND))
	{
		if(SB_GetPlayerProp(victim,iDamage)>10000)
		{
			//ForcePlayerSuicide(victim);
			//SDKHooks_TakeDamage(victim, 0, 0, 999999.9, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR);
			int pointHurt=CreateEntityByName("point_hurt");
			if(pointHurt)
			{
				DispatchKeyValue(victim,"targetname","sb_hurtme"); //set victim as the target for damage
				DispatchKeyValue(pointHurt,"Damagetarget","sb_hurtme");
				DispatchKeyValue(pointHurt,"Damage","99999");
				DispatchKeyValue(pointHurt,"DamageType","32");
				DispatchKeyValue(pointHurt,"classname","sb_point_hurt");
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt,"Hurt",-1);
				DispatchKeyValue(victim,"targetname","sb_donthurtme"); //unset the victim as target for damage
				RemoveEdict(pointHurt);
			}

			return;
		}
	}*/

	bool DamageCustom = false;
	int customdamage = 0;

	switch (damagecustom)
	{
		case TF_CUSTOM_TAUNT_HADOUKEN, TF_CUSTOM_TAUNT_HIGH_NOON, TF_CUSTOM_TAUNT_GRAND_SLAM, TF_CUSTOM_TAUNT_FENCING,
		TF_CUSTOM_TAUNT_ARROW_STAB, TF_CUSTOM_TAUNT_GRENADE, TF_CUSTOM_TAUNT_BARBARIAN_SWING,
		TF_CUSTOM_TAUNT_UBERSLICE, TF_CUSTOM_TAUNT_ENGINEER_SMASH, TF_CUSTOM_TAUNT_ENGINEER_ARM, TF_CUSTOM_TAUNT_ARMAGEDDON:
		{
			DamageHandled = true;
			DamageCustom = true;
			SB_DamageModPercent(0.0);
		}
	}

	switch (damagecustom)
	{
		case TF_CUSTOM_BACKSTAB, TF_CUSTOM_HEADSHOT:
		{
			DamageHandled = true;
			DamageCustom = true;
			customdamage = 100;
			SB_DamageModPercent(0.0);
		}
	}

	if(SB_ValidPlayer(attacker) && attacker == victim)
	{
		int currentwpn = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		// boston basher
		if(currentwpn > MaxClients && GetEntProp(currentwpn, Prop_Send, "m_iItemDefinitionIndex")==325)
		{
			//SB_DP("boston basher");
			SB_DamageModPercent(0.0);
			return;
		}
	}

	/*
	if(attacker==victim && SB_GetDamageInflictor()>MaxClients)
	{
		int iItemDefinitionIndex = GetEntProp(SB_GetDamageInflictor(), Prop_Send, "m_iItemDefinitionIndex");
		if(iItemDefinitionIndex == 325)
		{
			//SB_DP("iItemDefinitionIndex %d",iItemDefinitionIndex);
			//SB_DP("iItemDefinitionIndex 0.0");
			SB_DamageModPercent(0.0);
			return;
		}
	}*/

	if(SB_ValidPlayer(victim) && SB_GetDamageType()==DMG_FALL)
	{
		//SB_DP("FALL DAMAGE");
		//new newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		//SB_SetPlayerProp(victim,iDamage,newdamage);
		if(GetEntityFlags(victim) & FL_ONGROUND)
		{
			//SB_DP("victim & DMG_FALL 0.0");
			SB_DamageModPercent(0.0);
			//passcheck++;
			return;
		}
	}

	//SB_DP("victim & DMG_FALL pass");

	//else if(SB_ValidPlayer(attacker) && attacker==victim)
	//{
		//if(iItemDefinitionIndex != 325)
		//{
		//new newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		//SB_SetPlayerProp(victim,iDamage,newdamage);
		//}
		//SB_DP("valid attacker 0.0");
		//SB_DamageModPercent(0.0);
		//passcheck++;
	//}
	else if(SB_ValidPlayer(attacker) && SB_ValidPlayer(victim) && (GetClientTeam(attacker) != GetClientTeam(victim)))
	{
		//if(iItemDefinitionIndex != 325)
		//{
		if(!DamageCustom)
		{
			int newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
			SB_SetPlayerProp(victim,iDamage,newdamage);
			SB_DamageModPercent(0.01);
		}
		else
		{
			int newdamage = (SB_GetPlayerProp(victim,iDamage) + customdamage);
			SB_SetPlayerProp(victim,iDamage,newdamage);
		}
		//}
		//SB_DP("valid attacker 0.0");
		//passcheck++;
	}
	/*
	else if(SB_ValidPlayer(attacker) && attacker==victim)
	{
		//if(iItemDefinitionIndex != 325)
		//{
		new newdamage = (SB_GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		SB_SetPlayerProp(victim,iDamage,newdamage);
		//}
		//SB_DP("valid attacker 0.0");
		SB_DamageModPercent(0.01);
		//passcheck++;
	}*/

	//SB_DP("valid attacker pass");

	if(SB_ValidPlayer(victim))
	{
		new Float:vec[3];
		GetClientAbsOrigin(victim, vec);
		if(TR_PointOutsideWorld(vec))
		{
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			SB_DP("OUT SIDE OF MAP");
			// allow to kill
			//ForcePlayerSuicide(victim);
			//SDKHooks_TakeDamage(victim, 0, 0, 999999.9, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR);
		}
	}
	//SB_DP("iItemDefinitionIndex pass");

	if(SB_ValidPlayer(victim))
	{
		if(!DamageHandled && RoundToCeil(damage)>GetClientHealth(victim))
		{
			if(SB_GetPlayerProp(victim,iLives)>1)
			{
				SB_DamageModPercent(0.0);
				FakeDeath(victim, attacker);
			}
		}
	}
}

public OnSBEventPostHurt(victim,attacker,dmgamount,const String:weapon[32])
{
	if(SB_ValidPlayer(victim,true) && SB_ValidPlayer(attacker))
	{
		int inflictor = SB_GetDamageInflictor();

		//SB_DP("OnSBEventPostHurt weapon name %s",weapon);

		if(StrEqual(weapon,"tf_weapon_bat"))
		{
			int currentwpn = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			// boston basher
			if(currentwpn > MaxClients && GetEntProp(currentwpn, Prop_Send, "m_iItemDefinitionIndex")==325)
			{
				//SB_DP("boston basher");
				return;
			}
		}

		if(attacker!=inflictor && (GetClientTeam(attacker) == GetClientTeam(victim)))
		{
			if(inflictor>0 && IsValidEdict(inflictor))
			{
				char ent_name[64];
				GetEdictClassname(inflictor,ent_name,64);
				//SB_DP("ent name %s",ent_name);
				if(StrContains(ent_name,"tf_projectile_rocket",false)==0)
				{
					new owner = GetEntPropEnt(inflictor, Prop_Data, "m_hOwnerEntity");
					if(attacker==owner)
					{
						new MaxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
						SB_SetHealth(victim, MaxHealth);

						//SB_DP("projectile rocket post hurt");
						return;
					}
				}
			}
		}
		//new iItemDefinitionIndex = GetEntProp(SB_GetDamageInflictor(), Prop_Send, "m_iItemDefinitionIndex");
		//SB_DP("iItemDefinitionIndex %d",iItemDefinitionIndex);
		//if(iItemDefinitionIndex != 325)
		//{
		//new newdamage = (SB_GetPlayerProp(victim,iDamage) + dmgamount);
		//SB_SetPlayerProp(victim,iDamage,newdamage);

		//new Float:totaldamage = float(newdamage)*4;

		//bool PlayerIsOnFire = TF2_IsPlayerInCondition(victim, TFCond_OnFire);

		if(TF2_IsPlayerInCondition(victim, TFCond_OnFire))
		{
			ExtinguishEntity(victim);
			TF2_RemoveCondition(victim, TFCond_OnFire);
		}

		float totaldamage;

		/*
		if(PlayerIsOnFire)
		{
			totaldamage = FloatDiv(float(SB_GetPlayerProp(victim,iDamage)),0.5);
		}
		else
		{*/
		//totaldamage = FloatMul(float(SB_GetPlayerProp(victim,iDamage)),6.0);
		totaldamage = FloatMul(float(SB_GetPlayerProp(victim,iDamage)),3.0);
		//}

		new MaxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		SB_SetHealth(victim, MaxHealth);
		//new Float:stren = FloatMul(float(totaldamage),0.1);
		//new Float:stren = float(dmgamount);

		//if(TF2_GetPlayerClass(attacker)==TFClass_Scout)
		//{
			//SB_DP("scout damage %.2f",totaldamage);
		//}

		if(totaldamage)
		{
			//SB_DP("totaldamage %.2f",totaldamage);
			new Float:vAngles[3], Float:vReturn[3];
			//Since m_angEyeAngles or m_angEyeAngles[0] works, I am using the harsh number
			GetClientEyeAngles(attacker, vAngles);

			//if(PlayerIsOnFire)
			//{
				//vAngles[0] = 89.0;
			//}
			vAngles[0] = g_fsb_angles; //50.0

			vReturn[0] = FloatMul( Cosine( DegToRad(vAngles[1])  ) , totaldamage);
			vReturn[1] = FloatMul( Sine( DegToRad(vAngles[1])  ) , totaldamage);
			vReturn[2] = FloatMul( Sine( DegToRad(vAngles[0])  ) , FloatMul(totaldamage,g_fsb_upward_force)); //upward force 1.5

			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vReturn);
		}
		//}
	}
}

public Action OnSB_EventSpawn(client)
{
	if(SB_ValidPlayer(client))
	{
		SB_SetPlayerProp(client,iDamage,0);
		//SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
		SpawnProtect(client);
	}
	return Plugin_Continue;
}

/*
public void OnSB_EventDeath(int victim, int attacker, int assister, int distance, int attacker_hpleft, Handle event)
{
	if(SB_ValidPlayer(victim))
	{
		if(SB_GetPlayerProp(victim,iLives)>0)
		{
			SB_SetPlayerProp(victim,iLives,SB_GetPlayerProp(victim,iLives)-1);
			CreateTimer(3.0,instaspawn,victim);
		}
		//SDKUnhook(victim,SDKHook_OnTakeDamage,OnTakeDamage);
	}
}*/

public Action:Timer_Uber_Regen(Handle:timer, any:user)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (!SB_ValidPlayer(i,true,true))
		{
			continue;	// Client isnt valid
		}

		if(TF2_GetPlayerClass(i) != TFClass_Medic)
		{
			continue;
		}

		new HealVictim = TF2_GetHealingTarget(i);
		//if (ValidPlayer(HealVictim, true) && !SB_IsUbered(healer))
		if (SB_ValidPlayer(HealVictim, true))
		{
			//SB_DP("healer %d ... healer victim %d",i,HealVictim);
			if(SB_GetPlayerProp(HealVictim,iDamage)>0)
			{
				new NewDamage = SB_GetPlayerProp(HealVictim,iDamage)-1;
				if(TF2_IsPlayerInCondition(i, TFCond_MegaHeal))
				{
					NewDamage -= 1;
				}
				if(NewDamage<0) NewDamage = 0;
				SB_SetPlayerProp(HealVictim,iDamage,NewDamage);
			}
		}

		/*
		if(SB_GetPlayerProp(i,iDamage)>10000)
		{
			if(SB_ValidPlayer(i,true,true))
			{
				//ForcePlayerSuicide(i);
				SDKHooks_TakeDamage(i, 0, 0, 999999.9, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR);
			}
		}*/
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Bleeding))
	{
		TF2_RemoveCondition(client, TFCond_Bleeding);
		new MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		SB_SetHealth(client, MaxHealth);
	}
}

public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(SB_ValidPlayer(client,true))
	{
		new index = GetEventInt(event, "index");

		new String:classname[32];
		GetEdictClassname(index, classname, sizeof(classname));

		if( strcmp("obj_sentrygun", classname ) == 0 )
		{
			//if(GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel")==3 && GetEntProp(index, Prop_Send, "m_bMiniBuilding") == 1 )
			//{
			SetEntPropFloat(index, Prop_Send, "m_flModelScale",1.0);
			SetEntProp(index, Prop_Send, "m_bMiniBuilding",1);
			//SetEntProp(index, Prop_Send, "m_bBuilding",0);
			SetEntProp(index, Prop_Send, "m_iHealth", 200);
			SetEntProp(index, Prop_Send, "m_iMaxHealth", 200);

			static Float:g_fSentryMaxs[] = {9.0, 9.0, 29.7};
			SetEntPropVector(index, Prop_Send, "m_vecMaxs", g_fSentryMaxs);

			new OldMetal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), OldMetal+30, 4, true);
			new Metal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
			if(Metal>200)
				SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 200, 4, true);
			//}
			if((GetEntProp(index, Prop_Send, "m_bBuilding") == 1 ))
				SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 1);
			//SB_CooldownMGR(client,UpgradeSentryCooldowns[skill_level],thisRaceID,ABILITY_UPGRADE_SENTRY,true,true);

			CreateTimer(1.0, SkinFix, index);
		}
	}
	return Plugin_Continue;
}
public Action:SkinFix(Handle:timer, any:sentry)
{
	new String:classname[32];

	if(!IsValidEntity(sentry) || sentry <= 32 ) return Plugin_Continue;

	if(GetEntityClassname(sentry, classname, sizeof(classname)) && StrEqual(classname, "obj_sentrygun", false))
	{
		if((GetEntProp(sentry, Prop_Send, "m_bPlacing") == 0))
		{
			new client = GetEntDataEnt2(sentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
			if(!IsValidClient(client)) return Plugin_Continue;

			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(client)-2);
		}
	}

	return Plugin_Continue;
}
stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}



public Action:teamplay_round_active(Handle:event,  const String:name[], bool:dontBroadcast)
{
	firstblood=false;
	CreateTimer(1.0,RemoveStuff,0);
}

public Action:RemoveStuff(Handle:t,any:data)
{
	int i = -1;
	while((i = FindEntityByClassname(i,"func_nobuild")) != -1)
	{
		if(IsValidEntity(i))
		{
			AcceptEntityInput( i,"Kill");
		}
	}
	i = -1;
	while((i = FindEntityByClassname(i,"func_respawnroom")) != -1)
	{
		if(IsValidEntity(i))
		{
			AcceptEntityInput( i,"Kill");
		}
	}
}

public Action:SB_ENGINEERING(client,args)
{
	CreateTimer(0.1,RemoveStuff,0);
}

public SpawnProtect(client)
{
	if(SB_ValidPlayer(client,true))
	{
		TF2_AddCondition(client, TFCond_Ubercharged, 5.0);
	}
}


public Event_player_healonhit(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "entindex"));

	if(SB_ValidPlayer(client))
	{
		if(SB_GetPlayerProp(client,iDamage)>0)
		{
			int CurrentDamage = SB_GetPlayerProp(client,iDamage);
			//int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.50));
			CurrentDamage -= 10;
			if(CurrentDamage<0) CurrentDamage = 0;
			SB_SetPlayerProp(client,iDamage,CurrentDamage);
		}
	}
}
/*
public Action FakeKillFeedTimer(Handle timer, Handle datapack)
{
	PrintToChatAll("FakeKillFeedTimer start");
	ResetPack(datapack);
	PrintToChatAll("ResetPack(datapack)");
	int victim = ReadPackCell(datapack);
	PrintToChatAll("victim = %d", victim);
	int attacker = ReadPackCell(datapack);
	PrintToChatAll("attacker = %d", attacker);
	SB_FakeKillFeed_TEST(victim, attacker);
	PrintToChatAll("FakeKillFeedTimer end");
	return Plugin_Continue;
}
*/

public OnSB_RoundEnd()
{
	new iEnt = -1;
	iEnt = FindEntityByClassname(iEnt, "game_round_win");

	if (iEnt < 1)
	{
		iEnt = CreateEntityByName("game_round_win");
		if (IsValidEntity(iEnt))
			DispatchSpawn(iEnt);
		else
		{
			//ReplyToCommand(client, "Unable to find or create a game_round_win entity!");
			SB_DP("Unable to find or create a game_round_win entity!");
			return;
		}
	}

	int teamred, teamblue;
	CalculateTeamScores(teamred,teamblue);

	int iWinningTeam = 0;

	if(teamred>teamblue)
	{
		iWinningTeam=TEAM_RED;
		if(GetConVarBool(FindConVar("sb_chatmsg")))
		{
			SB_ChatMessage(0,"{default}[{yellow}RED TEAM WINS!{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
		}
	}
	else if(teamred<teamblue)
	{
		iWinningTeam=TEAM_BLUE;
		if(GetConVarBool(FindConVar("sb_chatmsg")))
		{
			SB_ChatMessage(0,"{default}[{yellow}BLUE TEAM WINS!{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
		}
	}
	else
	{
		if(GetConVarBool(FindConVar("sb_chatmsg")))
		{
			SB_ChatMessage(0,"{default}[{yellow}STALEMATE!{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",teamred,teamblue);
		}
	}

	SetVariantInt(iWinningTeam);
	AcceptEntityInput(iEnt, "SetTeam");
	AcceptEntityInput(iEnt, "RoundWin");
}

float SpawnLocation[MAXPLAYERS + 1][3];

public OnSB_SpawnPlayer(int client)
{
	if(SB_ValidPlayer(client))
	{
		GetClientAbsOrigin(client, SpawnLocation[client]);
	}
	CreateTimer(0.2, StopPlayerMovement, client);
}

public Action:StopPlayerMovement(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client,true))
	{
		if(SpawnLocation[client][0]!= 0.0
		&& SpawnLocation[client][1]!= 0.0
		&& SpawnLocation[client][2]!= 0.0)
		{
			TeleportEntity(client, SpawnLocation[client], NULL_VECTOR, NULL_VECTOR);
			SpawnLocation[client][0]!= 0.0;
			SpawnLocation[client][1]!= 0.0;
			SpawnLocation[client][2]!= 0.0;
		}
	}
}

