////////////////////////////////////////////////////////////
//
//			Fysics Control
//				(for TF2)
//			by thaCURSEDpie
//
//			2012-08-19
//
//			version 1.0.4
//
//
//			This plugin aims to give server-admins
//			greater control over the game's physics.
//
////////////////////////////////////////////////////////////
/*
 * =============================================================================
 * Smash Bros - FC - A modified addon first created by thaCURSEDpie,
 *                   then modified by El Diablo
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


////////////////////////////////////////////////////////////
//
//			Includes et cetera
//
////////////////////////////////////////////////////////////
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.4 smash bro addon"
#define SHORT_DESCRIPTION "Fysics Control by thaCURSEDpie."
#define ADMINCMD_MIN_LEVEL ADMFLAG_ROOT

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <sb_addon_fc>


////////////////////////////////////////////////////////////
//
//			Global vars
//
////////////////////////////////////////////////////////////
//-- Constants
static float Pi = 3.1415926535898;

//-- Handles
Handle hEnabled = null;
Handle hAirstrafeMult = null;
Handle hBhopMult = null;
Handle hBhopMaxDelay = null;
Handle hBhopZMult = null;
Handle hBhopAngleRatio = null;
Handle hBhopLazyMode = null;
Handle hAllowBounce = null;
Handle hBounceMult = null;
Handle hBhopMaxSpeed = null;
Handle hBhopEnabled = null;
Handle hAirstrafeIgnoreScouts = null;

//-- Values
float fAirstrafeMult = 1.0;
float fBhopMult = 1.0;
float fBhopMaxDelay = 0.2;
float fBhopZMult = 1.0;
float fBhopAngleRatio = 0.5;
bool bAirstrafeIgnoreScouts = true;
bool bModEnabled = true;
bool bBhopLazyMode = false;
bool bAllowBounce = false;
bool bBhopEnabled = true;
float fBounceMult = 1.0;
float fBhopMaxSpeed = -1.0;

//-- Player properties
float fAirstrafeMults[MAXPLAYERS];
float fBhopMults[MAXPLAYERS];
float fBhopZMults[MAXPLAYERS];
float fOldVels[MAXPLAYERS][3];
float fBhopAngleRatios[MAXPLAYERS];
bool bIsInAir[MAXPLAYERS];
bool bJumpPressed[MAXPLAYERS];
float fMomentTouchedGround[MAXPLAYERS];
float fBhopMaxDelays[MAXPLAYERS];
new iBounceInfo[MAXPLAYERS];
bool bIsAllowedToBounce[MAXPLAYERS];
bool bBhopLazyModes[MAXPLAYERS];
float fBounceMults[MAXPLAYERS];
float fBhopMaxSpeeds[MAXPLAYERS];
bool bIsAllowedToBhop[MAXPLAYERS];

////////////////////////////////////////////////////////////
//
//			Mod description
//
////////////////////////////////////////////////////////////
public Plugin:myinfo =
{
	name		 	= "Fysics Control",
	author		   	= "thaCURSEDpie, natives by Keith Warren (Jack of Designs)",
	description	 	= "This plugin aims to give server admins more control over the game physics.",
	version		  	= PLUGIN_VERSION,
	url			  	= "http://www.sourcemod.net"
};


////////////////////////////////////////////////////////////
//
//			OnPluginStart
//
////////////////////////////////////////////////////////////
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("FC_SetBhop", Native_SetBhop);
	CreateNative("FC_SetBhop2", Native_SetBhop2);
	CreateNative("FC_BhopStatus", Native_BhopStatus);
	CreateNative("FC_Enabled", Native_FC_Enabled);
	CreateNative("FC_Bhop_Enabled", Native_Bhop_Enabled);

	RegPluginLibrary("sb_addon_fc");

	return APLRes_Success;
}


////////////////////////////////////////////////////////////
//
//			OnPluginStart
//
////////////////////////////////////////////////////////////
public OnPluginStart()
{
	LoadTranslations("common.phrases");

	//---- Cmds
	RegAdminCmd("sm_fc_reload", CmdReload, ADMINCMD_MIN_LEVEL, "Reloads Fysics Control");

	// Airstrafe
	RegAdminCmd("sm_airstrafe_mult", CmdAirstrafeMult, ADMINCMD_MIN_LEVEL, "Change an individual user's airstrafe multiplier");

	// Bhop
	RegAdminCmd("sm_bhop_mult", CmdBhopMult, ADMINCMD_MIN_LEVEL, "Change an individual users's horizontal bhop multiplier (-1 disables bhop)");
	RegAdminCmd("sm_bhop_zmult", CmdBhopZMult, ADMINCMD_MIN_LEVEL, "Change an indivicual users's vertical bhop multiplier");
	RegAdminCmd("sm_bhop_lazymode", CmdBhopLazyMode, ADMINCMD_MIN_LEVEL, "Allow/dissallow an individual user to bunnyhop by holding +jump");
	RegAdminCmd("sm_bhop_enabled", CmdBhopEnabled, ADMINCMD_MIN_LEVEL, "Change whether or not an individual user can bunnyhop");

	// Bounce
	RegAdminCmd("sm_bounce_mult", CmdBounceMult, ADMINCMD_MIN_LEVEL, "Change an individual users's bounce multiplier");
	RegAdminCmd("sm_bounce_enabled", CmdBounceEnabled, ADMINCMD_MIN_LEVEL, "Allow/dissallow an individual user to bounce");

	//---- Convars
	CreateConVar("fc_version", PLUGIN_VERSION, SHORT_DESCRIPTION, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	// Overall mod
	hEnabled 			= CreateConVar("fc_enabled", "0", "Enable Fysics Control", FCVAR_PLUGIN);

	// Airstrafe
	hAirstrafeMult 		= CreateConVar("fc_airstrafe_mult", "1.0", "The multiplier to apply to airstrafing", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hAirstrafeIgnoreScouts = CreateConVar("fc_airstrafe_ignorescouts", "1", "Sets the airstrafe multiplier to ignore scouts, since this tends to screw up double-jumps", FCVAR_PLUGIN);

	// Bhop
	hBhopEnabled 		= CreateConVar("fc_bhop_enabled", "1", "Whether or not players can bunnyhop", FCVAR_PLUGIN);
	hBhopMult 			= CreateConVar("fc_bhop_mult", "1.0", "Horizontal boost to apply to bunnyhopping", FCVAR_PLUGIN, true, 0.0);
	hBhopMaxDelay		= CreateConVar("fc_bhop_maxdelay", "0.2", "Maximum time in seconds, after which the player has touched the ground and can still get a bhop boost.", FCVAR_PLUGIN);
	hBhopZMult 			= CreateConVar("fc_bhop_zmult", "1.0", "Boost to apply to vertical velocity when bunnyhopping", FCVAR_PLUGIN);
	hBhopAngleRatio 	= CreateConVar("fc_bhop_angleratio", "0.5", "Ratio between old and new velocity to be used with bunnyhopping", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hBhopLazyMode 		= CreateConVar("fc_bhop_lazymode", "1", "Whether or not player can bunnyhop simply by holding +jump", FCVAR_PLUGIN);
	hBhopMaxSpeed		= CreateConVar("fc_bhop_maxspeed", "-1.0", "The maximum speed for bunnyhopping. Use -1.0 for no max speed.", FCVAR_PLUGIN, true, -1.0);

	// Bounce
	hAllowBounce 		= CreateConVar("fc_bounce_enabled", "0", "Whether or not players can bounce", FCVAR_PLUGIN);
	hBounceMult 		= CreateConVar("fc_bounce_mult", "1.0", "Modifies the strenght of a bounce", FCVAR_PLUGIN, true, 0.0);

	//---- Convar changed hooks
	// Overall mod
	HookConVarChange(hEnabled, OnEnabledChanged);

	// Airstrafe
	HookConVarChange(hAirstrafeMult, OnAirstrafeMultChanged);
	HookConVarChange(hAirstrafeIgnoreScouts, OnAirstrafeIgnoreScoutsChanged);

	// Bhop
	HookConVarChange(hBhopMult, OnBhopMultChanged);
	HookConVarChange(hBhopMaxDelay, OnBhopMaxDelayChanged);
	HookConVarChange(hBhopZMult, OnBhopZMultChanged);
	HookConVarChange(hBhopAngleRatio, OnBhopAngleRatioChanged);
	HookConVarChange(hBhopLazyMode, OnBhopLazyModeChanged);
	HookConVarChange(hBhopMaxSpeed, OnBhopMaxSpeedChanged);
	HookConVarChange(hBhopEnabled, OnBhopEnabledChanged);

	// Bounce
	HookConVarChange(hAllowBounce, OnAllowBounceChanged);
	HookConVarChange(hBounceMult, OnBounceMultChanged);

	Init();
}


////////////////////////////////////////////////////////////
//
//			Commands
//
////////////////////////////////////////////////////////////
public Action:CmdReload(client, args)
{
	Init();
	ReplyToCommand(client, "Fysics Control reloaded!");

	return Plugin_Handled;
}

public Action:CmdBhopMult(client, args)
{
	HandleCmdMult(client, args, "sm_bhop_mult", fBhopMults);

	return Plugin_Handled;
}

public Action:CmdBhopZMult(client, args)
{
	HandleCmdMult(client, args, "sm_bhop_zmult", fBhopZMults);

	return Plugin_Handled;
}

public Action:CmdAirstrafeMult(client, args)
{
	HandleCmdMult(client, args, "sm_airstrafe_mult", fAirstrafeMults);

	return Plugin_Handled;
}

public Action:CmdBounceMult(client, args)
{
	HandleCmdMult(client, args, "sm_bounce_zmult", fBounceMults);

	return Plugin_Handled;
}

public Action:CmdBhopEnabled(client, args)
{
	HandleCmdBool(client, args, "sm_bhop_enabled", bIsAllowedToBhop);

	return Plugin_Handled;
}

public Action:CmdBounceEnabled(client, args)
{
	HandleCmdBool(client, args, "sm_bounce_enabled", bIsAllowedToBounce);

	return Plugin_Handled;
}

public Action:CmdBhopLazyMode(client, args)
{
	HandleCmdBool(client, args, "sm_bhop_lazymode", bBhopLazyModes);

	return Plugin_Handled;
}


////////////////////////////////////////////////////////////
//
//			Command handling
//
////////////////////////////////////////////////////////////
public HandleCmdBool(client, args, String:cmdName[], bool:targetArray[])
{
	if (args < 2)
	{
		char buf[300] = "[SM] Usage: ";
		StrCat(buf, sizeof(buf), cmdName);
		StrCat(buf, sizeof(buf), " <#userid|name> [amount]");

		ReplyToCommand(client, buf);

		return;
	}

	decl clients[MAXPLAYERS], nTargets;
	decl String:targetName[MAX_TARGET_LENGTH];

	if (GetTargetedClients(client, clients, nTargets, targetName) == 1)
	{
		return;
	}

	int amount = 0;

	char arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));

	if (StringToIntEx(arg2, amount) == 0 || amount <= 0)
	{
		ReplyToCommand(client, "[SM] %t", "Invalid Amount");

		return;
	}

	for (new i = 0; i < nTargets; i++)
	{
		targetArray[clients[i]] = view_as<bool>(amount);
	}

	ReplyToCommand(client, "[FC] Successfully applied cmd %s with value %b to %s!", cmdName, amount, targetName);
}

public HandleCmdMult(client, args, String:cmdName[], Float:targetArray[])
{
	if (args < 2)
	{
		char buf[300] = "[SM] Usage: ";
		StrCat(buf, sizeof(buf), cmdName);
		StrCat(buf, sizeof(buf), " <#userid|name> [amount]");

		ReplyToCommand(client, buf);

		return;
	}

	int clients[MAXPLAYERS];
	int nTargets = 0;

	char targetName[MAX_TARGET_LENGTH];

	if (GetTargetedClients(client, clients, nTargets, targetName) == 1)
	{
		return;
	}

	float amount = 0.0;

	char arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));

	if (StringToFloatEx(arg2, amount) == 0 || amount < 0)
	{
		ReplyToCommand(client, "[SM] %t", "Invalid Amount");

		return;
	}

	for (new i = 0; i < nTargets; i++)
	{
		targetArray[clients[i]] = amount;
	}

	ReplyToCommand(client, "[FC] Successfully applied cmd %s with value %f to %s!", cmdName, amount, targetName);
}

// Gets the clients the admin wants to target
// 		I got this somewhere from the SourceMod wiki, can't remember where :-(
public GetTargetedClients(admin, clients[MAXPLAYERS], &targetCount, String:targetName[])
{
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	bool tn_is_ml;

	if ((targetCount = ProcessTargetString(arg, admin, clients, MAXPLAYERS,COMMAND_FILTER_ALIVE, targetName, MAX_TARGET_LENGTH, tn_is_ml)) <= 0)
	{
		ReplyToTargetError(admin, targetCount);

		return 1;
	}

	return 0;
}


////////////////////////////////////////////////////////////
//
//			Init
//
////////////////////////////////////////////////////////////
public Init()
{
	//-- Init some arrays and values
	for (int i = 1; i < MAXPLAYERS; i++)
	{
		SetConVarFloat(hAirstrafeMult, fAirstrafeMult);
		SetConVarFloat(hBhopMult, fBhopMult);
		SetConVarFloat(hBhopMaxDelay, fBhopMaxDelay);
		SetConVarFloat(hBhopZMult, fBhopZMult);
		SetConVarFloat(hBhopAngleRatio, fBhopAngleRatio);
		SetConVarBool(hAllowBounce, bAllowBounce);
		SetConVarBool(hBhopLazyMode, bBhopLazyMode);
		SetConVarBool(hBhopEnabled, bBhopEnabled);
		SetConVarFloat(hBounceMult, fBounceMult);
		SetConVarFloat(hBhopMaxSpeed, fBhopMaxSpeed);

		fAirstrafeMults[i] = fAirstrafeMult;
		fBhopMults[i] = fBhopMult;
		fBhopMaxDelays[i] = fBhopMaxDelay;
		fBhopZMults[i] = fBhopZMult;
		fBhopAngleRatios[i] = fBhopAngleRatio;
		bIsAllowedToBounce[i] = bAllowBounce;
		bBhopLazyModes[i] = bBhopLazyMode;
		fBounceMults[i] = fBounceMult;
		fBhopMaxSpeeds[i] = fBhopMaxSpeed;
		bIsAllowedToBhop[i] = bBhopEnabled;

		if (IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}


////////////////////////////////////////////////////////////
//
//			OnClientPutInServer
//
////////////////////////////////////////////////////////////
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}


////////////////////////////////////////////////////////////
//
//			Convars Changed Hooks
//
////////////////////////////////////////////////////////////
public OnEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bModEnabled = GetConVarBool(convar);
}

public OnBhopEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bBhopEnabled = GetConVarBool(convar);

	for (int i = 0; i < MAXPLAYERS; i++)
	{
		bIsAllowedToBhop[i] = bBhopEnabled;
	}
}

public OnAirstrafeMultChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	fAirstrafeMult = GetConVarFloat(convar);

	for (int i = 0; i < MAXPLAYERS; i++)
	{
		fAirstrafeMults[i] = fAirstrafeMult;
	}
}

public OnAirstrafeIgnoreScoutsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bAirstrafeIgnoreScouts = GetConVarBool(convar);
}

public OnAllowBounceChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bAllowBounce = GetConVarBool(convar);

	for (int i = 0; i < MAXPLAYERS; i++)
	{
		bIsAllowedToBounce[i] = bAllowBounce;
	}
}

public OnBounceMultChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	fBounceMult = GetConVarFloat(convar);

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		fBounceMults[i] = fBounceMult;
	}
}

public OnBhopLazyModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	bBhopLazyMode = GetConVarBool(convar);

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		bBhopLazyModes[i] = bBhopLazyMode;
	}
}

public OnBhopMaxSpeedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	fBhopMaxSpeed = GetConVarFloat(convar);

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		fBhopMaxSpeeds[i] = fBhopMaxSpeed;
	}
}

public OnBhopMultChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	fBhopMult = GetConVarFloat(convar);

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		fBhopMults[i] = fBhopMult;
	}
}

public OnBhopAngleRatioChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	fBhopAngleRatio = GetConVarFloat(convar);

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		fBhopAngleRatios[i] = fBhopAngleRatio;
	}
}

public OnBhopZMultChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	fBhopZMult = GetConVarFloat(convar);

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		fBhopZMults[i] = fBhopZMult;
	}
}

public OnBhopMaxDelayChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	float oldMult = fBhopMaxDelay;

	fBhopMaxDelay = GetConVarFloat(convar);

	for (new i = 0; i < MAXPLAYERS; i++)
	{
		if (fBhopMaxDelays[i] == oldMult)
		{
			fBhopMaxDelays[i] = fBhopMaxDelay;
		}
	}
}


////////////////////////////////////////////////////////////
//
//			OnPlayerRunCmd
//
////////////////////////////////////////////////////////////
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!bModEnabled)
	{
		return Plugin_Continue;
	}

	if (bIsInAir[client])
	{
		if (!bAirstrafeIgnoreScouts || TF2_GetPlayerClass(client) != TFClass_Scout)
		{
			vel[0] *= fAirstrafeMults[client];
			vel[1] *= fAirstrafeMults[client];
		}

		if (bIsAllowedToBounce[client])
		{
			if (buttons & IN_JUMP && buttons & IN_DUCK)
			{
				iBounceInfo[client] = 1;
			}
			else
			{
				iBounceInfo[client] = 0;
			}
		}
	}
	else
	{
		if (iBounceInfo[client] == 1)
		{
			if (buttons & IN_JUMP && buttons & IN_DUCK)
			{
				iBounceInfo[client] = 2;
			}
		}
		else if (buttons & IN_JUMP)
		{
			bJumpPressed[client] = true;
		}
	}

	return Plugin_Continue;
}


////////////////////////////////////////////////////////////
//
//			OnTakeDamage
//
////////////////////////////////////////////////////////////
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (!IsValidClient(victim))
	{
		return Plugin_Continue;
	}

	if (damagetype & DMG_FALL)
	{
		if (iBounceInfo[victim] == 1) // Block damage is the player is bouncing
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}


////////////////////////////////////////////////////////////
//
//			OnPostThink
//
////////////////////////////////////////////////////////////
public OnPostThink(client)
{
	if (!bModEnabled || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}

	if (iBounceInfo[client] == 2)
	{
		iBounceInfo[client] = 0;

		fOldVels[client][2] *= -fBounceMults[client];
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fOldVels[client]);
	}
	else if (bJumpPressed[client])
	{
		bJumpPressed[client] = false;

		if (bBhopEnabled && bIsAllowedToBhop[client] && GetTickedTime() - fMomentTouchedGround[client] <= fBhopMaxDelays[client])
		{
			float fNewVel[3];

			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fNewVel);

			float fAngle = GetVectorAngle(fNewVel[0], fNewVel[1]);
			float fOldAngle = GetVectorAngle(fOldVels[client][0], fOldVels[client][1]);

			float fSpeed = SquareRoot(fOldVels[client][0] * fOldVels[client][0] + fOldVels[client][1] * fOldVels[client][1]);
			fSpeed *= fBhopMults[client];

			float fNewAngle = (fAngle * fBhopAngleRatios[client] + fOldAngle) / (fBhopAngleRatios[client] + 1);

			// There are some strange instances we need to filter out, else the player sometimes gets propelled backwards
			if ((fOldAngle < 0) && (fNewAngle >= 0))
			{
				fNewAngle = fAngle;
			}
			else if ((fNewAngle < 0) && (fOldAngle >= 0) )
			{
				fNewAngle = fAngle;
			}

			if (bBhopLazyModes[client])
			{
				fNewVel[2] = 300.0;
			}

			if (fSpeed > fBhopMaxSpeeds[client] && fBhopMaxSpeeds[client] >= 0.0)
			{
				fSpeed = fBhopMaxSpeeds[client];
			}

			fNewVel[0] = fSpeed * Cosine(fAngle);
			fNewVel[1] = fSpeed * Sine(fAngle);
			fNewVel[2] *= fBhopZMults[client];

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fNewVel);
		}
	}

	// Find out if the player is on the ground or in the air
	new iGroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");

	if (iGroundEntity == -1)
	{
		// Air
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fOldVels[client]);
		bIsInAir[client] = true;
	}
	else
	{
		// Ground or entity
		if (bIsInAir[client])
		{
			fMomentTouchedGround[client] = GetTickedTime();
			bIsInAir[client] = false;
		}
	}
}


/////////////////////////////////////////////////////////
//
//		 GetVectorAngle
//
//		 Notes:
//		  Get the angle for the respective vector
//
/////////////////////////////////////////////////////////
Float:GetVectorAngle(Float:x, Float:y)
{
	// set this to an arbitrary value, which we can use for error-checking
	float theta=1337.00;

	// some math :)
	if (x>0)
	{
		theta = ArcTangent(y/x);
	}
	else if ((x<0) && (y>=0))
	{
		theta = ArcTangent(y/x) + Pi;
	}
	else if ((x<0) && (y<0))
	{
		theta = ArcTangent(y/x) - Pi;
	}
	else if ((x==0) && (y>0))
	{
		theta = 0.5 * Pi;
	}
	else if ((x==0) && (y<0))
	{
		theta = -0.5 * Pi;
	}

	// let's return the value
	return theta;
}

////////////////////////////////////////////////////////////
//
//			Natives
//
////////////////////////////////////////////////////////////
public int Native_FC_Enabled(Handle plugin, int numParams)
{
	return GetConVarBool(hEnabled);
}

public int Native_Bhop_Enabled(Handle plugin, int numParams)
{
	return bBhopEnabled;
}

public int Native_SetBhop(Handle plugin, int numParams)
{
	if (!hEnabled || !hBhopEnabled) ThrowNativeError(SP_ERROR_INDEX, "Native is currently disabled.");

	int client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client is invalid.");
	}

	bIsAllowedToBhop[client] = bool:GetNativeCell(2);
	bBhopLazyModes[client] = bool:GetNativeCell(3);
	fBhopMults[client] = Float:GetNativeCell(4);
	fBhopZMults[client] = Float:GetNativeCell(5);
}

public int Native_SetBhop2(Handle plugin, int numParams)
{
	if (!hEnabled || !hBhopEnabled) return 0; //ThrowNativeError(SP_ERROR_INDEX, "Native is currently disabled.");

	int client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		//ThrowNativeError(SP_ERROR_INDEX, "Client is invalid.");
		return;
	}

	bIsAllowedToBhop[client] = bool:GetNativeCell(2);
	bBhopLazyModes[client] = bool:GetNativeCell(3);
}

public int Native_BhopStatus(Handle plugin, int numParams)
{
	if (!hEnabled || !hBhopEnabled) ThrowNativeError(SP_ERROR_INDEX, "Native is currently disabled.");

	int client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client is invalid.");
	}

	return bIsAllowedToBhop[client];
}

bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
	return false;
	return true;
}
