//SB_001_HookEvent.sp


public SB_001_HookEvent_OnPluginStart()
{
	// Events for all games
	if(!HookEventEx("player_spawn",SB_PlayerSpawnEvent,EventHookMode_Pre)) //,EventHookMode_Pre
	{
		PrintToServer("[SmashBros] Could not hook the player_spawn event.");
	}
	if(!HookEventEx("player_death",SB_PlayerDeathEvent,EventHookMode_Pre))
	{
		PrintToServer("[SmashBros] Could not hook the player_death event.");
	}

	HookEvent("teamplay_round_start", teamplay_round_start);
	HookEvent("teamplay_round_active", teamplay_round_active);
	HookEvent("arena_round_start", arena_round_start);

	HookEvent("teamplay_round_win", teamplay_round_win);
	HookEvent("teamplay_waiting_begins", teamplay_waiting_begins);

	HookEvent("player_team", Event_player_team);

	SB_Engine_Calculations_SB_001_HookEvent();
}


public SB_PlayerSpawnEvent(Handle event,  char[] name, bool dontBroadcast)
{
	if(!g_sb_enabled) return 0;

	int userid=GetEventInt(event,"userid");
	if(userid>0)
	{
		int client=GetClientOfUserId(userid);
		if(SB_ValidPlayer(client,true))
		{

			if(!GetPlayerProp(client,SpawnedOnce))
			{
				SetPlayerProp(client,SpawnedOnce,true);
			}
			//forward to all other plugins last
			DoForward_OnSB_EventSpawn(client);

			SetPlayerProp(client,bStatefulSpawn,false); //no longer a "stateful" spawn
		}
	}
	return 1;
}

public Action SB_PlayerDeathEvent(Handle event,  char[] name, bool dontBroadcast)
{
	if(!g_sb_enabled) return Plugin_Continue;

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


	if(uid_attacker>0)
	{
		attackerIndex=GetClientOfUserId(uid_attacker);
	}

	if(uid_victim>0)
	{
		victimIndex=GetClientOfUserId(uid_victim);
	}

	if(uid_assister>0)
	{
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

	if(bHasDiedThisFrame[victimIndex]>0)
	{
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
		SetPlayerProp(victimIndex,bStatefulSpawn,true);//next spawn shall be stateful
	}
	return Plugin_Continue;
}

public Action teamplay_round_active(Handle event,  char[] name, bool dontBroadcast)
{
	if(!g_sb_enabled) return Plugin_Continue;

	//PrintToChatAll("teamplay_round_active");
	//Action aReturn = Plugin_Continue;
	StartTheRound();

	return Plugin_Continue;
}

public Action arena_round_start(Handle event,  char[] name, bool dontBroadcast)
{
	if(!g_sb_enabled) return Plugin_Continue;
	//PrintToChatAll("arena_round_start");
	/*
	playing=true;
	CountDownTimer = GetTime() + RoundToFloor(GetConVarFloat(sb_round_time));

	// engine calculations
	firstblood=false;
	CreateTimer(1.0,RemoveStuff,0);*/

	StartTheRound();

	if(bHopEnabled)
	{
		LoopIngameClients(target)
		{
			FC_SetBhop2(target, true, true);
		}
	}

	return Plugin_Continue;
}

public Action teamplay_round_win(Handle event,  char[] name, bool dontBroadcast)
{
	if(!g_sb_enabled) return Plugin_Continue;
	//PrintToChatAll("teamplay_round_win");
	playing=false;
	for(int i=1;i<=MaxClients;++i)
	{
		ResetClientVars(i);
	}
	SB_Engine_Display_teamplay_round_win();
	if(bHopEnabled)
	{
		LoopIngameClients(target)
		{
			CreateTimer(10.0, TurnOffMovement, target);
		}
	}
	return Plugin_Continue;
}
public Action:TurnOffMovement(Handle:timer, any:client)
{
	if(SB_ValidPlayer(client))
	{
		if(bHopEnabled)
		{
			//ServerCommand("sm_bhop_enabled %d 1",GetClientUserId(client));
			//PrintToChatAll("AllowMovementAgain");
			FC_SetBhop2(client, false, false);
		}
	}
}

public Action:teamplay_waiting_begins(Handle event,  char[] name, bool dontBroadcast)
{
	if(!g_sb_enabled) return Plugin_Continue;

	//PrintToChatAll("teamplay_waiting_begins");
	playing=false;
	return Plugin_Continue;
}


public Action teamplay_round_start(Handle event,  const char[] name, bool dontBroadcast)
{
	if(!g_sb_enabled) return Plugin_Continue;

	SB_Engine_Display_teamplay_round_start();
	return Plugin_Continue;
}


public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_sb_enabled) return Plugin_Continue;

	if(GetEventInt(event, "team")>1) {
		g_spec[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
	}
	return Plugin_Continue;
}
