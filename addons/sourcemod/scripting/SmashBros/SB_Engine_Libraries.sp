//SB_Engine_Libraries.sp

public SB_Engine_Libraries_OnAllPluginsLoaded()
{
	if(LibraryExists("sb_addon_fc"))
	{
		if(FC_Enabled())
		{
			if(FC_Bhop_Enabled())
			{
				bHopEnabled = true;
			}
		}
	}
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name,"sb_addon_fc"))
	{
		if(FC_Enabled())
		{
			if(FC_Bhop_Enabled())
			{
				bHopEnabled = true;
			}
		}
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name,"sb_addon_fc"))
	{
		bHopEnabled = false;
	}
}

