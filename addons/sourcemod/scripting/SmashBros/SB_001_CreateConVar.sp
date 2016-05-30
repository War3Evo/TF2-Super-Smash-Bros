//SB_001_CreateConVar.sp

public OnPluginStart_SB_001_CreateConVar()
{
	CreateConVar("Super_Smash_Bros_version", PLUGIN_VERSION, "Smash Bros version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	sb_enabled = CreateConVar("sb_enabled", "1", "1 to enable / 0 to disable Smash Bros", FCVAR_PLUGIN);
	HookConVarChange(sb_enabled, OnConVarChange);


	sb_round_time = CreateConVar("sb_roundtime", "300.0", "Round Time in Seconds", FCVAR_PLUGIN);
	HookConVarChange(sb_round_time, OnConVarChange);

	sb_fc_bhop = CreateConVar("sb_fc_bhop", "0.5", "fc disable bhop on spawn for seconds", FCVAR_PLUGIN);

	sb_medichealself = CreateConVar("sb_medichealself", "2", "amount of heal applied to self", FCVAR_PLUGIN);
	g_sb_medichealself = GetConVarInt(sb_medichealself);

	sb_medicheal = CreateConVar("sb_medicheal", "1", "amount of heal applied to team when healing them", FCVAR_PLUGIN);
	g_sb_medicheal = GetConVarInt(sb_medicheal);

	sb_medicmegaheal = CreateConVar("sb_medicmegaheal", "1", "extra points for healing", FCVAR_PLUGIN);
	g_sb_medicmegaheal = GetConVarInt(sb_medicmegaheal);

	sb_angles = CreateConVar("sb_angles", "50.0", "Advanced options", FCVAR_PLUGIN);
	g_fsb_angles = GetConVarFloat(sb_angles);

	sb_upward_force= CreateConVar("sb_upward_force", "1.5", "Advanced options", FCVAR_PLUGIN);
	g_fsb_upward_force = GetConVarFloat(sb_upward_force);

	HookConVarChange(sb_medichealself, OnConVarChange);
	HookConVarChange(sb_medicheal, OnConVarChange);
	HookConVarChange(sb_medicmegaheal, OnConVarChange);
	HookConVarChange(sb_angles, OnConVarChange);
	HookConVarChange(sb_upward_force, OnConVarChange);

	sb_lives = CreateConVar("sb_lives", "3", "Amount of lives a player starts with.", FCVAR_PLUGIN);
	sb_chatmsg = CreateConVar("sb_chatmsg", "0", "Enable chat messages of team scores in chat.", FCVAR_PLUGIN);
	sb_chatmsg_balance = CreateConVar("sb_chatmsg_balance", "1", "Enable showing player balance information of lives during beginning of round.", FCVAR_PLUGIN);

	SB_Engine_Weapon_Manager_SB_001_CreateConVar();

	ServerCommand("tf_arena_preround_time 5");
	ServerCommand("mp_teams_unbalance_limit 0");
	ServerCommand("mp_enableroundwaittime 0");
	ServerCommand("mp_restartround 0");
	ServerCommand("mp_stalemate_timelimit 0");
	ServerCommand("mp_stalemate_enable 0");
	ServerCommand("tf_arena_override_team_size 1");
	ServerCommand("tf_arena_use_queue 0");
}


public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == sb_round_time)
	{
		if(playing)
		{
			CountDownTimer = GetTime() + RoundToFloor(GetConVarFloat(sb_round_time));
		}
	}
	else if(hConvar == sb_angles)
		g_fsb_angles = GetConVarFloat(sb_angles);
	else if(hConvar == sb_upward_force)
		g_fsb_upward_force = GetConVarFloat(sb_upward_force);
	else if(hConvar == sb_medicheal)
		g_sb_medicheal = GetConVarInt(sb_medicheal);
	else if(hConvar == sb_medicmegaheal)
		g_sb_medicmegaheal = GetConVarInt(sb_medicmegaheal);
	else if(hConvar == sb_medichealself)
		g_sb_medichealself = GetConVarInt(sb_medichealself);
	else if(hConvar == sb_enabled)
		g_sb_enabled = GetConVarBool(sb_enabled);
}
