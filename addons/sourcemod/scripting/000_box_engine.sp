// *************************************************************************
// 000_box_engine.sp
//
// Made by  El Diablo <admin@war3evo.info>
//
//  War3Evo Community Forums: https://war3evo.info/forums/index.php

// https://forums.alliedmods.net/showthread.php?t=264551&page=3

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// DO NOT GO BELOW THIS LINE AND EDIT THE FILES UNLESS YOU KNOW WHAT YOUR DOING
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------

#pragma semicolon 1

#include <morecolors>
#include <sdktools>
#include <tf2>
#include <000_box_engine>

public Plugin:myinfo =
{
	name = "Box Engine Plugin",
	author = "El Diablo",
	description = "Box Engine",
	version = "1.0",
	url = "http://www.war3evo.info/"
};

new bool:MapStart = false;

// current box
new Float:fBoxPosMin[3];
new Float:fBoxPosMax[3];
new ClientDrawingBox=0;

new Float:corners[2][3];
new cornerSw;

new iHaloIndex;
new iBeamIndex;

new bool:boxtoggle=false;

new Handle:g_hBoxEnabled = INVALID_HANDLE;

new Handle:g_hBoxCorner1 = INVALID_HANDLE;
new Handle:g_hBoxCorner2 = INVALID_HANDLE;

new Handle:g_hBoxBehaviorBitFlags = INVALID_HANDLE;
new Handle:g_hBoxTargetBitFlags = INVALID_HANDLE;

new Handle:g_OnBoxCreatedHandle = INVALID_HANDLE;
new Handle:g_OnBoxRemovedHandle = INVALID_HANDLE;
new Handle:g_OnBoxChanged = INVALID_HANDLE;
new Handle:g_OnBoxTriggerHandle = INVALID_HANDLE;
new Handle:g_OnBoxNotTriggerHandle = INVALID_HANDLE;
new Handle:g_OnBoxPulseHandle = INVALID_HANDLE;

// Main SourceMod Functions
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Box_IsPlayerInBox", Native_Box_IsPlayerInBox);

	CreateNative("Box_GetBehavior", Native_Box_GetBehavior);
	CreateNative("Box_GetTarget", Native_Box_GetTarget);

	CreateNative("Box_SetBehavior", Native_Box_SetBehavior);
	CreateNative("Box_SetTarget", Native_Box_SetTarget);


	CreateNative("Box_GetNoClip", Native_Box_GetNoClip);

	CreateNative("Box_Reset", Native_Box_Reset);
	CreateNative("Box_ClearBoxes", Native_ClearBoxes);
	CreateNative("Box_SaveToFile", Native_Box_SaveToFile);
	CreateNative("Box_LoadFromFile", Native_Box_LoadFromFile);

	CreateNative("Box_SaveCurrentBox", Native_Box_SaveCurrentBox);

	CreateNative("Box_NoClip", Native_Box_NoClip);
	CreateNative("Box_MarkCorner", Native_Box_MarkCorner);
	CreateNative("Box_Toggle", Native_Box_Toggle);

	CreateNative("Box_DrawBoxID",Native_Box_DrawBoxID);

	CreateNative("Box_isEnable", Native_isBox_Enable);
	CreateNative("Box_Enable", Native_Box_Enable);
	CreateNative("Box_Remove", Native_Box_Remove);

	g_OnBoxCreatedHandle = CreateGlobalForward("OnBoxCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array);
	g_OnBoxRemovedHandle = CreateGlobalForward("OnBoxRemoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array);
	g_OnBoxChanged = CreateGlobalForward("OnBoxChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell);
	g_OnBoxPulseHandle = CreateGlobalForward("OnBoxPulse", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_OnBoxTriggerHandle = CreateGlobalForward("OnBoxTrigger", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_OnBoxNotTriggerHandle = CreateGlobalForward("OnBoxNotTrigger", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	RegPluginLibrary("000_box_engine");

	g_hBoxEnabled = CreateArray(1);
	g_hBoxCorner1 = CreateArray(3);
	g_hBoxCorner2 = CreateArray(3);
	g_hBoxBehaviorBitFlags = CreateArray(1);
	g_hBoxTargetBitFlags = CreateArray(1);

	return APLRes_Success;
}

stock ResetVariables()
{
	ClientDrawingBox=0;
	cornerSw=0;
	boxtoggle=false;
	ClearArray(g_hBoxEnabled);
	ClearArray(g_hBoxCorner1);
	ClearArray(g_hBoxCorner2);
	ClearArray(g_hBoxTargetBitFlags);
	ClearArray(g_hBoxBehaviorBitFlags);
}


stock PerformNoClip(client,bool:turnon)
{
	if (turnon)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		ReplyToCommand(client,"\x01[SM] \x04Noclip & God Mode on");
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		ReplyToCommand(client,"\x01[SM] \x04Noclip & God Mode off");
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

stock bool:IsTooFarFromCenter(client,Float:distance)
{
	new Float:PlayerPos[3];
	GetClientAbsOrigin(ClientDrawingBox, PlayerPos);
	new Float:fAddedVectors[3], Float:fNewVectors[3];

	AddVectors(fBoxPosMin, fBoxPosMax, fAddedVectors);

	fNewVectors[0] = FloatDiv(fAddedVectors[0],2.0);
	fNewVectors[1] = FloatDiv(fAddedVectors[1],2.0);
	fNewVectors[2] = FloatDiv(fAddedVectors[2],2.0);

	return (GetVectorDistance(fNewVectors, PlayerPos)>distance)? true:false;
}

stock Float:BoxCenter()
{
	new Float:fAddedVectors[3], Float:fNewVectors[3];

	AddVectors(fBoxPosMin, fBoxPosMax, fAddedVectors);

	fNewVectors[0] = FloatDiv(fAddedVectors[0],2.0);
	fNewVectors[1] = FloatDiv(fAddedVectors[1],2.0);
	fNewVectors[2] = FloatDiv(fAddedVectors[2],2.0);

	return fNewVectors;
}

public OnPluginStart()
{
}

stock bool:IsInBox(const Float:pos[3],Float:BoxPOSmin[3],Float:BoxPOSmax[3],bool:checkZ=true)
{
	if(IsInsideRect(pos, BoxPOSmin, BoxPOSmax,checkZ))
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock bool:IsInsideRect(const Float:Pos[3], const Float:Corner1[3], const Float:Corner2[3],bool:checkZ=true) {
	decl Float:field1[2];
	decl Float:field2[2];
	decl Float:field3[2];
	if(Corner1[0] < Corner2[0]){
		field1[0] = Corner1[0];
		field1[1] = Corner2[0];
	}else{
		field1[0] = Corner2[0];
		field1[1] = Corner1[0];
	}
	if(Corner1[1] < Corner2[1]){
		field2[0] = Corner1[1];
		field2[1] = Corner2[1];
	}else{
		field2[0] = Corner2[1];
		field2[1] = Corner1[1];
	}
	if(Corner1[2] < Corner2[2]){
		field3[0] = Corner1[2];
		field3[1] = Corner2[2];
	}else{
		field3[0] = Corner2[2];
		field3[1] = Corner1[2];
	}
	if (Pos[0] < field1[0] || Pos[0] > field1[1]) return false;
	if (Pos[1] < field2[0] || Pos[1] > field2[1]) return false;
	decl Float:zPos[3];
	// add height of character:
	zPos[2] = Pos[2]+40.0;
	if (checkZ)
		if (zPos[2] < field3[0]) return false;

	if (checkZ)
		if (Pos[2] > field3[1]) return false;

	return true;
}

/**
 * Copies a 1 dimensional static array.
 *
 * @param array			Static Array to copy from.
 * @param newArray		New Array to copy to.
 * @param size			Size of the array (or number of cells to copy)
 * @noreturn
 */
stock Array_Copy(const any:array[], any:newArray[], size)
{
	for (new i=0; i < size; i++) {
		newArray[i] = array[i];
	}
}

stock DrawBox(
	const Float:bottomCorner[3],
	const Float:upperCorner[3],
	modelIndex,
	haloIndex,
	startFrame=0,
	frameRate=30,
	Float:life=5.0,
	Float:width=5.0,
	Float:endWidth=5.0,
	fadeLength=2,
	Float:amplitude=1.0,
	const color[4]={ 255, 0, 0, 255 },
	speed=0,
	client=0)
	{
		// Create the additional fCorners of the box
		decl Float:fCorners[8][3];

		for (new i=0; i < 4; i++) {
			Array_Copy(bottomCorner,	fCorners[i],		3);
			Array_Copy(upperCorner,		fCorners[i+4],	3);
		}

		fCorners[1][0] = upperCorner[0];
		fCorners[2][0] = upperCorner[0]; fCorners[2][1] = upperCorner[1];
		fCorners[3][1] = upperCorner[1];
		fCorners[4][0] = bottomCorner[0]; fCorners[4][1] = bottomCorner[1];
		fCorners[5][1] = bottomCorner[1];
		fCorners[7][0] = bottomCorner[0];

	    // Draw all the edges

		// Horizontal Lines
		// Bottom
		for (new i=0; i < 4; i++) {
			new j = ( i == 3 ? 0 : i+1 );
			TE_SetupBeamPoints(fCorners[i], fCorners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
			if(client==0)
			{
				TE_SendToAll();
			}
			else
			{
				TE_SendToClient(client);
			}
		}

		// Top
		for (new i=4; i < 8; i++) {
			new j = ( i == 7 ? 4 : i+1 );
			TE_SetupBeamPoints(fCorners[i], fCorners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
			if(client==0)
			{
				TE_SendToAll();
			}
			else
			{
				TE_SendToClient(client);
			}
		}

		// All Vertical Lines
		for (new i=0; i < 4; i++) {
			TE_SetupBeamPoints(fCorners[i], fCorners[i+4], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
			if(client==0)
			{
				TE_SendToAll();
			}
			else
			{
				TE_SendToClient(client);
			}
		}
	}


new Float:fNextTick = 0.0;

public OnGameFrame()
{
	if(!MapStart) return;

	new Float:now = GetEngineTime();

	if (fNextTick <= now)
	{
		for(new i = 0; i < GetArraySize(g_hBoxCorner1); i++)
		{
			BoxPulse(i);
		}
		fNextTick = now + 0.1;
	}
}

public OnMapStart()
{
	MapStart = true;

	iHaloIndex = PrecacheModel("materials/sprites/halo01.vmt");
	iBeamIndex = PrecacheModel("materials/sprites/lgtning.vmt");
	CreateTimer(0.1, doTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	MapStart = false;
}

public Action:doTimer(Handle:thetimer)
{
	if(!boxtoggle) return Plugin_Continue;

	if(ValidPlayer(ClientDrawingBox,true) && cornerSw==1)
	{
		new Float:PlayerPos[3];
		GetClientAbsOrigin(ClientDrawingBox, PlayerPos);
		DrawBox(
			corners[0],
			PlayerPos,
			iBeamIndex,
			iHaloIndex,
			0,
			5,
			0.2,
			5.0,
			5.0,
			2,
			0.5,
			{ 255, 0, 0, 255 },
			20);
	}
	// some maps don't perform well with the red box on / showing
	// might be good to comment this off??  using: /* comment */
	else if(cornerSw==2)
	{
		DrawBox(
			fBoxPosMin,
			fBoxPosMax,
			iBeamIndex,
			iHaloIndex,
			0,
			5,
			0.2,
			5.0,
			5.0,
			2,
			0.5,
			{ 255, 0, 0, 255 },
			20);
	}

	return Plugin_Continue;
}

public BoxPulse(id)
{
	new Float:CornerNum1[3];
	GetArrayArray(g_hBoxCorner1, id, CornerNum1);
	new Float:CornerNum2[3];
	GetArrayArray(g_hBoxCorner2, id, CornerNum2);

	new BoxBitFlags_Targets = GetArrayCell(g_hBoxTargetBitFlags, id);
	new BoxBitFlags_Behaviors = GetArrayCell(g_hBoxBehaviorBitFlags, id);

	new bool:BoxEnabled = GetArrayCell(g_hBoxEnabled, id)?true:false;

	Call_StartForward(g_OnBoxPulseHandle);
	Call_PushCell(id);
	Call_PushCell(BoxBitFlags_Behaviors);
	Call_PushCell(BoxBitFlags_Targets);
	Call_PushCell(BoxEnabled);
	Call_Finish();

	new Float:PlayerPos[3];

	for(new i=1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i, true))
		{
			GetClientAbsOrigin(i, PlayerPos);
			if(IsInBox(PlayerPos,CornerNum1,CornerNum2))
			{
				Call_StartForward(g_OnBoxTriggerHandle);
				Call_PushCell(id);
				Call_PushCell(i);
				Call_PushCell(BoxBitFlags_Behaviors);
				Call_PushCell(BoxBitFlags_Targets);
				Call_PushCell(BoxEnabled);
				Call_Finish();
			}
			else
			{
				Call_StartForward(g_OnBoxNotTriggerHandle);
				Call_PushCell(id);
				Call_PushCell(i);
				Call_PushCell(BoxBitFlags_Behaviors);
				Call_PushCell(BoxBitFlags_Targets);
				Call_PushCell(BoxEnabled);
				Call_Finish();
			}
		}
	}
	return;
}

////////////////////////////////////////////////////////////////////////////////////
//////////// 	NATIVES
////////////////////////////////////////////////////////////////////////////////////

public Native_Box_DrawBoxID(Handle:plugin, numParams)
{
	new id = GetNativeCell(1);
	new client = GetNativeCell(2);

	if(id <= GetArraySize(g_hBoxCorner1))
	{

		new Float:CornerNum1[3];
		GetArrayArray(g_hBoxCorner1, id, CornerNum1);
		new Float:CornerNum2[3];
		GetArrayArray(g_hBoxCorner2, id, CornerNum2);

		if(ValidPlayer(client))
		{
			DrawBox(
				CornerNum1,
				CornerNum2,
				iBeamIndex,
				iHaloIndex,
				0,
				5,
				0.15,
				5.0,
				5.0,
				2,
				0.5,
				{ 255, 255, 0, 255 },
				20,
				client);
		}
		else
		{
			DrawBox(
				CornerNum1,
				CornerNum2,
				iBeamIndex,
				iHaloIndex,
				0,
				5,
				0.15,
				5.0,
				5.0,
				2,
				0.5,
				{ 255, 255, 0, 255 },
				20);
		}
	}
}

public Native_Box_IsPlayerInBox(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		new BoxIndex = GetNativeCell(2);

		if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxEnabled))
		{
			new Float:PlayerPos[3];
			GetClientAbsOrigin(client, PlayerPos);

			new Float:CornerNum1[3];
			GetArrayArray(g_hBoxCorner1, BoxIndex, CornerNum1);
			new Float:CornerNum2[3];
			GetArrayArray(g_hBoxCorner2, BoxIndex, CornerNum2);

			if(IsInBox(PlayerPos,CornerNum1,CornerNum2))
			{
				return true;
			}
		}
	}
	return false;
}

public Native_Box_Toggle(Handle:plugin, numParams)
{
	boxtoggle = bool:GetNativeCell(1);
}

public Native_Box_GetNoClip(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(ValidPlayer(client))
	{
		if(GetEntityMoveType(client) != MOVETYPE_WALK)
		{
			return true;
		}
	}
	return false;
}

public Native_Box_NoClip(Handle:plugin, numParams)
{
	PerformNoClip(GetNativeCell(1),bool:GetNativeCell(2));
}

public Native_Box_MarkCorner(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new ResetBox = bool:GetNativeCell(2);

	if(ResetBox) cornerSw=2;

	if(!ValidPlayer(client)) return 2;

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);

	if (cornerSw >= 2) {
		ClientDrawingBox = client;
		cornerSw = 0;
		CPrintToChat(client,"{red}CORNERS READY (Mark a corner to start)!");
		return cornerSw;
	}

	if (cornerSw==0)
	{
		ClientDrawingBox = client;
		cornerSw++;
		corners[0]=vec;
		fBoxPosMin=corners[0];
		CPrintToChat(client,"{red}Marked a corner! %.3f %.3f %.3f",corners[0][0],corners[0][1],corners[0][2]);
		PerformNoClip(client,true);
		return cornerSw;
	}

	ClientDrawingBox = 0;
	cornerSw++;
	corners[1]=vec;
	CPrintToChat(client,"{red}Marked the other corner! (noclip off!) %.3f %.3f %.3f",corners[1][0],corners[1][1],corners[1][2]);
	PerformNoClip(client,false);

	fBoxPosMin=corners[0];
	fBoxPosMax=corners[1];
	CPrintToChat(client,"{red}CORNERS ACTIVE!");
	return cornerSw;
}

public Native_Box_SaveCurrentBox(Handle:plugin, numParams)
{
	new id = PushArrayArray(g_hBoxCorner1, fBoxPosMin);
	PushArrayArray(g_hBoxCorner2, fBoxPosMax);

	new BehaviorBITFLAGS = GetNativeCell(1);
	new TargetBITFLAGS = GetNativeCell(2);
	new isENABLED = bool:GetNativeCell(3)?1:0;

	PushArrayCell(g_hBoxEnabled, isENABLED);
	PushArrayCell(g_hBoxBehaviorBitFlags, BehaviorBITFLAGS);
	PushArrayCell(g_hBoxTargetBitFlags, TargetBITFLAGS);

	Call_StartForward(g_OnBoxCreatedHandle);
	Call_PushCell(id);
	Call_PushCell(BehaviorBITFLAGS);
	Call_PushCell(TargetBITFLAGS);
	Call_PushArray(fBoxPosMin,sizeof(fBoxPosMin));
	Call_PushArray(fBoxPosMax,sizeof(fBoxPosMax));
	Call_Finish();

	return id;
}

public Native_isBox_Enable(Handle:plugin, numParams)
{
	new BoxIndex = GetNativeCell(1);

	if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxEnabled))
	{
		if(GetArrayCell(g_hBoxEnabled, BoxIndex)>0)
		{
			return true;
		}
	}
	return false;
}

public Native_Box_GetBehavior(Handle:plugin, numParams)
{
	new BoxIndex = GetNativeCell(1);

	if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxEnabled))
	{
		return GetArrayCell(g_hBoxBehaviorBitFlags, BoxIndex);
	}
	return 0;
}

public Native_Box_GetTarget(Handle:plugin, numParams)
{
	new BoxIndex = GetNativeCell(1);

	if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxEnabled))
	{
		return GetArrayCell(g_hBoxTargetBitFlags, BoxIndex);
	}
	return 0;
}

public Native_Box_SetTarget(Handle:plugin, numParams)
{
	new BoxIndex = GetNativeCell(1);

	if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxEnabled))
	{
		new BoxBitFlags_Targets = GetNativeCell(2);
		SetArrayCell(g_hBoxTargetBitFlags, BoxIndex, BoxBitFlags_Targets);

		new bool:bISboxEnabled = GetArrayCell(g_hBoxEnabled, BoxIndex)?true:false;

		new Float:CornerNum1[3];
		GetArrayArray(g_hBoxCorner1, BoxIndex, CornerNum1);
		new Float:CornerNum2[3];
		GetArrayArray(g_hBoxCorner2, BoxIndex, CornerNum2);

		new BoxBitFlags_Behaviors = GetArrayCell(g_hBoxBehaviorBitFlags, BoxIndex);

		Call_StartForward(g_OnBoxChanged);
		Call_PushCell(BoxIndex);
		Call_PushCell(BoxBitFlags_Behaviors);
		Call_PushCell(BoxBitFlags_Targets);
		Call_PushArray(CornerNum1,sizeof(CornerNum1));
		Call_PushArray(CornerNum2,sizeof(CornerNum2));
		Call_PushCell(bISboxEnabled);
		Call_Finish();
	}
}

public Native_Box_SetBehavior(Handle:plugin, numParams)
{
	new BoxIndex = GetNativeCell(1);

	if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxEnabled))
	{
		new BoxBitFlags_Behaviors = GetNativeCell(2);
		SetArrayCell(g_hBoxBehaviorBitFlags, BoxIndex, BoxBitFlags_Behaviors);

		new bool:bISboxEnabled = GetArrayCell(g_hBoxEnabled, BoxIndex)?true:false;

		new Float:CornerNum1[3];
		GetArrayArray(g_hBoxCorner1, BoxIndex, CornerNum1);
		new Float:CornerNum2[3];
		GetArrayArray(g_hBoxCorner2, BoxIndex, CornerNum2);

		new BoxBitFlags_Targets = GetArrayCell(g_hBoxTargetBitFlags, BoxIndex);

		Call_StartForward(g_OnBoxChanged);
		Call_PushCell(BoxIndex);
		Call_PushCell(BoxBitFlags_Behaviors);
		Call_PushCell(BoxBitFlags_Targets);
		Call_PushArray(CornerNum1,sizeof(CornerNum1));
		Call_PushArray(CornerNum2,sizeof(CornerNum2));
		Call_PushCell(bISboxEnabled);
		Call_Finish();
	}
}

public Native_Box_Enable(Handle:plugin, numParams)
{
	new BoxIndex = GetNativeCell(1);

	if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxEnabled))
	{
		new bool:bISboxEnabled = bool:GetNativeCell(2);
		new isBoxEnabled = bISboxEnabled?1:0;
		SetArrayCell(g_hBoxEnabled, BoxIndex, isBoxEnabled);

		new Float:CornerNum1[3];
		GetArrayArray(g_hBoxCorner1, BoxIndex, CornerNum1);
		new Float:CornerNum2[3];
		GetArrayArray(g_hBoxCorner2, BoxIndex, CornerNum2);

		new BoxBitFlags_Targets = GetArrayCell(g_hBoxTargetBitFlags, BoxIndex);
		new BoxBitFlags_Behaviors = GetArrayCell(g_hBoxBehaviorBitFlags, BoxIndex);

		Call_StartForward(g_OnBoxChanged);
		Call_PushCell(BoxIndex);
		Call_PushCell(BoxBitFlags_Behaviors);
		Call_PushCell(BoxBitFlags_Targets);
		Call_PushArray(CornerNum1,sizeof(CornerNum1));
		Call_PushArray(CornerNum2,sizeof(CornerNum2));
		Call_PushCell(bISboxEnabled);
		Call_Finish();
	}
}

public Native_Box_Remove(Handle:plugin, numParams)
{
	new BoxIndex = GetNativeCell(1);

	if(GetArraySize(g_hBoxEnabled)>0 && BoxIndex <= GetArraySize(g_hBoxCorner1))
	{
		new Float:CornerNum1[3];
		GetArrayArray(g_hBoxCorner1, BoxIndex, CornerNum1);
		new Float:CornerNum2[3];
		GetArrayArray(g_hBoxCorner2, BoxIndex, CornerNum2);

		new BoxBitFlags_Targets = GetArrayCell(g_hBoxTargetBitFlags, BoxIndex);
		new BoxBitFlags_Behaviors = GetArrayCell(g_hBoxBehaviorBitFlags, BoxIndex);

		RemoveFromArray(g_hBoxEnabled,BoxIndex);
		RemoveFromArray(g_hBoxCorner1,BoxIndex);
		RemoveFromArray(g_hBoxCorner2,BoxIndex);
		RemoveFromArray(g_hBoxTargetBitFlags,BoxIndex);
		RemoveFromArray(g_hBoxBehaviorBitFlags,BoxIndex);

		Call_StartForward(g_OnBoxRemovedHandle);
		Call_PushCell(BoxIndex);
		Call_PushCell(BoxBitFlags_Behaviors);
		Call_PushCell(BoxBitFlags_Targets);
		Call_PushArray(CornerNum1,sizeof(CornerNum1));
		Call_PushArray(CornerNum2,sizeof(CornerNum2));
		Call_Finish();

		return true;
	}
	return false;
}

stock TE_ParticleToClient(client,
String:Name[],
Float:origin[3]=NULL_VECTOR,
Float:start[3]=NULL_VECTOR,
Float:angles[3]=NULL_VECTOR,
entindex=-1,
attachtype=-1,
attachpoint=-1,
bool:resetParticles=true,
Float:delay=0.0)
{
	// find string table
	new tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx==INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return 0;
	}

	// find particle index
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	new i;
	for (i=0; i<count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx==INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return 0;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	if (entindex!=-1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype!=-1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint!=-1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
	if(client==0)
	{
		TE_SendToAll(delay);
	}
	else
	{
		TE_SendToClient(client, delay);
	}
	return 0;
}

public Native_Box_SaveToFile(Handle:plugin, numParams)
{
	new String:name[64];
	new Float:CornerNum1[3];
	new Float:CornerNum2[3];
	new BoxBitFlags_Targets;
	new BoxBitFlags_Behaviors;
	new BoxBitFlags_isENABLED;

	new String:path[1024];
	new String:pathname[1024];
	new String:mapname[1024];

	BuildPath(Path_SM,path,sizeof(path),"configs/boxes");

	if(!DirExists(path))
	{
		CreateDirectory(path, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_EXEC);
	}

	GetCurrentMap(STRING(mapname));

	Format(STRING(pathname), "configs/boxes/%s.cfg", mapname);

	BuildPath(Path_SM,path,sizeof(path),pathname);

	new Handle:boxKV = CreateKeyValues("Boxes");

	for(new i = 0; i < GetArraySize(g_hBoxCorner1); i++)
	{
		GetArrayArray(g_hBoxCorner1, i, CornerNum1);
		GetArrayArray(g_hBoxCorner2, i, CornerNum2);

		BoxBitFlags_isENABLED = GetArrayCell(g_hBoxEnabled, i);

		BoxBitFlags_Targets = GetArrayCell(g_hBoxTargetBitFlags, i);
		BoxBitFlags_Behaviors = GetArrayCell(g_hBoxBehaviorBitFlags, i);

		Format(STRING(name), "box%d", i);

		KvJumpToKey(boxKV, name, true);

		KvSetNum(boxKV, "enabled", BoxBitFlags_isENABLED);

		KvSetVector(boxKV, "CornerNum1", CornerNum1);
		KvSetVector(boxKV, "CornerNum2", CornerNum2);

		KvSetNum(boxKV, "targetsbitflags", BoxBitFlags_Targets);
		KvSetNum(boxKV, "behaviorsbitflags", BoxBitFlags_Behaviors);

		KvRewind(boxKV);
	}
	KeyValuesToFile(boxKV, path);
	CloseHandle(boxKV);
}

public Native_Box_LoadFromFile(Handle:plugin, numParams)
{
	new String:name[64];
	new Float:CornerNum1[3];
	new Float:CornerNum2[3];
	new BoxBitFlags_Targets;
	new BoxBitFlags_Behaviors;
	new BoxBitFlags_isENABLED;
	new String:mapname[1024];
	new String:pathname[1024];
	new String:path[1024];

	GetCurrentMap(STRING(mapname));

	Format(STRING(pathname), "configs/boxes/%s.cfg", mapname);

	BuildPath(Path_SM,path,sizeof(path),pathname);

	new Handle:boxKV = CreateKeyValues("Boxes");

	if (!FileToKeyValues(boxKV, path))
	{
		CloseHandle(boxKV);
		return false;
	}

	ClearArray(g_hBoxCorner1);
	ClearArray(g_hBoxCorner2);
	ClearArray(g_hBoxTargetBitFlags);
	ClearArray(g_hBoxBehaviorBitFlags);

	new i = 0;

	KvRewind(boxKV);

	Format(STRING(name), "box%d", i);

	if(KvJumpToKey(boxKV, name, false))
	{
		do
		{
			//PrintToChatAll("Loading %s",name);

			KvGetVector(boxKV, "CornerNum1", CornerNum1, CornerNum1);
			KvGetVector(boxKV, "CornerNum2", CornerNum2, CornerNum2);

			BoxBitFlags_isENABLED = KvGetNum(boxKV, "enabled", 1);

			BoxBitFlags_Targets = KvGetNum(boxKV, "targetsbitflags", 0);
			BoxBitFlags_Behaviors = KvGetNum(boxKV, "behaviorsbitflags", 0);

			PushArrayArray(g_hBoxCorner1, CornerNum1);
			PushArrayArray(g_hBoxCorner2, CornerNum2);

			PushArrayCell(g_hBoxEnabled, BoxBitFlags_isENABLED);

			PushArrayCell(g_hBoxBehaviorBitFlags, BoxBitFlags_Behaviors);
			PushArrayCell(g_hBoxTargetBitFlags, BoxBitFlags_Targets);

			if(!KvGoBack(boxKV))
			{
				//PrintToChatAll("!KvGoBack(boxKV) [i = %d]",i);
			}

			i++;
			Format(STRING(name), "box%d", i);
		} while (KvJumpToKey(boxKV, name, false));
	}

	CloseHandle(boxKV);

	return true;
}

public Native_ClearBoxes(Handle:plugin, numParams)
{
	ClearArray(g_hBoxCorner1);
	ClearArray(g_hBoxCorner2);
	ClearArray(g_hBoxTargetBitFlags);
	ClearArray(g_hBoxBehaviorBitFlags);
}

public Native_Box_Reset(Handle:plugin, numParams)
{
	ResetVariables();
}
