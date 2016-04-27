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

