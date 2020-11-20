#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
    name = "[INS] Limit Smoke & Fire",
    description = "Limit the amount of smoke & fire a player can have at a time.",
    author = "Dan",
    version = "1",
};

new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarSmokeLimit = INVALID_HANDLE;
new Handle:cvarFireLimit = INVALID_HANDLE;
new Handle:cvarPrintLimit = INVALID_HANDLE;
new Handle:cvarFireSupportLimit = INVALID_HANDLE;

public OnPluginStart() 
{
    cvarEnabled = CreateConVar("grenade_limits_enabled", "1", "sets whether limit grenades is enabled");
    cvarSmokeLimit = CreateConVar("smoke_limit", "1", "amount of smoke that player can bring at a time");
    cvarFireLimit = CreateConVar("fire_limit", "1", "amount of fire grenades that player can bring at a time");
    cvarPrintLimit = CreateConVar("print_limit", "0", "enable chat message to players when swapping to limited grenade");
    cvarFireSupportLimit = CreateConVar("m79_smoke_limit", "2", "amount of smoke that player can bring to call firesupport with");

    AutoExecConfig(true,"limit_grenades");
}

public OnClientPutInServer(client) 
{
	if(!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitchHook); 
	}
}

public Action:WeaponSwitchHook(client, weapon)
{
	if(GetConVarBool(cvarEnabled))
	{
		//Smoke
		int nSmokeAmount = GetConVarInt(cvarSmokeLimit);
		decl String:sWeaponName[64]; 
		GetEntityClassname(weapon, sWeaponName, sizeof(sWeaponName)); 

		new PrimaryAmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");

		//PrintToChatAll("Weapon is: %s", sWeaponName);
		if(StrEqual(sWeaponName, "weapon_m18") && (PrimaryAmmoType != -1))
		{
			new CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);
			if(CurrentAmmo > nSmokeAmount)
			{
				if(GetConVarBool(cvarPrintLimit))
					PrintToChat(client, "You can't have more than %i smoke. Use it wisely!", nSmokeAmount);
				SetEntProp(client, Prop_Send, "m_iAmmo", nSmokeAmount, _, PrimaryAmmoType);
			}
		}

		//firesupport
		int nSupportAmount = GetConVarInt(cvarFireSupportLimit);
		GetEntityClassname(weapon, sWeaponName, sizeof(sWeaponName)); 

		PrimaryAmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");

		//PrintToChatAll("Weapon is: %s", sWeaponName);
		if(StrEqual(sWeaponName, "weapon_m79_smoke") && (PrimaryAmmoType != -1))
		{
			new CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);
			if(CurrentAmmo > nSmokeAmount)
			{
				if(GetConVarBool(cvarPrintLimit))
					PrintToChat(client, "You can't have more than %i smoke. Use it wisely!", nSupportAmount);
				SetEntProp(client, Prop_Send, "m_iAmmo", nSupportAmount, _, PrimaryAmmoType);
			}
		}

		//Fire
		int nFireAmount = GetConVarInt(cvarFireLimit);
		GetEntityClassname(weapon, sWeaponName, sizeof(sWeaponName)); 

		PrimaryAmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");

		if( (StrEqual(sWeaponName, "weapon_anm14") || (StrEqual(sWeaponName, "weapon_molotov")) ) && (PrimaryAmmoType != -1))
		{
			new CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);
			if(CurrentAmmo > nFireAmount)
			{
				if(GetConVarBool(cvarPrintLimit))
					PrintToChat(client, "You can't have more than %i fire grenade. Use it wisely!", nFireAmount);
				SetEntProp(client, Prop_Send, "m_iAmmo", nFireAmount, _, PrimaryAmmoType);
			}
		}
	}
	
	return Plugin_Continue;
}