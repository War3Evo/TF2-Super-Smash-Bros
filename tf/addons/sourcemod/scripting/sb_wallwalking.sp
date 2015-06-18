//Wall Walking v1.1 by Pinkfairie

//Termination:
#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <DiabloStocks>

//Definitions:
#define Speed 200

//Variables:
//static bool:AllowWallWalking[33] = false;

//int ClientTracer;

int WaitTime[MAXPLAYERS + 1] = {0, ...};

//Prethink:
public OnGameFrame()
{

	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	int CurrentTime = GetTime();

	//Loop:
	for(new X = 1; X < MaxPlayers; X++)
	{

		//Connected:
		if(WaitTime[X] <= CurrentTime && IsClientConnected(X) && IsClientInGame(X))
		{

			//Alive:
			if(IsPlayerAlive(X))
			{

				//Wall?
				new bool:NearWall = false;

				/*
				//Circle:
				for(new AngleRotate = 0; AngleRotate < 360; AngleRotate += 30)
				{

					//Declare:
					decl Handle:TraceRay;
					decl Float:StartOrigin[3], Float:Angles[3];

					//Initialize:
					Angles[0] = 0.0;
					Angles[2] = 0.0;
					Angles[1] = float(AngleRotate);
					GetClientEyePosition(X, StartOrigin);

					//Ray: CONTENTS_SOLID
					//TraceRay = TR_TraceRayEx(StartOrigin, Angles, MASK_SOLID, RayType_Infinite);
					TraceRay = TR_TraceRayEx(StartOrigin, Angles, CONTENTS_SOLID, RayType_Infinite);

					//Collision:
					if(TR_DidHit(TraceRay))
					{

						//Declare:
						decl Float:Distance;
						decl Float:EndOrigin[3];

						//Retrieve:
						TR_GetEndPosition(EndOrigin, TraceRay);

						//Distance:
						Distance = (GetVectorDistance(StartOrigin, EndOrigin));

						//Allowed:
						if(GetClientButtons(X) & IN_ATTACK)
						{
							if(Distance < 25) NearWall = true;
						}
						//if(AllowWallWalking[X]) if(Distance < 50) NearWall = true;

					}

					//Close:
					CloseHandle(TraceRay);

				}*/

				//Ceiling:
				decl Handle:TraceRay;
				decl Float:startpos[3];
				//new Float:Angles[3] =  {270.0, 0.0, 0.0};
				new Float:Angles[3];
				new Float:endpos[3];
				new Float:dir[3];

				//Initialize:
				GetClientEyePosition(X, startpos);

				GetClientEyeAngles(X, Angles);

				Angles[0] = 0.0;
				Angles[2] = 0.0;

				GetAngleVectors(Angles, dir, NULL_VECTOR, NULL_VECTOR);

				ScaleVector(dir, 25.0);

				AddVectors(startpos, dir, endpos);

				//ClientTracer=X;

				TraceRay = TR_TraceRayFilterEx(startpos,endpos,MASK_SOLID,RayType_EndPoint,AimTargetFilter);
				//TR_GetEndPosition(endpos);

				//Ray:
				//TraceRay = TR_TraceRayEx(StartOrigin, Angles, MASK_SOLID, RayType_Infinite);
				//TraceRay = TR_TraceRayEx(StartOrigin, Angles, CONTENTS_SOLID, RayType_Infinite);

				//Collision:
				if(TR_DidHit(TraceRay))
				{
					//Declare:
					decl Float:Distance;
					//decl Float:EndOrigin[3];

					//Retrieve:
					//TR_GetEndPosition(EndOrigin, TraceRay);
					TR_GetEndPosition(endpos, TraceRay);

					//Distance:
					Distance = (GetVectorDistance(startpos, endpos));

					//Allowed:
					//if(AllowWallWalking[X]) if(Distance < 25) NearWall = true;
					if(GetClientButtons(X) & IN_ATTACK)
					{
						if(Distance < 50.0) NearWall = true;
						//NearWall = true;
					}
				}

				//Close:
				CloseHandle(TraceRay);

				//Near:
				if(NearWall)
				{

					//Almost Zero:
					SetEntityGravity(X, Pow(Pow(100.0, 3.0), -1.0));

					//Buttons:
					decl ButtonBitsum;
					ButtonBitsum = GetClientButtons(X);

					//Origin:
					decl Float:ClientOrigin[3];
					GetClientAbsOrigin(X, ClientOrigin);

					//Angles:
					decl Float:ClientEyeAngles[3];
					GetClientEyeAngles(X, ClientEyeAngles);

					//Declare:
					decl Float:VeloX, Float:VeloY, Float:VeloZ;

					//Initialize:
					ClientEyeAngles[0] = -89.0;

					VeloX = (Speed * Cosine(DegToRad(ClientEyeAngles[1])));
					VeloY = (Speed * Sine(DegToRad(ClientEyeAngles[1])));
					VeloZ = (Speed * Sine(DegToRad(ClientEyeAngles[0])));


					//Jumping:
					if(ButtonBitsum & IN_JUMP)
					{

						WaitTime[X] = CurrentTime + 1;

						//Stop:
						new Float:Velocity[3] = {0.0, 0.0, 0.0};
						Velocity[0] = VeloX;
						Velocity[1] = VeloY;
						Velocity[2] = (VeloZ - (VeloZ * 10));
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);

						CreateTimer(0.1,StopVelocity,X);
					}

					//Forward:
					/*
					if(ButtonBitsum & IN_FORWARD)
					{

						//Forward:
						new Float:Velocity[3];
						Velocity[0] = VeloX;
						Velocity[1] = VeloY;
						Velocity[2] = (VeloZ - (VeloZ * 2));
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

					//Backward:
					else if(ButtonBitsum & IN_BACK)
					{

						//Backward:
						new Float:Velocity[3];
						Velocity[0] = (VeloX - (VeloX * 2));
						Velocity[1] = (VeloY - (VeloY * 2));
						Velocity[2] = VeloZ;
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}*/

					//Null:
					else
					{

						//Stop:
						new Float:Velocity[3] = {0.0, 0.0, 0.0};
						TeleportEntity(X, ClientOrigin, NULL_VECTOR, Velocity);
					}

				}

				//Default:
				else SetEntityGravity(X, 1.0);
			}

		}

	}

}

public Action:StopVelocity(Handle:timer,any:client)
{
	if(client)
	{
		decl Float:ClientOrigin[3];
		GetClientAbsOrigin(client, ClientOrigin);

		new Float:Velocity[3] = {0.0, 0.0, 0.0};
		TeleportEntity(client, ClientOrigin, NULL_VECTOR, Velocity);
	}
}

public bool:AimTargetFilter(entity,mask)
{
	//return !(entity==ClientTracer);
	return !(ValidPlayer(entity));
}

//Information:
public Plugin:myinfo =
{

	//Initialize:
	name = "Wallwalk",
	author = "Pinkfairie & El Diablo",
	description = "Allows users to cling to walls",
	version = "1.1",
	url = "Http://www.myspace.com/josephmaley"
}
