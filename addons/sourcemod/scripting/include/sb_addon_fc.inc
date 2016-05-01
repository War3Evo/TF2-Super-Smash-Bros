#if defined _sb_addon_fc_included
  #endinput
#endif
#define _sb_addon_fc_included

//Natives
native bool FC_Enabled();
native bool FC_Bhop_Enabled();

/**
 * Set Bunny Hopping for client(s).
 *
 * @param client			Client to set bunny hopping.
 * @param enabled		Bool value for status: (1 = Enabled, 0 = Disabled)
 * @param lazymode		Bool value for lazy mode: (1 = Hold Space bar, 0 = Don't hold Space bar)
 * @param multi			Float value for horizontal velocity.
 * @param zmulti			Float value for vertical velocity.
 **/
native void FC_SetBhop(client, bool:enabled = false, bool:lazymode = false, Float:multi = 1.0, Float:zmulti = 1.0);

native void FC_SetBhop2(int client, bool enabled = false, bool lazymode = false);

/**
 * Set Bunny Hopping for client(s).
 *
 * @param client			Client to check for bunny hopping.
 *
 * @return				True if enabled, false otherwise.
 * @error				Invalid client or fields.
 **/
native bool FC_BhopStatus(client);

public SharedPlugin:__pl_sb_addon_fc =
{
	name = "sb_addon_fc",
	file = "sb_addon_fc.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_fc_SetNTVOptional()
{
	MarkNativeAsOptional("FC_SetBhop");
	MarkNativeAsOptional("FC_SetBhop2");
	MarkNativeAsOptional("FC_BhopStatus");
	MarkNativeAsOptional("FC_Enabled");
	MarkNativeAsOptional("FC_Bhop_Enabled");
}
#endif
