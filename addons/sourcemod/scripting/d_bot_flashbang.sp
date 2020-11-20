#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
    name = "[INS] Bot have flashbang",
    description = "Replace bot smoke grenade into flashbang",
    author = "Neko-",
    version = "1.0.1",
};

new Handle:percentFlash = INVALID_HANDLE;

public OnPluginStart() 
{
    percentFlash = CreateConVar("percentage_bots_throw_flash", "70", "sets percentage of bots to throw flash instead of smoke");    
    AutoExecConfig(true,"bot_flashbang");
}

public OnClientPutInServer(client) 
{
	if(IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponSwitch, WeaponSwitchHook); 
	}
}

public Action:WeaponSwitchHook(client, weapon)
{
	decl String:sWeaponClassname[64]; 
	GetEntityClassname(weapon, sWeaponClassname, sizeof(sWeaponClassname));
	
	if(StrEqual(sWeaponClassname, "weapon_m18"))
	{
		if(GetRandomInt(0,100) < GetConVarInt(percentFlash)) //only replace flash for percentage
		{
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);
			
			new newWeapon = GivePlayerItem(client, "weapon_m84");
			new PrimaryAmmoType = GetEntProp(newWeapon, Prop_Data, "m_iPrimaryAmmoType");
			SetEntProp(client, Prop_Send, "m_iAmmo", 1, _, PrimaryAmmoType);
			InstantSwitch(client, newWeapon);
		}
	}
	
	return Plugin_Continue;
}

InstantSwitch(client, weapon, timer = 0) {
	new Float:GameTime = GetGameTime();

	if (!timer) {
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GameTime);
	}

	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GameTime);
	new ViewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	SetEntProp(ViewModel, Prop_Send, "m_nSequence", 0);
}