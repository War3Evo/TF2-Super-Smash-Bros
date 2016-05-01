//SB_001_OnGameFrame.sp

TriggerEvent()
{
	playing = false;

	int dummyresult2 = 0;

	SB_Engine_Internal_OnSB_RoundEnd();

	Call_StartForward(FHOnSB_RoundEnd);
	Call_Finish(dummyresult2);
}

public OnGameFrame(){
	//if(!started) return;
	if(!playing) return;
	if(GetClientCount()<2) return;

	for(new i=1;i<MaxClients;i++){   // was MAXPLAYERSCUSTOM
		bHasDiedThisFrame[i]=0;
	}

	if(GetTime()>=CountDownTimer)
	{
		// trigger end of round
		TriggerEvent();
	}
}
