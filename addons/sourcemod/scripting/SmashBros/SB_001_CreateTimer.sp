// SB_001_CreateTimer.sp

// Not all createtimers are in here.  For example, SB_001_RegConsoleCmd, handles everything itself.

public OnPluginStart_SB_001_CreateTimer()
{
	CreateTimer(1.0, Timer_Uber_Regen, _, TIMER_REPEAT);
}

public Action:Timer_Uber_Regen(Handle:timer, any:user)
{
	for (int i=1; i<=MaxClients; i++)
	{
		if (!SB_ValidPlayer(i,true,true))
		{
			continue;	// Client isnt valid
		}

		if(TF2_GetPlayerClass(i) != TFClass_Medic)
		{
			continue;
		}

		//g_sb_medichealself
		if(SB_GetPlayerProp(i,iDamage)>0)
		{
			int NewDamage = SB_GetPlayerProp(i,iDamage)-g_sb_medichealself;
			if(TF2_IsPlayerInCondition(i, TFCond_MegaHeal))
			{
				NewDamage -= g_sb_medichealself;
			}
			if(NewDamage<0) NewDamage = 0;
			SB_SetPlayerProp(i,iDamage,NewDamage);
		}

		int HealVictim = TF2_GetHealingTarget(i);
		//if (ValidPlayer(HealVictim, true) && !SB_IsUbered(healer))
		if (SB_ValidPlayer(HealVictim, true))
		{
			//SB_DP("healer %d ... healer victim %d",i,HealVictim);
			if(SB_GetPlayerProp(HealVictim,iDamage)>0)
			{
				int NewDamage = SB_GetPlayerProp(HealVictim,iDamage)-g_sb_medicheal;
				if(TF2_IsPlayerInCondition(i, TFCond_MegaHeal))
				{
					NewDamage -= g_sb_medicmegaheal;
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
