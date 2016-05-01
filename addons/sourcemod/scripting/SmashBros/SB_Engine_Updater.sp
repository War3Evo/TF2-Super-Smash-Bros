//SB_Engine_Updater.sp

public SB_Engine_Updater_OnPluginStart()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public SB_Engine_Updater_OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
