// *************************************************************************
// 000_box_engine.inc is part of 000_box_engine.sp
//
// Made by  El Diablo <admin@war3evo.info>
//
//  War3Evo Community Forums: https://war3evo.info/forums/index.php

// https://forums.alliedmods.net/showthread.php?t=264551&page=3

#if defined box_engine_000
 #endinput
#endif
#define box_engine_000


// Bit flags for what a box should target
#define BOX_TARGET_NOBODY			(0 << 0)
#define BOX_TARGET_REDTEAM			(1 << 0)
#define BOX_TARGET_BLUETEAM			(1 << 1)
#define BOX_TARGET_BOTHTEAMS		(1 << 2) // not currently using
#define BOX_TARGET_SCOUT			(1 << 3)
#define BOX_TARGET_SNIPER			(1 << 4)
#define BOX_TARGET_SOLDIER			(1 << 5)
#define BOX_TARGET_DEMOMAN			(1 << 6)
#define BOX_TARGET_MEDIC			(1 << 7)
#define BOX_TARGET_HEAVY			(1 << 8)
#define BOX_TARGET_PYRO				(1 << 9)
#define BOX_TARGET_SPY				(1 << 10)
#define BOX_TARGET_ENGINEER			(1 << 11)

#define BEHAVIOR_NONE				(0 << 0)
#define BEHAVIOR_NO_DAMAGE			(1 << 0)
#define BEHAVIOR_NO_SHOOTING		(1 << 1)
#define BEHAVIOR_NO_BUILDINGS		(1 << 2)
#define BEHAVIOR_KILL_ZONE			(1 << 3)
#define BEHAVIOR_OUTSIDE_ZONE		(1 << 4)


#if !defined _diablostocks_included
#define LoopMaxClients(%1) for(new %1=1;%1<=MaxClients;++%1)
#define LoopIngameClients(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1))
#define LoopAlivePlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientInGame(%1) && IsPlayerAlive(%1))
#define STRING(%1) %1, sizeof(%1)

// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS
// STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS

#if !defined _vanilla_constants_included
#if !defined _War3Source_included
stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		if(check_alive && !IsPlayerAlive(client))
		{
			return false;
		}
		if(alivecheckbyhealth&&GetClientHealth(client)<1) {
			return false;
		}
		return true;
	}
	return false;
}
#endif
#endif
#endif


/**
 * Toggle bitflags.
 *
 * @param bitflag		flag index.
 * @param removebits	Bits to remove.
 * @noreturn
 */
stock ToggleBitflag(bitflag, removebits)
{
	bitflag ^= removebits;
	return bitflag;
}

/**
 * Removes bitflags.
 *
 * @param bitflag		flag index.
 * @param removebits	Bits to remove.
 * @noreturn
 */
stock RemoveBitflag(bitflag, removebits)
{
	bitflag &= ~removebits;
	return bitflag;
}

/**
 * Adds bitflags.
 *
 * @param bitflag		flag index.
 * @param addbits		Bits to add.
 * @noreturn
 */
stock AddBitflag(bitflag, addbits)
{
	bitflag |= addbits;
	return bitflag;
}

/**
 * Clears all bitflags.
 *
 * @param bitflag		flag Index.
 * @noreturn
 */
stock ClearBits(bitflag)
{
	bitflag=0;
}

/**
 * Returns if the given flags exists or not.
 *
 * @param bitflag		flag Index.
 * @param vzbits		bits as bitflag.
 * @return				True if the bits are exist otherwise false.
 */
stock bool:HasBitflags(bitflag, vzbits)
{
	return bool:(bitflag & vzbits);
}

// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES
// NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES NATIVES

/**
 * checks if player is in boxindex
 *
 * @param boxindex: box id
 *
 * @return true if player is in box, otherwise false
 */
native bool:Box_IsPlayerInBox(client,boxindex);

/**
 * gets box Behavior
 *
 * @param boxindex: box id
 *
 * @return Behavior of boxindex
 */
native Box_GetBehavior(boxindex);

/**
 * gets box Target
 *
 * @param boxindex: box id
 *
 * @return Target of boxindex
 */
native Box_GetTarget(boxindex);

/**
 * sets box Behavior
 *
 * @param boxindex: box id
 * @param Behavior: Behavior of box
 *
 * @return none
 */
native Box_SetBehavior(boxindex,Behavior);

/**
 * sets box Target
 *
 * @param boxindex: box id
 * @param Target: Target of box
 *
 * @return none
 */
native Box_SetTarget(boxindex,Target);

/**
 * Removes a box given an id
 *
 * @param boxindex: box id
 * @param EnableBox: true to enable, false to disable
 *
 * @return none
 */
native Box_Enable(boxindex,bool:EnableBox=true);

// returns if box is enabled or not
native bool:Box_isEnable(boxindex);

// resets all variables as if you reloaded the box_engine
native Box_Reset();

native Box_ClearBoxes();

native Box_SaveToFile();

native bool:Box_LoadFromFile();

native Box_NoClip(client,bool:noclip);

// if client is in noclip
native bool:Box_GetNoClip(client);

//native Box_CountPlayersInBox(bool:InBox=true);

native Box_Toggle(bool:ToggleOnOff=false);

//native bool:Box_IsPlayerInside(client);

native bool:Box_MarkCorner(client,bool:ResetBox=false);

/**
 * Saves and Creates new box
 *
 * @param BoxBehavior: BoxBehavior bit flags
 * @param BoxTargets: BoxTargets bit flags
 * @param isENABLED: if box is enabled or not
 *
 * @return box index created
 */
native Box_SaveCurrentBox(BoxBehavior,BoxTargets,bool:isENABLED=true);


native Box_LoadBoxes(String:MapName[256]);

/**
 * Removes a box given an id
 *
 * @param boxindex: box id
 * @return True if the box was removed. False otherwise
 */
native bool:Box_Remove(boxindex);

native Box_DrawBoxID(id,client=0);

// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS
// FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS FORWARDS

//Fired every time a box is created
forward OnBoxCreated(boxindex, behaviorBitFlags, targetBitFlags, Float:BoxMin[3], Float:BoxMax[3]);

forward OnBoxRemoved(boxindex, behaviorBitFlags, targetBitFlags, Float:BoxMin[3], Float:BoxMax[3]);

forward OnBoxChanged(boxindex, behaviorBitFlags, targetBitFlags, Float:BoxMin[3], Float:BoxMax[3], bool:isBoxEnabled);

//Fired every time a box "pulses". Only enabled wards pulse
forward OnBoxPulse(boxindex, behaviorBitFlags, targetBitFlags, bool:isBoxEnabled);

//Fired every time a box "pulses" when a valid target is in range
forward OnBoxTrigger(boxindex, client, behaviorBitFlags, targetBitFlags, bool:isBoxEnabled);

//Fired every time a box "pulses" when a valid target is NOT in range
forward OnBoxNotTrigger(boxindex, client, behaviorBitFlags, targetBitFlags, bool:isBoxEnabled);


public SharedPlugin:__pl_000_box_engine =
{
	name = "000_box_engine",
	file = "000_box_engine.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_000_box_engine_SetNTVOptional()
{
	MarkNativeAsOptional("Box_IsPlayerInBox");
	MarkNativeAsOptional("Box_GetNoClip");
	MarkNativeAsOptional("Box_NoClip");
	MarkNativeAsOptional("Box_LoadFromFile");
	MarkNativeAsOptional("Box_SaveToFile");
	MarkNativeAsOptional("Box_ClearBoxes");
	MarkNativeAsOptional("Box_Reset");
	MarkNativeAsOptional("Box_isEnable");
	MarkNativeAsOptional("Box_Enable");
	MarkNativeAsOptional("Box_SetTarget");
	MarkNativeAsOptional("Box_SetBehavior");
	MarkNativeAsOptional("Box_GetTarget");
	MarkNativeAsOptional("Box_GetBehavior");
	MarkNativeAsOptional("Box_Remove");
	MarkNativeAsOptional("Box_DrawBoxID");
	MarkNativeAsOptional("Box_LoadBoxes");
	MarkNativeAsOptional("Box_SaveCurrentBox");
	MarkNativeAsOptional("Box_MarkCorner");
	MarkNativeAsOptional("Box_Toggle");
}
#endif
