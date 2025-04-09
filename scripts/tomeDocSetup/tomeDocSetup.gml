
#region System(don't mess with these)

global.__tomeFileArray = [];
global.__tomeAdditionalSidebarItemsArray = [];
global.__tomeHomepage = "Homepage";
global.__tomeLatestDocVersion = "Current-Version";
global.__tomeNavbarItemsArray = [];

#endregion

/*
	Add all the files you wish to be parsed here!
	                                            */
tome_add_script("Cupidon")			
												
tome_set_site_description("The documentation for Cupidon. A small library for creating easy parabola for GameMaker");
tome_set_site_name("Cupidon - Wiki");
tome_set_site_latest_version("Beta 1");
tome_set_site_older_versions(["Beta 1"]);
tome_set_site_theme_color("#FFFFFF");