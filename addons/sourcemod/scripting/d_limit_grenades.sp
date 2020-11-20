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
new Handle:cvarHeavyFireLimit = INVALID_HANDLE;

public OnPluginStart() 
{
    cvarEnabled = CreateConVar("grenade_limits_enabled", "1", "sets whether limit grenades is enabled");
    cvarSmokeLimit = CreateConVar("smoke_limit", "1", "amount of smoke that player can bring at a time");
    cvarFireLimit = CreateConVar("fire_limit", "1", "amount of fire grenades that player can bring at a time");
    cvarHeavyFireLimit = CreateConVar("heavy_fire_limit", "4", "amount of heavy weaponry that player can bring at a time");
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
		decl String:sWeaponName[64]; 
		GetEntityClassname(weapon, sWeaponName, sizeof(sWeaponName));
		new PrimaryAmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
		
		//Smoke		
		if(StrEqual(sWeaponName, "weapon_m18") && (PrimaryAmmoType != -1))
		{
			int nSmokeAmount = GetConVarInt(cvarSmokeLimit);
			new CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);

			if(CurrentAmmo > nSmokeAmount)
			{
				if(GetConVarBool(cvarPrintLimit))
					PrintToChat(client, "You can't have more than %i smoke. Use it wisely!", nSmokeAmount);
				SetEntProp(client, Prop_Send, "m_iAmmo", nSmokeAmount, _, PrimaryAmmoType);
			}
		}

		//firesupport
		else if(StrEqual(sWeaponName, "weapon_m79_smoke") && (PrimaryAmmoType != -1))
		{
			int nSupportAmount = GetConVarInt(cvarFireSupportLimit);
			new CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);

			if(CurrentAmmo > nSupportAmount)
			{
				if(GetConVarBool(cvarPrintLimit))
					PrintToChat(client, "You can't have more than %i fire support. Use it wisely!", nSupportAmount);
				SetEntProp(client, Prop_Send, "m_iAmmo", nSupportAmount, _, PrimaryAmmoType);
			}
		}

		//Fire
		else if( (StrEqual(sWeaponName, "weapon_anm14") || (StrEqual(sWeaponName, "weapon_molotov")) ) && (PrimaryAmmoType != -1))
		{
			int nFireAmount = GetConVarInt(cvarFireLimit);
			new CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);

			if(CurrentAmmo > nFireAmount)
			{
				if(GetConVarBool(cvarPrintLimit))
					PrintToChat(client, "You can't have more than %i fire grenade. Use it wisely!", nFireAmount);
				SetEntProp(client, Prop_Send, "m_iAmmo", nFireAmount, _, PrimaryAmmoType);
			}
		}
		//Heavy Fire
		else if( (StrEqual(sWeaponName, "weapon_c4_clicker") || StrEqual(sWeaponName, "weapon_c4_ied") || StrEqual(sWeaponName, "weapon_geballteladung") || StrEqual(sWeaponName, "weapon_hafthohlladung") || StrEqual(sWeaponName, "weapon_m79") || StrEqual(sWeaponName, "weapon_m79_napalm") ) && (PrimaryAmmoType != -1))
		{
			//PrintToChatAll("Weapon is: %s", sWeaponName);

			int nHeavyFireAmount = GetConVarInt(cvarHeavyFireLimit);
			new CurrentAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, PrimaryAmmoType);

			if(CurrentAmmo > nHeavyFireAmount)
			{
				if(GetConVarBool(cvarPrintLimit))
					PrintToChat(client, "You can't have more than %i heavy grenade. Use it wisely!", nHeavyFireAmount);
				SetEntProp(client, Prop_Send, "m_iAmmo", nHeavyFireAmount, _, PrimaryAmmoType);
			}
		}
	}
	
	return Plugin_Continue;
}