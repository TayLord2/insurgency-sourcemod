#include <sourcemod> 
#include <sdktools>

#define PLUGIN_AUTHOR "Dan Taylor"
#define PLUGIN_DESCRIPTION "Makes hunt into survival!"
#define PLUGIN_NAME "Ultimate Survival Hunt v2"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_WORKING "0"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
};

#define TEAM_1_SEC	2
#define TEAM_2_INS	3
#define botdelay 0.0

//for messaging for respawning
new g_isHunt = 0; //is hunt gamemode to run this mod
new g_count; //number to kill for life, comes fro killcounts
new g_botdeaths = 0; //counter for bot deaths, will reward once hits g_count
new g_inc; //amount to increase respawn count by
new g_lifecount; //team lifecount
new cacheDestroyed = 0; //tracking for cache
new g_botcount; //botcount that will be set by number of players
new g_maxLives;
new grenadeEnabled; 

new g_hsEnabled = 0; //hs enable
new g_brEnabled = 0; //br enable
new g_mode = 0; //global enable

//for bot-respawn mode store the number of bot lives left
new g_remainingBotLives;
//temp storage that will be reset after hunt round is over
new oldBotCountValue;

//Trackers for dead players
new downPlayers[8]; //array of clients (players) that have died
new numDownPlayers = 0; //number of dead players 1-8
new startOfList = 1; //pointer to the longest dead player

//print delay for status updates
new g_statusDelay; 

const OFF = 0; //disable
const HS = 1; //hunt-survival - endless respawn until cache
const BR = 2; //bot-respawn - finite respawn count

new Handle:hunt_mode = INVALID_HANDLE;
//Bot-Respawn
new Handle:br_killCount = INVALID_HANDLE;
new Handle:br_killCount_1 = INVALID_HANDLE;
new Handle:br_killCount_2 = INVALID_HANDLE;
new Handle:br_killCount_3 = INVALID_HANDLE;
new Handle:br_killCount_4 = INVALID_HANDLE;
new Handle:br_respawnInc = INVALID_HANDLE;
new Handle:br_respawnStart = INVALID_HANDLE;
new Handle:br_maxLives = INVALID_HANDLE;
new Handle:br_botcount = INVALID_HANDLE;
new Handle:br_botcount_1 = INVALID_HANDLE;
new Handle:br_botcount_2 = INVALID_HANDLE;
new Handle:br_botcount_3 = INVALID_HANDLE;
new Handle:br_botcount_4 = INVALID_HANDLE;
new Handle:br_botcount_base = INVALID_HANDLE;

//Hunt-Survival
new Handle:killCount = INVALID_HANDLE;
new Handle:killCount_1 = INVALID_HANDLE;
new Handle:killCount_2 = INVALID_HANDLE;
new Handle:killCount_3 = INVALID_HANDLE;
new Handle:killCount_4 = INVALID_HANDLE;
new Handle:respawnInc = INVALID_HANDLE;
new Handle:respawnStart = INVALID_HANDLE;
new Handle:maxLives = INVALID_HANDLE;
new Handle:botcount = INVALID_HANDLE;
new Handle:botcount_1 = INVALID_HANDLE;
new Handle:botcount_2 = INVALID_HANDLE;
new Handle:botcount_3 = INVALID_HANDLE;
new Handle:botcount_4 = INVALID_HANDLE;
new Handle:grenadeKillsEnabled = INVALID_HANDLE;

//print
new Handle:statusDelay = INVALID_HANDLE;
new Handle:statusTimer = INVALID_HANDLE;

//respawn plugin handles
new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;

public void OnPluginStart()
{
    PrintToServer("Dan's Ultimate Survival Mod v2 is running");

    hunt_mode = CreateConVar("hunt_mod_enabled", "1", "1 - Enable Hunt-survival 2- Enable Bot-respawn - 0 disable");
    //hunt-survival cvars
    killCount = CreateConVar("hs_killcount", "0", "How many bots must be killed before granting respawns. If 0 then set by number of players");
    killCount_1 = CreateConVar("hs_killcount_1", "5", "How many bots must be killed before granting respawns for 1 player");
    killCount_2 = CreateConVar("hs_killcount_2", "8", "How many bots must be killed before granting respawns for 2 players");
    killCount_3 = CreateConVar("hs_killcount_3", "10", "How many bots must be killed before granting respawns for 3 players");
    killCount_4 = CreateConVar("hs_killcount_4", "15", "How many bots must be killed before granting respawns for 4 players");
    respawnInc = CreateConVar("hs_reward","1","How many respawns to give upon reaching killcount");
    respawnStart = CreateConVar("hs_start","2","How many respawns team starts with");
    botcount = CreateConVar("hs_botcount","0","How many bots to max out at? If set to 0 then will set by the number of players");
    botcount_1 = CreateConVar("hs_botcount_1","25","How many bots to have for 1 player");
    botcount_2 = CreateConVar("hs_botcount_2","28","How many bots to have for 2 player");
    botcount_3 = CreateConVar("hs_botcount_3","32","How many bots to have for 3 player");
    botcount_4 = CreateConVar("hs_botcount_4","45","How many bots to have for 4 player");
    maxLives = CreateConVar("hs_maxlives","2","Maximum number of lives that can be reached per player");
    grenadeKillsEnabled = CreateConVar("hs_grenadekills","1","Does explosive damage kill permanently?");

    //bot-respawn cvars
    br_killCount = CreateConVar("br_killcount", "0", "How many bots must be killed before granting respawns. If 0 then set by number of players");
    br_killCount_1 = CreateConVar("br_killcount_1", "5", "How many bots must be killed before granting respawns for 1 player");
    br_killCount_2 = CreateConVar("br_killcount_2", "8", "How many bots must be killed before granting respawns for 2 players");
    br_killCount_3 = CreateConVar("br_killcount_3", "10", "How many bots must be killed before granting respawns for 3 players");
    br_killCount_4 = CreateConVar("br_killcount_4", "15", "How many bots must be killed before granting respawns for 4 players");
    br_respawnInc = CreateConVar("br_reward","1","How many respawns to give upon reaching killcount");
    br_respawnStart = CreateConVar("br_start","2","How many respawns team starts with");
    br_botcount_base = CreateConVar("br_botcount_base","44","Number bots to be on the map that will respawn when killed");
    br_botcount = CreateConVar("br_botcount","0","How many bots to respawn? If set to 0 then will set by the number of players");
    br_botcount_1 = CreateConVar("br_botcount_1","40","How many bots to respawn for 1 player");
    br_botcount_2 = CreateConVar("br_botcount_2","50","How many bots to respawn for 2 player");
    br_botcount_3 = CreateConVar("br_botcount_3","60","How many bots to respawn for 3 player");
    br_botcount_4 = CreateConVar("br_botcount_4","70","How many bots to respawn for 4 player");
    br_maxLives = CreateConVar("br_maxlives","2","Maximum number of lives that can be reached per player");
    
    //print
    statusDelay = CreateConVar("statusdelay","4","Delay between printing status updates");

    //Event hooks
    HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
    HookEvent("object_destroyed", Event_ObjectDestroyed, EventHookMode_Pre);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    // HookEvent("player_pick_squad", Event_PlayerPickSquad);

    //cvar changes
    //hs
    HookConVarChange(respawnInc, CvarChangeInc);
    HookConVarChange(hunt_mode, CvarChangeMode);
    HookConVarChange(killCount, CvarChangekillCount);
    HookConVarChange(maxLives, CvarChangeMaxLives);
    HookConVarChange(respawnStart, CvarChangeStart);
    //br
    HookConVarChange(br_respawnInc, CvarChangeInc);
    HookConVarChange(br_killCount, CvarChangekillCount);
    HookConVarChange(br_maxLives, CvarChangeMaxLives);
    HookConVarChange(br_respawnStart, CvarChangeStart);
    //print
    HookConVarChange(statusDelay, CvarChangeStatus);

    //Startup respawn
    // Next 14 lines of text are taken from Andersso's DoDs respawn plugin. Thanks :)
    g_hGameConfig = LoadGameConfigFile("plugin.respawn");

    if (g_hGameConfig == INVALID_HANDLE) 
    {
        SetFailState("Fatal Error: Missing File \"plugin.respawn\"!");
    }
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "ForceRespawn");
    g_hPlayerRespawn = EndPrepSDKCall();
    if (g_hPlayerRespawn == INVALID_HANDLE)
    {
        SetFailState("Fatal Error: Unable to find signature for \"Respawn\"!");
    }
    AutoExecConfig(true, "hunt_mods");
}

// When cvar changed
public CvarChangeMode(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    if(!g_isHunt) return;
    g_mode = GetConVarInt(hunt_mode);
    
    if(g_mode == HS)
    {
        g_hsEnabled = 1;
        huntSurvivalSetup(0);
    }
    else if(g_mode == BR)
    {
        g_brEnabled = 1;
        botRespawnSetup(0);
    }
    else //if disabled then reset the changed cvars
    {
        SetConVarInt(FindConVar("ins_bot_count_hunt"), oldBotCountValue);
//        SetConVarInt(FindConVar("enable_player_respawn"),1);
    }
}
public CvarChangeMaxLives(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    if(g_hsEnabled) g_maxLives = GetConVarInt(maxLives);
    else if(g_brEnabled) g_maxLives = GetConVarInt(br_maxLives);
    
    if(g_mode != OFF)
        PrintToChatAll("Max team spawn count set to: %d",g_maxLives);        
}
public CvarChangeGrenade(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    grenadeEnabled = GetConVarInt(grenadeKillsEnabled);
}
public CvarChangeInc(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    if(g_hsEnabled) g_inc = GetConVarInt(respawnInc);
    else if(g_brEnabled) g_inc = GetConVarInt(br_respawnInc);

    if(g_mode != OFF)
        PrintToChatAll("%d team respawn are reward for every %d kills!", g_inc,g_count);    
}
public CvarChangekillCount(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{  
    if(g_hsEnabled) g_count = GetConVarInt(killCount);
    else if(g_brEnabled) g_count = GetConVarInt(br_killCount);

    if(g_mode != OFF)
        PrintToChatAll("%d team respawn are reward for every %d kills!", g_inc,g_count);
}
public CvarChangeStart(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{  
    if(g_hsEnabled) g_lifecount = GetConVarInt(respawnStart);
    else if(g_brEnabled) g_lifecount = GetConVarInt(br_respawnStart);
    if(g_mode != OFF)
        PrintToChatAll("Lifecount set to new starting value: %d", g_lifecount);
}

public CvarChangeStatus(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    if(statusTimer != INVALID_HANDLE)
        delete statusTimer;
    g_statusDelay = GetConVarInt(statusDelay);
    // PrintToServer("StatusDelay changed to %d",g_statusDelay);
    if(g_isHunt)
        statusTimer = CreateTimer(float(g_statusDelay),PrintStatus,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:sGameMode[32];
    GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
    g_isHunt = 0;
    if (StrEqual(sGameMode,"hunt"))
        g_isHunt = 1;    
    
    g_hsEnabled = 0;
    g_brEnabled = 0;
    g_mode = GetConVarInt(hunt_mode);
    if(g_mode == HS) g_hsEnabled = 1;
    else if (g_mode == BR) g_brEnabled = 1;
    
    if(!g_isHunt) return Plugin_Handled;

    g_statusDelay = GetConVarInt(statusDelay);
    if(g_hsEnabled)
    {
        huntSurvivalSetup();
    }
    else if(g_brEnabled)
    {
        botRespawnSetup();
    }
    return Plugin_Handled;
}

void huntSurvivalSetup(int printChat = 1)
{
    if(!g_hsEnabled || !g_isHunt)
        return;

    g_botdeaths = 0;
    g_lifecount = GetConVarInt(respawnStart);
    grenadeEnabled = GetConVarInt(grenadeKillsEnabled);
    g_inc = GetConVarInt(respawnInc);
    numDownPlayers = 0;
    cacheDestroyed = 0;
    startOfList = 1;
    //Save pre-existing settings
    oldBotCountValue = GetConVarInt(FindConVar("ins_bot_count_hunt"));

    g_botcount = GetConVarInt(botcount);
    int numPlayers = GetTeamSecCount();
    if(g_botcount == 0)
    {
        switch (numPlayers)
        {
            case 1: g_botcount = GetConVarInt(botcount_1);
            case 2: g_botcount = GetConVarInt(botcount_2);
            case 3: g_botcount = GetConVarInt(botcount_3);
            case 4: g_botcount = GetConVarInt(botcount_4);
            default: g_botcount = GetConVarInt(botcount_4);
        }
    }
    if(GetConVarInt(killCount) == 0)
    {
        switch (numPlayers)
        {
            case 1: g_count = GetConVarInt(killCount_1);
            case 2: g_count = GetConVarInt(killCount_2);
            case 3: g_count = GetConVarInt(killCount_3);
            case 4: g_count = GetConVarInt(killCount_4);
            default: g_count = GetConVarInt(killCount_4);
        }
    }
    else g_count = GetConVarInt(killCount);
    
    g_maxLives = GetConVarInt(maxLives)*GetTeamSecCount();

    //Let this cvar override the bot count hunt default
    SetConVarInt(FindConVar("ins_bot_count_hunt"), g_botcount);
    //disable other respawn plugins as this one will respawn players/bots
    //SetConVarInt(FindConVar("enable_player_respawn"), 0);

    if(printChat)
    {
        PrintToChatAll("Bots will respawn until cache is blown!");
        PrintToChatAll("Explosive kills are permanent");
        PrintToChatAll("%d team respawn is rewarded for every %d kills!", g_inc,g_count);        
        PrintToChatAll("Team starts with %d shared respawns",GetConVarInt(respawnStart));    
    }
    statusTimer = CreateTimer(float(g_statusDelay),PrintStatus,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

//Called via timer
public Action:PrintStatus(Handle:timer, any:client)
{
    if(!g_isHunt)
        return Plugin_Handled;
    decl String:botsRemaining[64];
    if((g_mode == BR) && (g_remainingBotLives > 0))
        Format(botsRemaining,sizeof(botsRemaining),"Incoming: %d | ",g_remainingBotLives);
    else
        Format(botsRemaining,sizeof(botsRemaining),"");
    
    decl String:textToPrint[64];
    if(numDownPlayers > 0) //no respawns and dead players
    {
        if(IsPlayer(GetClientOfUserId(downPlayers[startOfList]))) //if single player dies and is last player it will display bot name :)
            Format(textToPrint, sizeof(textToPrint),"%sNo respawns | %d/%d for %N",botsRemaining, g_botdeaths,g_count,GetClientOfUserId(downPlayers[startOfList]));
    }
    else if(g_lifecount == g_maxLives) //no dead players and max respawns
        Format(textToPrint, sizeof(textToPrint),"%sRespawns: %d/%d | Maxed",botsRemaining, g_lifecount,g_maxLives);
    else if(g_lifecount == 0)
        Format(textToPrint, sizeof(textToPrint),"%sNo respawns | %d/%d for respawn",botsRemaining,g_botdeaths,g_count);
    else //no dead player but not max lives
        Format(textToPrint, sizeof(textToPrint),"%sRespawns: %d/%d | %d/%d for respawn",botsRemaining,g_lifecount,g_maxLives,g_botdeaths,g_count);
    // PrintToServer(textToPrint);
    PrintHintTextToAll(textToPrint);
    return Plugin_Handled;   
}


void botRespawnSetup(int printChat = 1)
{
    if(!g_brEnabled || !g_isHunt)
        return;
    g_botdeaths = 0;    //bots kills incremented till reward
    g_lifecount = GetConVarInt(br_respawnStart); //team lives
    g_inc = GetConVarInt(br_respawnInc); //reward amount
    numDownPlayers = 0;
    cacheDestroyed = 0;
    startOfList = 1;
    //Save pre-existing settings before overwriting
    oldBotCountValue = GetConVarInt(FindConVar("ins_bot_count_hunt"));
    SetConVarInt(FindConVar("ins_bot_count_hunt"),GetConVarInt(br_botcount_base));
    
    g_remainingBotLives = GetConVarInt(br_botcount);
    int numPlayers = GetTeamSecCount();
    if(g_remainingBotLives == 0)
    {
        switch (numPlayers)
        {
            case 1: g_remainingBotLives = GetConVarInt(br_botcount_1);
            case 2: g_remainingBotLives = GetConVarInt(br_botcount_2);
            case 3: g_remainingBotLives = GetConVarInt(br_botcount_3);
            case 4: g_remainingBotLives = GetConVarInt(br_botcount_4);
            default: g_remainingBotLives = GetConVarInt(br_botcount_4);
        }
    }
    if(GetConVarInt(br_killCount) == 0)  //number bots required to kill for reward
    {
        switch (numPlayers)
        {
            case 1: g_count = GetConVarInt(br_killCount_1);
            case 2: g_count = GetConVarInt(br_killCount_2);
            case 3: g_count = GetConVarInt(br_killCount_3);
            case 4: g_count = GetConVarInt(br_killCount_4);
            default: g_count = GetConVarInt(br_killCount_4);
        }
    }
    else g_count = GetConVarInt(br_killCount);
    
    g_maxLives = GetConVarInt(br_maxLives)*GetTeamSecCount();

    //disable other respawn plugins as this one will respawn players/bots
    //SetConVarInt(FindConVar("enable_player_respawn"), 0);

    if(printChat)
    {
        PrintToChatAll("Intel shows %d incoming reinforcements!",g_remainingBotLives);
        PrintToChatAll("%d team respawn is rewarded for every %d kills!", g_inc,g_count);        
        PrintToChatAll("Team starts with %d shared respawns",GetConVarInt(br_respawnStart));
    }
    statusTimer = CreateTimer(float(g_statusDelay),PrintStatus,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
//In both modes players gain respawns the same, but bot respawns are handled differently
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new clientId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(clientId);

    if(!g_isHunt || (g_mode == OFF))
        return Plugin_Handled;

    if(!IsPlayer(client) && (GetClientTeam(client) == TEAM_2_INS)) //if bot died and respawn enabled
    {
        //only count bot kills if respawns aren't maxed out
        if(g_lifecount != g_maxLives) g_botdeaths++;
        
        // new killsNeeded = g_count - g_botdeaths;
        // if(numDownPlayers > 0) //If players are down then print every kill
        // {
        //     PrintToChatAll("Get %d more kill(s) to respawn %N", killsNeeded, GetClientOfUserId(downPlayers[startOfList]));
        // }
        // else//Print a message every five kills letting players know how close they are to regaining lives
        // {
        //     if((killsNeeded % 5 == 0) && killsNeeded > 0) 
        //         PrintToChatAll("Get %d more kill(s) for respawn", killsNeeded);
        // }
        if(g_botdeaths >= g_count) //if deaths reached
        {
            g_botdeaths -= g_count; //start count over

            g_lifecount += g_inc; //increment team lifecount
            RespawnDeadPlayers(); //respawn as many as lifecount allows
            if(g_lifecount >= g_maxLives)
            {
                // PrintToChatAll("Max team spawns reached: %d", g_maxLives);
                g_lifecount = g_maxLives;
            }
            // else
            //     PrintToChatAll("%d team spawn rewarded. Total respawns: %d/%d", g_inc, g_lifecount,g_maxLives);
        }
        if(g_hsEnabled) //hunt-survival mode. endless respawn till cache blown
        {
            if(!cacheDestroyed) //respawn bots if cache hasn't been destroyed yet for hs mode
            {
                char weapon[64];
                GetEventString(event,"weapon",weapon, sizeof(weapon));
                new wasGrenade = 0;
                // if(StrEqual(weapon,"grenade_anm14") | StrEqual(weapon,"grenade_molotov") | StrEqual(weapon,"grenade_m203_he") | StrEqual(weapon,"grenade_m203_incid") | StrEqual(weapon,"grenade_m67") | StrEqual(weapon,"rocket_at4")| StrEqual(weapon,"C4")| StrEqual(weapon,"rocket_m72law")| StrEqual(weapon,"rocket_rpg7"))
                if((StrContains(weapon,"grenade") != -1) || (StrContains(weapon,"rocket") != -1))
                    wasGrenade = 1;
                // PrintToServer("Grenade? %d, Weapon: %s",wasGrenade,weapon);
                // PrintToChatAll("Grenade? %d, Weapon: %s",wasGrenade,weapon);

                //Don't respawn bots kileed with explosives
                if(!grenadeEnabled || !wasGrenade)
                    CreateTimer(botdelay,RespawnPlayer2,client); //respawn bot
            }
        }
        else if (g_brEnabled) //finite respawn count
        {
            if(g_remainingBotLives > 0)
            {
                g_remainingBotLives--;
                CreateTimer(botdelay,RespawnPlayer2,client); //respawn bot
                if(g_remainingBotLives == 0)
                    PrintToChatAll("Inforcements Depleted!");
                //PrintToChatAll("%d reinforcements remaining", g_remainingBotLives);
            }
        }
    }
    else if(IsPlayer(client)) //if player died and respawn enabled
    {  
        if(g_lifecount > 0) //respawn immediately if team lifecounts exist
        {
            g_lifecount--;
            // if(g_lifecount == 0)
            // {
            //     new killsNeeded = g_count - g_botdeaths;
            //     PrintToChatAll("%N died. No respawns left. %d kills needed",client, killsNeeded);
            // }
            // else
            // {
            //     new killsNeeded = g_count - g_botdeaths;
            //     if(g_lifecount > 1)
            //         PrintToChatAll("%N died, %d respawns remaining. %d kills needed",client, g_lifecount,killsNeeded);
            //     else
            //         PrintToChatAll("%N died, %d respawn remaining. %d kills needed",client, g_lifecount,killsNeeded);
            // }

            CreateTimer(float(0),RespawnPlayer2,client);
        }
        else //otherwise add to dead list
        {
            // new killsNeeded = g_count - g_botdeaths;
            // PrintToChatAll("%N is down, %d kills needed", client, killsNeeded);
            new endOfList = startOfList + numDownPlayers; //startOfList is already pointing to first and numDownPlayers hasn't been incremented yet
            if (endOfList > 8) //keep within 1-8
                endOfList -= 8;
            downPlayers[endOfList] = clientId;
            numDownPlayers++;
        }
    }
    return Plugin_Handled;
}

public IsPlayer(client)
{
    if(IsClientConnected(client) && !IsFakeClient(client)) 
    {
        return true;
    }
    return false;
}

//Called via timer
public Action:RespawnPlayer2(Handle:timer, any:client)
{
    SDKCall(g_hPlayerRespawn, client); 
    return Plugin_Handled;   
}

//This should always respawn the entire team
//If lifecount is not high enough for whole team
//then it will respawn the whole team and set lifecount to 0
public RespawnTeam()
{
    if(numDownPlayers > 0)
        PrintToChatAll("Team respawned!");

    while(numDownPlayers > 0) //(new i = numDownPlayers; i <= 0; i--)
    {
        new clientId = downPlayers[startOfList];
        new client = GetClientOfUserId(clientId);        
        
        CreateTimer(float(0),RespawnPlayer2,client);

        g_lifecount -= 1;
        numDownPlayers--;
        startOfList++;
        if(startOfList > 8 ) //cycles 1-8
            startOfList = 1;
    }
    if (g_lifecount < 0)
        g_lifecount = 0;

    //reset down players values
    numDownPlayers = 0;
    startOfList = 1;
}

//This should only respawn players as lifecount allows
//starting with the longest dead
public RespawnDeadPlayers()
{
    if(numDownPlayers == 0)
        return;
    while(numDownPlayers > 0) //(new i = numDownPlayers; i <= 0; i--)
    {
        if(g_lifecount > 0)
        {
            new clientId = downPlayers[startOfList];
            new client = GetClientOfUserId(clientId);
            CreateTimer(float(0), RespawnPlayer2, client);

            PrintToChatAll("Respawned %N",client);
            startOfList++;
            if(startOfList > 8) //cycle 1-8
                startOfList = 1;
            numDownPlayers--;
            g_lifecount--;
        }
        else
            break;
    }


}

//if objective is destroyed just respawn dead teammates and stop respawning bots
public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!g_isHunt || (g_mode == OFF))
        return Plugin_Handled;
    new type = GetEventInt(event, "type");
    new CACHE = 0; //Some maps have explosive cars that typically have type 2 and cp -1
    if(type == CACHE)
    {
        cacheDestroyed = 1; //stops bots from spawning in hs mode
        g_lifecount += numDownPlayers; //increment lifecount only by the number of dead players
        RespawnTeam(); //Respawn whole team even if lifecount shouldn't allow it
        PrintToChatAll("Finish off the Insurgents!");
    }
    //
    //"team" "byte"
    //"attacker" "byte"
    //"cp" "short"
    //"type" "byte"
    // new team = GetEventInt(event, "team");
    // new attacker = GetEventInt(event, "attacker");
    // new attackerteam = GetEventInt(event, "attackerteam");
    // new cp = GetEventInt(event, "cp");
    // PrintToServer("Event_ObjectDestroyed: team %d attacker %d attacker_userid %d cp %d index %d type %d weaponid %d assister %d assister_userid %d attackerteam %d",team,attacker,attacker_userid,cp,index,type,weaponid,assister,assister_userid,attackerteam);
    // PrintToChatAll("Event_ObjectDestroyed: team %d attacker %d attacker_userid %d cp %d index %d type %d weaponid %d assister %d assister_userid %d attackerteam %d",team,attacker,attacker_userid,cp,index,type,weaponid,assister,assister_userid,attackerteam);
    return Plugin_Handled;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(g_isHunt)
    {
        if(g_hsEnabled) SetConVarInt(FindConVar("ins_bot_count_hunt"), oldBotCountValue); //only changed for hs mode
    //    SetConVarInt(FindConVar("enable_player_respawn"),1);
        if(statusTimer != INVALID_HANDLE)
            delete statusTimer;
    }
    return Plugin_Handled;
}

// Get current player count
public GetTeamSecCount() 
{
    new clients = 0;
    new iTeam;
    for( new i = 1; i <= GetMaxClients(); i++ ) {
        if (IsClientInGame(i) && IsClientConnected(i))
        {
            iTeam = GetClientTeam(i);
            if(iTeam == 2) //TEAM_SEC
                clients++;
        }
    }   
    return clients;
}
