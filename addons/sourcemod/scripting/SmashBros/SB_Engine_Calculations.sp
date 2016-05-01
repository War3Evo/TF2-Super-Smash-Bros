//SB_Engine_Calculations.sp


#define MAXHEALTHCHECK 500

public SB_Engine_Calculations_SB_001_HookEvent()
{
	HookEvent("player_builtobject", Event_Player_BuiltObject, EventHookMode_Pre);
	HookEvent("player_healonhit", Event_player_healonhit, EventHookMode_Post);

	//HookEvent("player_healed", Event_player_healed);
	//HookEvent("player_healedbymedic", Event_player_healedbymedic, EventHookMode_Post);
	//HookEvent("player_healed", Event_player_healed, EventHookMode_Post);
}

public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(SB_ValidPlayer(client,true))
	{
		int index = GetEventInt(event, "index");

		char classname[32];
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

			int OldMetal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), OldMetal+30, 4, true);
			int Metal = GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
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
	char classname[32];

	if(!IsValidEntity(sentry) || sentry <= 32 ) return Plugin_Continue;

	if(GetEntityClassname(sentry, classname, sizeof(classname)) && StrEqual(classname, "obj_sentrygun", false))
	{
		if((GetEntProp(sentry, Prop_Send, "m_bPlacing") == 0))
		{
			int client = GetEntDataEnt2(sentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
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

public Event_player_healonhit(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "entindex"));

	if(SB_ValidPlayer(client))
	{
		if(GetPlayerProp(client,iDamage)>0)
		{
			int CurrentDamage = GetPlayerProp(client,iDamage);
			//int ReduceDamageBy = RoundToFloor(FloatMul(float(CurrentDamage),0.50));
			CurrentDamage -= 10;
			if(CurrentDamage<0) CurrentDamage = 0;
			SetPlayerProp(client,iDamage,CurrentDamage);
		}
	}
}

public SB_Engine_Calculations_OnSBEventPostHurt(victim,attacker,dmgamount,const String:weapon[64])
{
	if(SB_ValidPlayer(victim,true) && SB_ValidPlayer(attacker))
	{
		//int inflictor = SB_GetDamageInflictor();
		int inflictor = g_CurInflictor;

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
					int owner = GetEntPropEnt(inflictor, Prop_Data, "m_hOwnerEntity");
					if(attacker==owner)
					{
						int MaxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
						SB_SetHealth(victim, MaxHealth); //stock from sb_interface.inc

						//SB_DP("projectile rocket post hurt");
						return;
					}
				}
			}
		}
		//new iItemDefinitionIndex = GetEntProp(g_CurInflictor, Prop_Send, "m_iItemDefinitionIndex");
		//SB_DP("iItemDefinitionIndex %d",iItemDefinitionIndex);
		//if(iItemDefinitionIndex != 325)
		//{
		//new newdamage = (GetPlayerProp(victim,iDamage) + dmgamount);
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
			totaldamage = FloatDiv(float(GetPlayerProp(victim,iDamage)),0.5);
		}
		else
		{*/
		//totaldamage = FloatMul(float(GetPlayerProp(victim,iDamage)),6.0);
		totaldamage = FloatMul(float(GetPlayerProp(victim,iDamage)),3.0);
		//}

		int MaxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		SB_SetHealth(victim, MaxHealth); //stock from sb_interface.inc
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


// Must return so that program will wait for it
public bool SB_Engine_Calculations_OnSB_TakeDmgAllPre(int victim, int attacker, float damage, int damagecustom)
{
	if(!playing && bLateLoad)
	{
		int RS = GameRules_GetProp("m_iRoundState");
		if(RS == 7)
		{
			//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre round state %d",RS);
			playing=true;
			bLateLoad=false;
		}
	}
	//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre start");
	if(!playing)
	{
		//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre !playing");
		DamageModPercent(0.0);
		return false;
	}

	if(damage>0.0 && (attacker > 0 && attacker < 33))
	{
		LastValidAttacker[victim]=attacker;
	}

	// help prevent demos from using stickies to keep themselves launched in the air!
	int inflictor = g_CurInflictor;
	if(victim==attacker && inflictor>0 && IsValidEdict(inflictor))
	{
		//tf_projectile_flare
		char ent_name[64];
		GetEdictClassname(inflictor,ent_name,64);
		if (StrEqual(ent_name, "tf_projectile_pipe_remote"))
		{
			//SB_DP("m_bTouched? %s",GetEntProp(inflictor, Prop_Send, "m_bTouched")?"TRUE":"FALSE");
			if(!GetEntProp(inflictor, Prop_Send, "m_bTouched"))
			{
				//SB_DP("!m_bTouched");
				DamageModPercent(0.0);
				return true;
			}
			/*
			if(!(GetEntityFlags(victim) & FL_ONGROUND) && !(GetEntityFlags(inflictor) & FL_ONGROUND))
			{
				//SB_DP("victim %d is not on ground",victim);
				float inflictorPOS[3];
				GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", inflictorPOS);

				float victimPOS[3];
				GetClientAbsOrigin(victim, victimPOS);

				float distancetoentity = GetVectorDistance(victimPOS, inflictorPOS);

				SB_DP("distancetoentity %f",distancetoentity);

				return;
			}*/
		}
	}

	bool DamageHandled = false;

	/*
	int inflictor = g_CurInflictor;

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
	//SB_DP("g_CurInflictor %d",g_CurInflictor);

	//if(SB_GetDamageType()==DMG_CRUSH)
	//{
		//SB_DP("DMG_CRUSH");
	//}

	//new iItemDefinitionIndex = GetEntProp(g_CurInflictor, Prop_Send, "m_iItemDefinitionIndex");

	//else if(SB_GetDamageType()==DMG_CRUSH)
	//{
		//SB_DP("DMG_CRUSH");
	//}

	/*
	if(!(GetEntityFlags(victim) & FL_ONGROUND))
	{
		if(GetPlayerProp(victim,iDamage)>10000)
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
			DamageModPercent(0.0);
			bloodspray(victim);
			//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre NO DAMAGE");
		}
	}

	switch (damagecustom)
	{
		case TF_CUSTOM_BACKSTAB, TF_CUSTOM_HEADSHOT:
		{
			DamageHandled = true;
			DamageCustom = true;
			customdamage = 100;
			DamageModPercent(0.0);
			bloodspray(victim);
			//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre NO DAMAGE");
		}
	}

	if(SB_ValidPlayer(attacker) && attacker == victim)
	{
		int currentwpn = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		// boston basher
		if(currentwpn > MaxClients && GetEntProp(currentwpn, Prop_Send, "m_iItemDefinitionIndex")==325)
		{
			//SB_DP("boston basher");
			DamageModPercent(0.0);
			//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre NO DAMAGE");
			return true;
		}
	}

	/*
	if(attacker==victim && g_CurInflictor>MaxClients)
	{
		int iItemDefinitionIndex = GetEntProp(g_CurInflictor, Prop_Send, "m_iItemDefinitionIndex");
		if(iItemDefinitionIndex == 325)
		{
			//SB_DP("iItemDefinitionIndex %d",iItemDefinitionIndex);
			//SB_DP("iItemDefinitionIndex 0.0");
			DamageModPercent(0.0);
			return;
		}
	}*/

	if(SB_ValidPlayer(victim) && g_CurDamageType==DMG_FALL)
	{
		//SB_DP("FALL DAMAGE");
		//new newdamage = (GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		//SB_SetPlayerProp(victim,iDamage,newdamage);
		if(GetEntityFlags(victim) & FL_ONGROUND)
		{
			//SB_DP("victim & DMG_FALL 0.0");
			DamageModPercent(0.0);
			//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre NO DAMAGE");
			//passcheck++;
			return true;
		}
	}

	//SB_DP("victim & DMG_FALL pass");

	//else if(SB_ValidPlayer(attacker) && attacker==victim)
	//{
		//if(iItemDefinitionIndex != 325)
		//{
		//new newdamage = (GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		//SB_SetPlayerProp(victim,iDamage,newdamage);
		//}
		//SB_DP("valid attacker 0.0");
		//DamageModPercent(0.0);
		//passcheck++;
	//}
	else if(SB_ValidPlayer(attacker) && SB_ValidPlayer(victim) && (GetClientTeam(attacker) != GetClientTeam(victim)))
	{
		//if(iItemDefinitionIndex != 325)
		//{
		if(!DamageCustom)
		{
			int newdamage = (GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
			SetPlayerProp(victim,iDamage,newdamage);
			DamageModPercent(0.0);
			//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre NO DAMAGE");
			bloodspray(victim);
		}
		else
		{
			int newdamage = (GetPlayerProp(victim,iDamage) + customdamage);
			SetPlayerProp(victim,iDamage,newdamage);
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
		new newdamage = (GetPlayerProp(victim,iDamage) + RoundToFloor(damage));
		SetPlayerProp(victim,iDamage,newdamage);
		//}
		//SB_DP("valid attacker 0.0");
		DamageModPercent(0.01);
		//passcheck++;
	}*/

	//SB_DP("valid attacker pass");

	/*
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
	}*/
	//SB_DP("iItemDefinitionIndex pass");

	if(SB_ValidPlayer(victim))
	{
		if(!DamageHandled && RoundToCeil(damage)>MAXHEALTHCHECK)
		{
			if(GetPlayerProp(victim,iLives)>1)
			{
				//PrintToChatAll("RoundToCeil(damage)>MAXHEALTHCHECK");
				DamageModPercent(0.0);
				//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre NO DAMAGE");
				FakeDeath(victim, attacker);
			}
		}
	}
	//PrintToChatAll("SB_Engine_Calculations_OnSB_TakeDmgAllPre end");
	return true;
}



public bool FakeDeath(int victim, int attacker)
{
	if(SB_ValidPlayer(victim))
	{
		if(GetPlayerProp(victim,iLives)>1)
		{
			SetPlayerProp(victim,iLives,GetPlayerProp(victim,iLives)-1);
			//CreateTimer(3.0,instaspawn,victim);

			iTotalScore[victim]=GetPlayerProp(victim,iLives);

			int RedTeam, BlueTeam;
			CalculateTeamScores(RedTeam,BlueTeam);

			// fake death
			if(GetConVarBool(FindConVar("sb_chatmsg")))
			{
				SB_ChatMessage(0,"{default}[{yellow}Total Lives{default}]{red}Red Team{default} %d {blue}Blue Team{default} %d",RedTeam,BlueTeam);
			}

			if(bHopEnabled)
			{
				//ServerCommand("sm_bhop_enabled %d 0",GetClientUserId(victim));
				//FC_SetBhop2(victim, false);
				//PrintToChatAll("bStopMovement FakeDeath");
				bStopMovement[victim] = false;
				//FC_SetBhop2(victim, false, false);
			}

			SpawnPlayer(victim);

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

public void StartTheRound()
{
	CountDownTimer = GetTime() + RoundToFloor(GetConVarFloat(sb_round_time));

	// engine calculations
	firstblood=false;
	CreateTimer(1.0,RemoveStuff,0);

	LoopAlivePlayers(target)
	{
		SpawnProtect(target);
	}

	SB_Engine_Display_teamplay_round_active();

	playing=true;
}
