//SB_Engine_Libraries.sp

public SB_Engine_Libraries_OnAllPluginsLoaded()
{
	if(LibraryExists("sb_addon_fc"))
	{
		bHopEnabled = true;
	}
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name,"sb_addon_fc"))
	{
		bHopEnabled = true;
	}
	SB_Engine_Updater_OnLibraryAdded(name);
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name,"sb_addon_fc"))
	{
		bHopEnabled = false;
	}
}

