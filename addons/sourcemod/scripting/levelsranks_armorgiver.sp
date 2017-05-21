#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int		g_iAGLevel,
		g_iAGArmor,
		g_iAGButton[MAXPLAYERS+1];
bool		g_bAGHelmet;
Handle	g_hArmorGiver = null;

public Plugin myinfo = {name = "[LR] Module - Armor Giver", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS: LogMessage("[%s Armor Giver] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Armor Giver] Плагин работает только на CS:GO и CS:S", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("player_spawn", PlayerSpawn);
	g_hArmorGiver = RegClientCookie("LR_ArmorGiver", "LR_ArmorGiver", CookieAccess_Private);
	LoadTranslations("levels_ranks_armorgiver.phrases");
	
	for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
		if(IsClientInGame(iClient))
		{
			if(AreClientCookiesCached(iClient))
			{
				OnClientCookiesCached(iClient);
			}
		}
	}
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/armorgiver.ini");
	KeyValues hLR_AG = new KeyValues("LR_ArmorGiver");

	if(!hLR_AG.ImportFromFile(sPath) || !hLR_AG.GotoFirstSubKey())
	{
		SetFailState("[%s Armor Giver] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_AG.Rewind();

	if(hLR_AG.JumpToKey("Settings"))
	{
		g_iAGLevel = hLR_AG.GetNum("rank", 0);
		g_iAGArmor = hLR_AG.GetNum("value", 125);
		g_bAGHelmet = view_as<bool>(hLR_AG.GetNum("helmet", 1));
	}
	else SetFailState("[%s Armor Giver] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_AG;
}

public void PlayerSpawn(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsValidClient(iClient) && !g_iAGButton[iClient] && (LR_GetClientRank(iClient) >= g_iAGLevel))
	{
		SetEntProp(iClient, Prop_Send, "m_ArmorValue", g_iAGArmor);
		if(g_bAGHelmet)
		{
			SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 1);
		}
	}
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == g_iAGLevel)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);

		if(LR_GetClientRank(iClient) >= g_iAGLevel)
		{
			switch(g_iAGButton[iClient])
			{
				case 0: FormatEx(sText, sizeof(sText), "%t", "AG_On", g_iAGArmor);
				case 1: FormatEx(sText, sizeof(sText), "%t", "AG_Off", g_iAGArmor);
			}

			hMenu.AddItem("ArmorGiver", sText);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%t", "AG_RankClosed", g_iAGArmor, g_iAGLevel);
			hMenu.AddItem("ArmorGiver", sText, ITEMDRAW_DISABLED);
		}
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == g_iAGLevel)
	{
		if(strcmp(sInfo, "ArmorGiver") == 0)
		{
			switch(g_iAGButton[iClient])
			{
				case 0: g_iAGButton[iClient] = 1;
				case 1: g_iAGButton[iClient] = 0;
			}
			
			LR_MenuInventory(iClient);
		}
	}
}

public void OnClientCookiesCached(int iClient)
{
	char sCookie[8];
	GetClientCookie(iClient, g_hArmorGiver, sCookie, sizeof(sCookie));
	g_iAGButton[iClient] = StringToInt(sCookie);
} 

public void OnClientDisconnect(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		char sBuffer[8];
		FormatEx(sBuffer, sizeof(sBuffer), "%i", g_iAGButton[iClient]);
		SetClientCookie(iClient, g_hArmorGiver, sBuffer);		
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}