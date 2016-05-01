//SB_Engine_Effects.sp


public void bloodspray(int client)
{
	float vecAngles[3];
	GetClientEyeAngles(client,vecAngles);
	float target_pos[3];
	GetClientAbsOrigin(client,target_pos);
	target_pos[2]+=45;
	TE_SetupBloodSprite(target_pos, vecAngles, {250, 250, 28, 255}, 35, mBloodSpray, mBloodDrop);
	TE_SendToAll();
}
