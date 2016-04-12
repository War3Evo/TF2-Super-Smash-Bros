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


#pragma semicolon 1

#include <sourcemod>
#include <sb_interface>

#define MIN5 "vo/announcer_ends_5min.mp3"
#define MIN2 "vo/announcer_ends_2min.mp3"
#define SEC60 "vo/announcer_ends_60sec.mp3"
#define SEC30 "vo/announcer_ends_30sec.mp3"
#define SEC20 "vo/announcer_ends_20sec.mp3"
//#define SEC10 "vo/announcer_ends_10sec.mp3"
#define SEC9 "vo/announcer_ends_9sec.mp3"
#define SEC8 "vo/announcer_ends_8sec.mp3"
#define SEC7 "vo/announcer_ends_7sec.mp3"
#define SEC6 "vo/announcer_ends_6sec.mp3"
#define SEC5 "vo/announcer_ends_5sec.mp3"
#define SEC4 "vo/announcer_ends_4sec.mp3"
#define SEC3 "vo/announcer_ends_3sec.mp3"
#define SEC2 "vo/announcer_ends_2sec.mp3"
#define SEC1 "vo/announcer_ends_1sec.mp3"

public Plugin:myinfo = {
	name = "Smash Bros Sound Engine",
	author = "El Diablo",
	description = "SB Core Plugins",
	version = PLUGIN_VERSION,
	url = "www.war3evo.info"
}

public OnPluginStart()
{
	CreateTimer(0.5,SoundTimer,_,TIMER_REPEAT);
}

public OnMapStart()
{
	PrecacheSound(MIN5);
	PrecacheSound(MIN2);
	PrecacheSound(SEC60);
	PrecacheSound(SEC30);
	PrecacheSound(SEC20);
	//PrecacheSound(SEC10);
	PrecacheSound(SEC9);
	PrecacheSound(SEC8);
	PrecacheSound(SEC7);
	PrecacheSound(SEC6);
	PrecacheSound(SEC5);
	PrecacheSound(SEC4);
	PrecacheSound(SEC3);
	PrecacheSound(SEC2);
	PrecacheSound(SEC1);
}

bool PlayOnce_5_Min = false;
bool PlayOnce_2_Min = false;
bool PlayOnce_60_sec = false;
bool PlayOnce_30_sec = false;
bool PlayOnce_20_sec = false;
//bool PlayOnce_10_sec = false;
bool PlayOnce_9_sec = false;
bool PlayOnce_8_sec = false;
bool PlayOnce_7_sec = false;
bool PlayOnce_6_sec = false;
bool PlayOnce_5_sec = false;
bool PlayOnce_4_sec = false;
bool PlayOnce_3_sec = false;
bool PlayOnce_2_sec = false;
bool PlayOnce_1_sec = false;

public OnSB_RoundEnd()
{
	PlayOnce_5_Min = false;
	PlayOnce_2_Min = false;
	PlayOnce_60_sec = false;
	PlayOnce_30_sec = false;
	PlayOnce_20_sec = false;
	//PlayOnce_10_sec = false;
	PlayOnce_9_sec = false;
	PlayOnce_8_sec = false;
	PlayOnce_7_sec = false;
	PlayOnce_6_sec = false;
	PlayOnce_5_sec = false;
	PlayOnce_4_sec = false;
	PlayOnce_3_sec = false;
	PlayOnce_2_sec = false;
	PlayOnce_1_sec = false;
}

public Action:SoundTimer(Handle:timer,any:userid)
{
	// Timer
	int iTimer = SB_GetCountDownTimer() - GetTime();
	switch (iTimer)
	{
		case 300:
		{
			// 5 mintues
			if(!PlayOnce_5_Min)
			{
				EmitSoundToAll(MIN5);
				PlayOnce_5_Min = true;
			}
		}
		case 120:
		{
			// 2 mintues
			if(!PlayOnce_2_Min)
			{
				EmitSoundToAll(MIN2);
				PlayOnce_2_Min = true;
			}
		}
		case 60:
		{
			if(!PlayOnce_60_sec)
			{
				EmitSoundToAll(SEC60);
				PlayOnce_60_sec = true;
			}
		}
		case 30:
		{
			if(!PlayOnce_30_sec)
			{
				EmitSoundToAll(SEC30);
				PlayOnce_30_sec = true;
			}
		}
		case 20:
		{
			if(!PlayOnce_20_sec)
			{
				EmitSoundToAll(SEC20);
				PlayOnce_20_sec = true;
			}
		}
		//case 10:
		//{
			//if(!PlayOnce_10_sec)
			//{
				//EmitSoundToAll(SEC10);
				//PlayOnce_10_sec = true;
			//}
		//}
		case 9:
		{
			if(!PlayOnce_9_sec)
			{
				EmitSoundToAll(SEC9);
				PlayOnce_9_sec = true;
			}
		}
		case 8:
		{
			if(!PlayOnce_8_sec)
			{
				EmitSoundToAll(SEC8);
				PlayOnce_8_sec = true;
			}
		}
		case 7:
		{
			if(!PlayOnce_7_sec)
			{
				EmitSoundToAll(SEC7);
				PlayOnce_7_sec = true;
			}
		}
		case 6:
		{
			if(!PlayOnce_6_sec)
			{
				EmitSoundToAll(SEC6);
				PlayOnce_6_sec = true;
			}
		}
		case 5:
		{
			if(!PlayOnce_5_sec)
			{
				EmitSoundToAll(SEC5);
				PlayOnce_5_sec = true;
			}
		}
		case 4:
		{
			if(!PlayOnce_4_sec)
			{
				EmitSoundToAll(SEC4);
				PlayOnce_4_sec = true;
			}
		}
		case 3:
		{
			if(!PlayOnce_3_sec)
			{
				EmitSoundToAll(SEC3);
				PlayOnce_3_sec = true;
			}
		}
		case 2:
		{
			if(!PlayOnce_2_sec)
			{
				EmitSoundToAll(SEC2);
				PlayOnce_2_sec = true;
			}
		}
		case 1:
		{
			if(!PlayOnce_1_sec)
			{
				EmitSoundToAll(SEC1);
				PlayOnce_1_sec = true;
			}
		}
	}
}
