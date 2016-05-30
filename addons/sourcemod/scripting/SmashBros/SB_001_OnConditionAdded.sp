//SB_001_OnConditionAdded.sp

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(g_sb_enabled)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Bleeding))
		{
			TF2_RemoveCondition(client, TFCond_Bleeding);
			int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
			SB_SetHealth(client, MaxHealth);
		}
	}
}

