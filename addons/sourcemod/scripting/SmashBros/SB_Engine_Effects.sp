//SB_Engine_Effects.sp

stock SetTeam(const iEntityIndex,iTeamIndex) {SetEntProp(iEntityIndex, Prop_Send, "m_iTeamNum", iTeamIndex);}
stock GetTeam(const iEntityIndex) {return GetEntProp(iEntityIndex, Prop_Data, "m_iTeamNum");}

stock GetEntityOrigin(const iEntityIndex,Float:vecOrigin[3]) {GetEntPropVector(iEntityIndex, Prop_Send, "m_vecOrigin", vecOrigin);}
stock GetEntityAngles(const iEntityIndex,Float:vecAngles[3]) {GetEntPropVector(iEntityIndex, Prop_Send, "m_angRotation" , vecAngles);}

public void bloodspray(int client)
{
	if(!g_sb_enabled) return;

	float vecAngles[3];
	GetClientEyeAngles(client,vecAngles);
	float target_pos[3];
	GetClientAbsOrigin(client,target_pos);
	target_pos[2]+=45;
	TE_SetupBloodSprite(target_pos, vecAngles, {250, 250, 28, 255}, 35, mBloodSpray, mBloodDrop);
	TE_SendToAll();
}

//CreateTimer(0.1,RuptureCheckLoop,_,TIMER_REPEAT);
public void Gore(int client)
{
	WriteParticle(client, "blood_spray_red_01_far");
	WriteParticle(client, "blood_impact_red_01");
}
WriteParticle(Ent, String:ParticleName[])
{
	//Declare:
	int Particle;
	char tName[64];

	//Initialize:
	Particle = CreateEntityByName("info_particle_system");

	//Validate:
	if(IsValidEdict(Particle))
	{

		//Declare:
		float Position[3], Angles[3];

		//Initialize:
		Angles[0] = GetRandomFloat(0.0, 360.0);
		Angles[1] = GetRandomFloat(0.0, 15.0);
		Angles[2] = GetRandomFloat(0.0, 15.0);

		//Origin:
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);
		Position[2] += GetRandomFloat(35.0, 65.0);
		TeleportEntity(Particle, Position, Angles, NULL_VECTOR);

		//Properties:
		GetEntPropString(Ent, Prop_Data, "m_iName", tName, sizeof(tName));
		StrCat(tName,63,"unambiguate");
		DispatchKeyValue(Particle, "targetname", "TF2Particle");
		DispatchKeyValue(Particle, "parentname", tName);
		DispatchKeyValue(Particle, "effect_name", ParticleName);

		//Spawn:
		DispatchSpawn(Particle);

		//Parent:
		//SetVariantString(tName);
		//AcceptEntityInput(Particle, "SetParent", -1, -1, 0);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");

		//Delete:
		CreateTimer(6.0, DeleteParticle, Particle);
	}
}

//Delete:
public Action DeleteParticle(Handle Timer, any Particle)
{

	//Validate:
	if(IsValidEntity(Particle))
	{

		//Declare:
		char Classname[64];

		//Initialize:
		GetEdictClassname(Particle, Classname, sizeof(Classname));

		//Is a Particle:
		if(StrEqual(Classname, "info_particle_system", false))
		{

			//Delete:
			RemoveEdict(Particle);
		}
	}
}

public CreateRagDoll(int owner)
{
	if(!g_sb_enabled) return;

	//Spawn a corpse :o
	int Ragdoll = CreateEntityByName("prop_ragdoll");
	if(IsValidEntity(Ragdoll))
	{
		char ModelName[128];
		GetEntPropString(owner, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
		if(strlen(ModelName)>0)
		{

			//if(ValidPlayer(owner))
			//{
				//decl String:ClientName[128];
				//GetClientName(owner,ClientName,sizeof(ClientName));
				//DP("owner = %s",ClientName);
			//}

			//DP("owner of ragdolll = %d",owner);

			int iTeam=GetTeam(owner);
			if( iTeam==3) {
				SetVariantInt(1);
				AcceptEntityInput(Ragdoll, "Skin");
			}

			float Position[3], Angles[3];
			GetEntityOrigin(owner,Position);
			GetEntityAngles(owner,Angles);
			SetEntityModel(Ragdoll,ModelName);
			SetEntityMoveType(Ragdoll, MOVETYPE_VPHYSICS);

			//SetEntProp(Ragdoll, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NONE); //COLLISION_GROUP_NPC

			//DispatchKeyValue(Ragdoll, "Solid", "0");
			//SetEntProp(Ragdoll, Prop_Send, "m_nSolidType", 0);
			//SetEntProp(Ragdoll, Prop_Send, "m_CollisionGroup", 0);

			//SetEntProp(Ragdoll, Prop_Data, "m_usSolidFlags", 16);
			DispatchSpawn(Ragdoll);

			AcceptEntityInput( Ragdoll, "DisableCollision" );
			//AcceptEntityInput(Ragdoll, "EnableCollision");
			//AcceptEntityInput(Ragdoll, "TurnOn", Ragdoll, Ragdoll, 0);
			Position[2]+=35;
			//using the explosion as some sort of "smoke" because it looks realy shitty when spawning just a ragdoll..
			//TE_SetupExplosion(Position, ExplosionSprite, 1.0, 0, TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NODLIGHTS, 0 , 0);
			//TE_SendToAll();
			TeleportEntity(Ragdoll, Position, Angles, NULL_VECTOR);
			CreateTimer(GetRandomFloat(1.0, 3.0), RemoveGib,EntIndexToEntRef(Ragdoll));
		}
	}
}
public Action RemoveGib(Handle Timer, any Ref)
{
	int Ent = EntRefToEntIndex(Ref);
	if (Ent > 0 && IsValidEdict(Ent))
	{
		//RemoveEdict(Ent);
		AcceptEntityInput(Ent, "Kill");
	}
}
