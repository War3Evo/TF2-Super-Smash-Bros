//SB_Engine_DamageSystem.sp

//#pragma semicolon 1
//#include <sourcemod>
//#include <sdkhooks>
//#include <sb_interface>


public OnPluginStart_SB_Engine_DamageSystem()
{
	PyroSB_ChanceModifierCvar=CreateConVar("sb_pyro_chancemod","0.500","Float 0.0 - 1.0");
	HeavySB_ChanceModifierCvar=CreateConVar("sb_heavy_chancemod","0.666","Float 0.0 - 1.0");

	//HookEvent("player_hurt", EventPlayerHurt);   ERRORS ON STACK..

	ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
}

public bool SB_Engine_DamageSystem_SB_Engine_InitNatives()
{
	CreateNative("SB_DamageModPercent",Native_SB_DamageModPercent);

	CreateNative("SB_GetDamageType",NSB_GetDamageType);
	CreateNative("SB_GetDamageInflictor",NSB_GetDamageInflictor);

	CreateNative("SB_GetSBDamageDealt",Native_SB_GetSBDamageDealt);

	CreateNative("SB_GetDamageStack",NSB_GetDamageStack);

	CreateNative("SB_ChanceModifier",Native_SB_ChanceModifier);
	CreateNative("SB_IsOwnerSentry",Native_SB_IsOwnerSentry);

	return true;
}

public bool SB_Engine_DamageSystem_SB_Engine_InitForwards()
{
	FHOnSB_TakeDmgAllPre=CreateGlobalForward("OnSB_TakeDmgAllPre",ET_Hook,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
	FHOnSB_TakeDmgAll=CreateGlobalForward("OnSB_TakeDmgAll",ET_Hook,Param_Cell,Param_Cell,Param_Cell);

	g_OnSBEventPostHurtFH=CreateGlobalForward("OnSBEventPostHurt",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_String);

	ChanceModifierSentry=CreateConVar("sb_chancemodifier_sentry","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");
	ChanceModifierSentryRocket=CreateConVar("sb_chancemodifier_sentryrocket","","None to use attack rate dependent chance modifier. Set from 0.0 to 1.0 chance modifier for sentry, this will override time dependent chance modifier");

	return true;
}

public Native_SB_DamageModPercent(Handle:plugin,numParams)
{
	if(!g_CanSetDamageMod){
		LogError("	");
		ThrowError("You may not set damage mod percent here, use ....Pre forward");
		//SB_LogError("You may not set damage mod percent here, use ....Pre forward");
		//PrintPluginError(plugin);
	}

	new Float:num=GetNativeCell(1);
	#if defined DEBUG
	PrintToServer("percent change %f",num);
	#endif
	g_CurDMGModifierPercent*=num;

}

public NSB_GetDamageType(Handle:plugin,numParams){
	return g_CurDamageType;
}
public NSB_GetDamageInflictor(Handle:plugin,numParams){
	return g_CurInflictor;
}
public NSB_GetDamageStack(Handle:plugin,numParams){
	return damagestack;
}

// Damage Engine needs to know about sentries and dispensers and stuff...
public OnEntityCreated(entity, const String:classname[])
{
	// Errors from this event... gives massive negative values.. should use entity > 0
	// DONT REMOVE entity>0
	// chdata recommended adding " StrContains(classname, "obj_", false) == 0"
	if(entity>0 && IsValidEntity(entity) && StrContains(classname, "obj_", false) == 0)
	{
		SDKHook(entity, SDKHook_OnTakeDamage, SDK_Forwarded_OnTakeDamage);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
}
public OnClientDisconnect(client)
{
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePostHook);
}

public Native_SB_IsOwnerSentry(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new bool:UseInternalInflictor=GetNativeCell(2);
	new pSentry;
	if(UseInternalInflictor)
		pSentry=g_CurInflictor;
	else
		pSentry=GetNativeCell(3);

	if(SB_ValidPlayer(client))
	{
		if(IsValidEntity(pSentry)&&TF2_GetPlayerClass(client)==TFClass_Engineer)
		{
			decl String:netclass[32];
			GetEntityNetClass(pSentry, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
			{
				if (GetEntDataEnt2(pSentry, ownerOffset) == client)
					return true;
			}
		}
	}
	return false;
}

public Native_SB_ChanceModifier(Handle:plugin,numParams)
{

	new attacker=GetNativeCell(1);
	if(attacker<=0 || attacker>MaxClients || !IsValidEdict(attacker)){
		return _:1.0;
	}

	new Float:tempChance = GetRandomFloat(0.0,1.0);
	switch (TF2_GetPlayerClass(attacker))
	{
		case TFClass_Heavy:
		{
			if (tempChance <= GetConVarFloat(HeavySB_ChanceModifierCvar)) //heavy cvar here, replaces 0.666
				return _:0.0;
		}
		case TFClass_Pyro:
		{
			if (tempChance <= GetConVarFloat(PyroSB_ChanceModifierCvar)) //pyro cvar here, replaces 0.500
				return _:0.0;
		}
	}
	return _:ChanceModifier[attacker];
}

new VictimCheck=-666;
new AttackerCheck=-666;
new InflictorCheck=-666;
new Float:DamageCheck=-666.6;
new DamageTypeCheck=-666;
new WeaponCheck=-666;
new Float:damageForceCheck[3];
new Float:damagePositionCheck[3];
new damagecustomCheck = -666;

public Action:SDK_Forwarded_OnTakeDamage(victim,&attacker,&inflictor,&Float:damage,&damagetype,&weapon,Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(VictimCheck==victim
	&&AttackerCheck==attacker
	&&InflictorCheck==inflictor
	&&DamageCheck==damage
	&&DamageTypeCheck==damagetype
	&&WeaponCheck==weapon
	&&damageForceCheck[0]==damageForce[0]
	&&damageForceCheck[1]==damageForce[1]
	&&damageForceCheck[2]==damageForce[2]
	&&damagePositionCheck[0]==damagePosition[0]
	&&damagePositionCheck[1]==damagePosition[1]
	&&damagePositionCheck[2]==damagePosition[2]
	&&damagecustomCheck==damagecustom
	)
	{
		return Plugin_Continue;
	}

	if(SB_ValidPlayer(victim,true)){
		//store old variables on local stack!

		new old_DamageType= g_CurDamageType;
		new old_Inflictor= g_CurInflictor;
		new Float:old_DamageModifierPercent = g_CurDMGModifierPercent;

		//set these to global
		g_CurDamageType=damagetype;
		g_CurInflictor=inflictor;
		g_CurDMGModifierPercent=1.0;

		//#if defined DEBUG
		//DP2("sdktakedamage %d->%d at damage [%.2f]",attacker,victim,damage);
		//#endif

		damagestack++;

		if(attacker!=inflictor)
		{
			if(inflictor>0 && IsValidEdict(inflictor))
			{
				new String:ent_name[64];
				GetEdictClassname(inflictor,ent_name,64);
						//	DP("ent name %s",ent_name);
				if(StrContains(ent_name,"obj_sentrygun",false)==0	&&!CvarEmpty(ChanceModifierSentry))
				{
					ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentry);
				}
				else if(StrContains(ent_name,"tf_projectile_sentryrocket",false)==0 &&!CvarEmpty(ChanceModifierSentryRocket))
				{
					ChanceModifier[attacker]=GetConVarFloat(ChanceModifierSentryRocket);
				}
			}
		}
		//	DP("%f",ChanceModifier[attacker]);
		//else it is true damage
		//PrintToChatAll("takedmg %f BULLET %d   lastiswarcraft %d",damage,isBulletDamage,g_CurDamageIsWarcraft);

		new bool:old_CanSetDamageMod=g_CanSetDamageMod;
		new bool:old_CanDealDamage=g_CanDealDamage;
		g_CanSetDamageMod=true;
		g_CanDealDamage=false;
		Call_StartForward(FHOnSB_TakeDmgAllPre);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(damage);
		Call_PushCell(damagecustom);
		Call_Finish(dummyresult); //this will be returned to

		g_CanSetDamageMod=false;
		g_CanDealDamage=true;

		if(g_CurDMGModifierPercent>0.001){ //so if damage is already canceled, no point in forwarding the second part , do we dont get: evaded but still recieve warcraft damage proc)

			Call_StartForward(FHOnSB_TakeDmgAll);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_PushCell(damage);
			Call_Finish(dummyresult); //this will be returned to

		}
		g_CanSetDamageMod=old_CanSetDamageMod;
		g_CanDealDamage=old_CanDealDamage;

		//modify final damage
		//DP("Damage before modifier %f %d to %d",damage,attacker,victim);
		damage=damage*g_CurDMGModifierPercent; ////so we calculate the percent

		//nobobdy retrieves our global variables outside of the forward call, restore old stack vars
		g_CurDamageType= old_DamageType;
		g_CurInflictor= old_Inflictor;
		g_CurDMGModifierPercent = old_DamageModifierPercent;

		damagestack--;

		VictimCheck=victim;
		AttackerCheck=attacker;
		InflictorCheck=inflictor;
		DamageCheck=damage;
		DamageTypeCheck=damagetype;
		WeaponCheck=weapon;
		damageForceCheck[0]=damageForce[0];
		damageForceCheck[1]=damageForce[1];
		damageForceCheck[2]=damageForce[2];
		damagePositionCheck[0]=damagePosition[0];
		damagePositionCheck[1]=damagePosition[1];
		damagePositionCheck[2]=damagePosition[2];
		damagecustomCheck=damagecustom;

		//#if defined DEBUG

		//DP2("sdktakedamage %d->%d END dmg [%.2f]",attacker,victim,damage);
		//#endif
	}

	return Plugin_Changed;
}


public OnTakeDamagePostHook(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
		// GHOSTS!!
		if (weapon == -1 && inflictor == -1)
		{
				//SB_LogError("OnTakeDamagePostHook: Who was pho^H^H^Hweapon?");
				return;
		}

		//Block uber hits (no actual damage)
		if(SB_IsUbered(victim))
		{
				//DP("ubered but SDK OnTakeDamagePostHook called, damage %f",damage);
				return;
		}

		damagestack++;

		new bool:old_CanDealDamage=g_CanDealDamage;
		g_CanSetDamageMod=true;

		g_CurInflictor = inflictor;

		// sbsource 2.0 uses this:
		//Figure out what really hit us. A weapon? A sentry gun?
		new String:weaponName[64];
		new realWeapon = weapon == -1 ? inflictor : weapon;
		GetEntityClassname(realWeapon, weaponName, sizeof(weaponName));

		//SB_LogInfo("OnTakeDamagePostHook called with weapon \"%s\"", weaponName);

		Call_StartForward(g_OnSBEventPostHurtFH);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(RoundToFloor(damage));
		Call_PushString(weaponName);
		Call_Finish(dummyreturn);

		g_CanDealDamage=old_CanDealDamage;

		damagestack--;

		g_CurLastActualDamageDealt = RoundToFloor(damage);
}

public Native_SB_GetSBDamageDealt(Handle:plugin,numParams) {
	return g_CurLastActualDamageDealt;
}
