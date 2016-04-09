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

#define GAME_TITLE "SmashBros"

#define BUILD_NUMBER "m.a.n.u.a.l." // For Jenkins Builds

#define PLUGIN_VERSION "1.3."...BUILD_NUMBER

#define PLUGIN_VERSION_NUMBER 12

#define MAXPLAYERSCUSTOM 34

#define SHORTNAMELEN 16 //item or race shotnames, 15 characters
#define FULLNAMELEN 32 //item or race full names, 31 characters. RUSSIAN and other characters require more than 1 byte to store a displayed character

//=============================================================================
// Damage
//=============================================================================
#define DMG_GENERIC					0
#define DMG_CRUSH					(1 << 0)
#define DMG_BULLET					(1 << 1)
#define DMG_SLASH					(1 << 2)
#define DMG_BURN					(1 << 3)
#define DMG_VEHICLE					(1 << 4)
#define DMG_FALL					(1 << 5)
#define DMG_BLAST					(1 << 6)
#define DMG_CLUB					(1 << 7)
#define DMG_SHOCK					(1 << 8)
#define DMG_SONIC					(1 << 9)
#define DMG_ENERGYBEAM				(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB				(1 << 12)
#define DMG_ALWAYSGIB				(1 << 13)
#define DMG_DROWN					(1 << 14)
#define DMG_TIMEBASED				(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE				(1 << 15)
#define DMG_NERVEGAS				(1 << 16)
#define DMG_POISON					(1 << 17)
#define DMG_RADIATION				(1 << 18)
#define DMG_DROWNRECOVER			(1 << 19)
#define DMG_ACID					(1 << 20)
#define DMG_SLOWBURN				(1 << 21)
#define DMG_REMOVENORAGDOLL			(1 << 22)
#define DMG_PHYSGUN					(1 << 23)
#define DMG_PLASMA					(1 << 24)
#define DMG_AIRBOAT					(1 << 25)
#define DMG_DISSOLVE				(1 << 26)
#define DMG_BLAST_SURFACE			(1 << 27)
#define DMG_DIRECT					(1 << 28)
#define DMG_BUCKSHOT				(1 << 29)


// The following are color presets for the SB_FlashScreen function
#define RGBA_COLOR_RED		{255,0,0,4}
#define RGBA_COLOR_GREEN	{0,255,0,3}
#define RGBA_COLOR_BLUE		{0,0,255,3}
#define RGBA_COLOR_YELLOW	{255,255,0,3}
#define RGBA_COLOR_ORANGE	{255,69,0,3}
#define RGBA_COLOR_PURPLE	{128,0,128,3}
#define RGBA_COLOR_CYAN		{255,0,255,3}
#define RGBA_COLOR_WHITE	{255,255,255,3}
#define RGBA_COLOR_BLACK	{0,0,0,3}
#define RGBA_COLOR_GREY		{128,128,128,3}
#define RGBA_COLOR_PINK		{255,20,147,3}
#define RGBA_COLOR_MAROON	{128,0,0,3}
#define RGBA_COLOR_SKYBLUE	{135,206,25,3}
#define RGBA_COLOR_GOLD		{255,215,0,3}
#define RGBA_COLOR_BROWN	{139,69,19,3}
#define RGBA_COLOR_VIOLET	{238,130,238,3}

// The following are from the SourceSDK, used for the optional flags field of SB_FlashScreen
#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function, YOUR SCREEN DECAYS AND YOU SEE CLEARLY SLOWLY
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

// Team ID's for the Valve specific game
//0 == unassigned
// 1 == spectator
#define  TEAM_RED 2
#define  TEAM_BLUE 3

stock bool:SB_ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
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

enum SBPlayerProp
{
	iLives,
	iDamage,
	bool:SpawnedOnce,
	bool:bStatefulSpawn, //set true if spawn is a non repeated spawn. set to true on join and death, set false after spawn forward is finished.
}

native SB_SetPlayerProp(client,SBPlayerProp:property,any:value);
native any:SB_GetPlayerProp(client,SBPlayerProp:property);


