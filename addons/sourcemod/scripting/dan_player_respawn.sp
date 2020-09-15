
#include <sourcemod> 
#include <sdktools>

#define PLUGIN_AUTHOR "Dan Taylor"
#define PLUGIN_DESCRIPTION "Respawn players"
#define PLUGIN_NAME "Player Respawn"
#define PLUGIN_VERSION "3.1"
#define PLUGIN_WORKING "0"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
};

#define SPECTATOR_TEAM	0
#define TEAM_SPEC 	1
#define SECURITY		2
#define INSURGENTS		3

//respawn plugin handles
new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;

//print
new Handle:statusTimer = INVALID_HANDLE;
//print delay for status updates
new g_statusDelay; 

//Player respawn cvars
new Handle:bPlayerRespawnEnabled = INVALID_HANDLE;
new Handle:bRespawnsResetAfterObjective = INVALID_HANDLE;
new Handle:iLifeBase = INVALID_HANDLE;
new Handle:iLifeBase_1 = INVALID_HANDLE;
new Handle:iRespawnDelay = INVALID_HANDLE;
new Handle:bIndividualLives = INVALID_HANDLE;

//player respawn cvars for hunt
new Handle:bIndividualLives_Hunt = INVALID_HANDLE;
new Handle:iPlayerTeamCount_Hunt = INVALID_HANDLE;
new Handle:iTeamBase_Hunt_count1 = INVALID_HANDLE;
new Handle:iTeamBase_Hunt_count2 = INVALID_HANDLE;
new Handle:iTeamBase_Hunt_count3 = INVALID_HANDLE;
new Handle:iTeamBase_Hunt_count4 = INVALID_HANDLE;
new Handle:iTeamBase_Hunt_count5 = INVALID_HANDLE;
new Handle:iTeamBase_Hunt_count6 = INVALID_HANDLE;

//Print Bot Count
new Handle:bPrintEnabled = INVALID_HANDLE;
new Handle:bPrintBotCountEnabled = INVALID_HANDLE;
new Handle:iPrintInterval = INVALID_HANDLE;

//global vars
//These will both be set and decremented from cvar iLifeBase
new g_iRespawnTeamCount;
new g_iRespawnCount[MAXPLAYERS+1];
new g_iLifeBase_Hunt; 

//for messaging for respawning
new g_isConquer,
	g_isCheckpoint,
	g_isHunt;

new g_PlayerRespawnIsEnabled = 1;
new g_playerCount = 0;
new g_IndividualLives = 1;
new g_playerDelay;
new g_printBotCount;
new g_printEnabled;

public void OnPluginStart()
{    
    PrintToServer("Dan's Player Respawn Mod running!");
    
    if(g_isHunt) return;

    //Set Admin Cmds
    RegAdminCmd("settings", Command_Respawn_Settings, ADMFLAG_SLAY);
    RegAdminCmd("print", Command_Respawn_Print, ADMFLAG_SLAY);
    RegAdminCmd("rhelp", Command_Help, ADMFLAG_SLAY);
    RegAdminCmd("respawn", Command_Respawn, ADMFLAG_SLAY, "sm_respawn <#userid|name>");

    //player cvars
    bPlayerRespawnEnabled = CreateConVar("enable_player_respawn", "1", "Enable Respawn Players");
    iLifeBase = CreateConVar("lifecount", "2", "Respawns per team or player");
    iLifeBase_1 = CreateConVar("lifecount_1", "5", "Respawns for single player");
    iRespawnDelay = CreateConVar("delay", "0", "Delay till player is respawned");
    bRespawnsResetAfterObjective = CreateConVar("reset", "1", "Reset lifecount after each objective");
    bIndividualLives = CreateConVar("mode", "1", "1 - Individual lives, 0 - Team lives");

    //player cvars for hunt
    bIndividualLives_Hunt = CreateConVar("mode_hunt", "0", "1 - Individual lives, 0 - Team lives")
    iPlayerTeamCount_Hunt = CreateConVar("team_lifecount_hunt", "0", "Respawns per team or player, if 0 then set based off of player count");
    iTeamBase_Hunt_count1 = CreateConVar("team_lifecount_hunt_1", "5", "Team respawns for hunt with 1 player");
    iTeamBase_Hunt_count2 = CreateConVar("team_lifecount_hunt_2", "6", "Team respawns for hunt with 2 player");
    iTeamBase_Hunt_count3 = CreateConVar("team_lifecount_hunt_3", "7", "Team respawns for hunt with 3 player");
    iTeamBase_Hunt_count4 = CreateConVar("team_lifecount_hunt_4", "8", "Team respawns for hunt with 4 player");
    iTeamBase_Hunt_count5 = CreateConVar("team_lifecount_hunt_5", "9", "Team respawns for hunt with 5 player");
    iTeamBase_Hunt_count6 = CreateConVar("team_lifecount_hunt_6", "10", "Team respawns for hunt with 6 player");

    //Print bot count to screen
    bPrintEnabled = CreateConVar("print_enabled", "1", "Enable lifecount/bot count printing");
    bPrintBotCountEnabled = CreateConVar("print_bot_count_enabled", "0", "Enable bot count printing");
    //unused after replacing with hintText
    iPrintInterval = CreateConVar("print_bot_interval", "5", "Print bot count every x kills.");
    
    //Event hooks
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("object_destroyed", Event_ObjectDestroyed);
    HookEvent("controlpoint_captured", Event_ControlPointCaptured);

    // player respawn
    HookConVarChange(bPlayerRespawnEnabled, CvarChangeEnabled);
    HookConVarChange(iLifeBase, CvarChangeLifeCount);
    HookConVarChange(iRespawnDelay, CvarChange);
    HookConVarChange(bRespawnsResetAfterObjective, CvarChange);
    HookConVarChange(bIndividualLives, CvarChange);
    //player hunt
    HookConVarChange(bIndividualLives_Hunt, CvarChange);
    HookConVarChange(iPlayerTeamCount_Hunt, CvarChange);

    //printing
    HookConVarChange(bPrintBotCountEnabled,CvarChangePrintEnable);
    HookConVarChange(bPrintEnabled,CvarChangePrintEnable);
    HookConVarChange(iPrintInterval,CvarChangePrintInterval);

    //Startup respawn
    // Next 14 lines of text are taken from Andersso's DoDs respawn plugin. Thanks :)
    g_hGameConfig = LoadGameConfigFile("plugin.respawn");

    if (g_hGameConfig == INVALID_HANDLE) 
    {
        SetFailState("Fatal Error: Missing File \"plugin.respawn\"!");
    }
    StartPrepSDKCall(SDKCall_Player);
    PrintToServer("[RESPAWN] ForceRespawn for Insurgency"); 
    PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "ForceRespawn");
    g_hPlayerRespawn = EndPrepSDKCall();
    if (g_hPlayerRespawn == INVALID_HANDLE)
    {
        SetFailState("Fatal Error: Unable to find signature for \"Respawn\"!");
    }
    AutoExecConfig(true, "player_respawn");

}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(g_isHunt) return Plugin_Handled;

    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_PlayerRespawnIsEnabled && IsPlayer(client)) //if player died and respawn enabled
    {
        if(g_IndividualLives) //players have individual lifecounts
        {
            if(g_iRespawnCount[client] > 0)
            {
                g_iRespawnCount[client]--;
                if(g_playerDelay>5)
                {
                    PrintToChatAll("%N died, will respawn in %d seconds",client,g_playerDelay);
                }
                
                CreateTimer(float(g_playerDelay),RespawnPlayer2,client);
            }
            else
            {
                PrintToChatAll("%N is down.", client);
            }
        }
        else if((g_iRespawnTeamCount > 0))//team lives
        {
            g_iRespawnTeamCount--;
            if(g_playerDelay>5)
            {
                PrintToChatAll("%N died, will respawn in %d seconds",client,g_playerDelay);
            }
            // SDKCall(g_hPlayerRespawn, client);    
            CreateTimer(float(g_playerDelay),RespawnPlayer2,client);
        }
        else //game over or respawn disabled
        {
        }
    }

    // if(!IsPlayer(client) && g_isCheckpoint && g_printBotCount && ((GetTeamInsCount()-1) %GetConVarInt(iPrintInterval) == 0)) //Display count after every 5 kills this happens while client is still "alive" so I decrease one
    //     PrintToChatAll("%d bots remaining", GetTeamInsCount()-1);

    return Plugin_Handled;
}

public Action:PrintStatusAllTimer(Handle:timer, any:client)
{
    PrintStatusAll();
    return Plugin_Handled;
}

//Called via timer
public PrintStatusAll()
{
    decl String:textToPrint[64];
    new bc = GetTeamInsCount(); //botcount

    if(!g_IndividualLives) //shared lifecount
    {
        if(g_printBotCount) 
            Format(textToPrint, sizeof(textToPrint),"Ins: %d | Lives: %d",bc,g_iRespawnTeamCount);
        else
            Format(textToPrint, sizeof(textToPrint),"Lives: %d",g_iRespawnTeamCount);
        
        PrintHintTextToAll(textToPrint);
    }
    else //print for each player seperately
    {
        for(int c = 1; c < GetMaxClients(); c++)
        {
            if(!IsPlayer(c))
                continue;
            if(g_printBotCount) 
                Format(textToPrint, sizeof(textToPrint),"Ins: %d | Lives: %d",bc,g_iRespawnCount[c]);
            else
                Format(textToPrint, sizeof(textToPrint),"Lives: %d",g_iRespawnCount[c]);
            
            PrintHintText(c, textToPrint);
        }
    }
}

public Action:PrintPlayerStatus(Handle:timer, any:client)
{
    decl String:textToPrint[64];
    if(!g_IndividualLives) //shared lifecount
        Format(textToPrint, sizeof(textToPrint),"Lives: %d",g_iRespawnTeamCount);
     else
        Format(textToPrint, sizeof(textToPrint),"Lives: %d",g_iRespawnCount[client]);           
    PrintHintText(client, textToPrint);
}

//Called via timer
public Action:RespawnPlayer2(Handle:timer, any:client)
{
    if(IsClientConnected(client))   //make sure they're still in-game
        SDKCall(g_hPlayerRespawn, client);    
    if(IsPlayer(client))//Respawn Player
    {
        if(g_IndividualLives)
        {
            PrintToChatAll("Respawning %N, who has %d live(s) remaining",client, g_iRespawnCount[client]);
            if(g_printEnabled && !g_printBotCount)
                CreateTimer(1.0,PrintPlayerStatus,client,TIMER_FLAG_NO_MAPCHANGE);           
        }
        else
        {
            PrintToChatAll("Respawning %N, Teamlives Remaining: %d",client, g_iRespawnTeamCount); 
            if(g_printEnabled && !g_printBotCount)
                CreateTimer(1.0,PrintPlayerStatus,client,TIMER_FLAG_NO_MAPCHANGE);           
        }
    }
    
    return Plugin_Handled;
}

// When cvar changed
public CvarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	UpdateRespawnCvars();
}

public CvarChangeEnabled(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    UpdateRespawnCvars();
}

public CvarChangeLifeCount(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    SetConVarInt(iLifeBase_1,GetConVarInt(iLifeBase));
    UpdateRespawnCvars();
    PrintToChatAll("Changed to %d respawns per objective", GetConVarInt(iLifeBase))
}
public CvarChangePrintEnable(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    if(statusTimer != INVALID_HANDLE)
        delete statusTimer;

    g_printBotCount = GetConVarInt(bPrintBotCountEnabled);
    g_printEnabled = GetConVarInt(bPrintEnabled);
    if(g_printEnabled)
        PrintToChatAll("Printing turned on");
    else
        PrintToChatAll("Printing turned off");
    if(g_printBotCount)
        PrintToChatAll("Bot Count Printing turned on");
    else
        PrintToChatAll("Bot Count Printing turned off");

    if(g_printEnabled && g_printBotCount)
        statusTimer = CreateTimer(float(g_statusDelay),PrintStatusAllTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public CvarChangePrintInterval(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    PrintToChatAll("Bot Count Print interval set to %d", GetConVarInt(iPrintInterval))
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    delete statusTimer;
    return Plugin_Handled;
}

// Update cvars if changed mid-round
void UpdateRespawnCvars()
{
    if(GetConVarInt(bPlayerRespawnEnabled))
        g_PlayerRespawnIsEnabled = 1;
    else    
        g_PlayerRespawnIsEnabled = 0;
    g_playerCount = GetTeamSecCount();

    ResetPlayers();
    if(g_isHunt) g_IndividualLives = GetConVarInt(bIndividualLives_Hunt);    
    else g_IndividualLives = GetConVarInt(bIndividualLives);
 
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check gamemode
    g_isCheckpoint = 0;
    g_isConquer = 0;
    g_isHunt = 0;
    decl String:sGameMode[32];
    GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
    if (StrEqual(sGameMode,"hunt"))
        g_isHunt = 1;
    if (StrEqual(sGameMode,"conquer")) 
        g_isConquer = 1;
    if (StrEqual(sGameMode,"checkpoint"))
        g_isCheckpoint = 1;

    //if hunt game mode then leave respawn behavior to dan_survival_hunt_mod_v2.sp
    if(g_isHunt) return Plugin_Handled;

    g_playerDelay = GetConVarInt(iRespawnDelay);
    g_printBotCount = GetConVarInt(bPrintBotCountEnabled);
    g_printEnabled = GetConVarInt(bPrintEnabled);

    if(GetConVarInt(bPlayerRespawnEnabled))
        g_PlayerRespawnIsEnabled = 1;
    else   
        g_PlayerRespawnIsEnabled = 0;
    g_playerCount = GetTeamSecCount();
    
    ResetPlayers();

    if(g_isHunt)
        g_IndividualLives = GetConVarInt(bIndividualLives_Hunt);
    else
        g_IndividualLives = GetConVarInt(bIndividualLives);

    if(g_isCheckpoint) 
    {
        if(GetConVarInt(FindConVar("ins_bot_count_checkpoint")) > 0)
            PrintToChatAll("Insurgent count set to: %d", GetConVarInt(FindConVar("ins_bot_count_checkpoint")));
        else
            PrintToChatAll("Insurgent count set to: %d",(GetConVarInt(FindConVar("ins_bot_count_checkpoint_max")) - GetConVarInt(FindConVar("ins_bot_count_checkpoint_min")))*(GetTeamSecCount()-1)/4 + GetConVarInt(FindConVar("ins_bot_count_checkpoint_min")));
    }
    //print info to clients
    if(g_PlayerRespawnIsEnabled)
    {
        if (GetConVarInt(bRespawnsResetAfterObjective))
        {
            if(g_IndividualLives)
            {
                if(g_playerCount == 1)
                    PrintToChatAll("Each player has %d respawn(s) per objective", GetConVarInt(iLifeBase_1));
                else
                    PrintToChatAll("Each player has %d respawn(s) per objective", GetConVarInt(iLifeBase));
            }
            else
            {
                PrintToChatAll("All players have shared pool of %d respawn(s) per objective", g_iRespawnTeamCount);
            }
        }
        else
        {   
            if(g_IndividualLives)
            {
                PrintToChatAll("Each player has %d total respawns", GetConVarInt(iLifeBase));
            }
            else
            {
                PrintToChatAll("All players together have %d total respawns", g_iRespawnTeamCount);
            }    
        }
    }
    
    g_statusDelay = GetConVarInt(FindConVar("statusDelay")); //grab fron dan survival hunt mod
    if(g_printEnabled && g_printBotCount) //if just printing lives then only print on player death
        statusTimer = CreateTimer(float(g_statusDelay),PrintStatusAllTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    else if (g_printEnabled && !g_printBotCount) //just print lifecount once on start
        CreateTimer(1.0,PrintStatusAllTimer,_);           

    return Plugin_Continue;  
}

public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(g_isHunt) return Plugin_Handled;
    if(g_PlayerRespawnIsEnabled)
    {
        if (GetConVarInt(bRespawnsResetAfterObjective))
        {
            if(g_isConquer) //if conquer gamemode and objective destroyed don't reset count
                return Plugin_Continue;

            ResetPlayers();
            if(g_isCheckpoint && !g_printEnabled)
                PrintToChatAll("Lifecount reset to %d", GetConVarInt(iLifeBase));
            else if(g_isCheckpoint && g_printEnabled && !g_printBotCount) //reprint lifecount
                PrintStatusAll();//CreateTimer(0.0,PrintStatusAllTimer,_); 
            if(g_isHunt)//If hunt then team isn't auto-spawned so respawn
            {
                if(g_printEnabled && !g_printBotCount) //reprint lifecount
                    PrintStatusAll();//CreateTimer(0.0,PrintStatusAllTimer,_); 
                else
                    PrintToChatAll("Team Lifecount reset to %d",g_iLifeBase_Hunt);
                for(int client = 1; client < GetMaxClients(); client++)
                {
                    if(IsPlayer(client) && !IsPlayerAlive(client))
                    {
                        CreateTimer(0.0,RespawnPlayer2,client); //instant respawn
                    }
                }
            }
        }
        else if( !g_IndividualLives && !g_printEnabled)
        {
            PrintToChatAll("%d remaining lives",g_iRespawnTeamCount);
        }
    }

    return Plugin_Continue;
}

public Action:Event_ControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
    // PrintToServer("ControlPointCapturedHook!!!!");
    if(g_PlayerRespawnIsEnabled)
    {
        if (GetConVarInt(bRespawnsResetAfterObjective))
        {
            if(g_isConquer)            //if conquer gamemode and insurgents took over objective don't reset count
            { 
                // Get client who captured control point.
                decl String:cappers[256];
                GetEventString(event, "cappers", cappers, sizeof(cappers));
                new cappersLength = strlen(cappers);
                for (new i = 0 ; i < cappersLength; i++)
                {
                    new clientCapper = cappers[i];
                    if(clientCapper > 0 && IsClientInGame(clientCapper) && IsClientConnected(clientCapper) && IsPlayerAlive(clientCapper) && !IsFakeClient(clientCapper))
                    {
                        ResetPlayers();
                        if(!g_printEnabled)
                            PrintToChatAll("Lifecount reset to %d",GetConVarInt(iLifeBase));
                        else if(g_printEnabled && !g_printBotCount) //print lifecount
                            PrintStatusAll();//CreateTimer(0.0,PrintStatusAllTimer,_); 
                    }
                }
                
            }
            else
            {
                ResetPlayers();
                if(!g_printEnabled)
                    PrintToChatAll("Lifecount reset to %d",GetConVarInt(iLifeBase));
                else if(g_printEnabled && !g_printBotCount)
                    PrintStatusAll();//CreateTimer(0.0,PrintStatusAllTimerTimer,_); 
            }
        }    
        else if(!g_IndividualLives)
        {
            if(!g_printEnabled)
                PrintToChatAll("%d remaining lives",g_iRespawnTeamCount);
        }
    }
    // ResetBots();
    return Plugin_Continue;
}

public IsPlayer(client)
{
    if(IsClientConnected(client) && !IsFakeClient(client))
    {
        return 1;
    }
    return 0;
}

public ResetPlayers()
{
    if(g_PlayerRespawnIsEnabled)
    {
        if(g_IndividualLives && !g_isHunt) //hunt defaults to teamcount
        {
            new lifecount = GetConVarInt(iLifeBase);
            if(g_playerCount == 1)
                lifecount = GetConVarInt(iLifeBase_1);
            //set each clients respawn count to iLifeBase
            for(int client = 1; client < GetMaxClients(); client++)
            {
                if(IsPlayer(client))
                    g_iRespawnCount[client] = lifecount;
            }
        }
        else //Whole team shares lifecount
        {
            if(g_isHunt)
            {
                if(GetConVarInt(iPlayerTeamCount_Hunt) == 0) //if set to zero then set lifecount based off of the number of players
                {
                    switch (g_playerCount)
                    {
                        case 1: g_iLifeBase_Hunt = GetConVarInt(iTeamBase_Hunt_count1);
                        case 2: g_iLifeBase_Hunt = GetConVarInt(iTeamBase_Hunt_count2);
                        case 3: g_iLifeBase_Hunt = GetConVarInt(iTeamBase_Hunt_count3);
                        case 4: g_iLifeBase_Hunt = GetConVarInt(iTeamBase_Hunt_count4);
                        case 5: g_iLifeBase_Hunt = GetConVarInt(iTeamBase_Hunt_count5);
                        case 6: g_iLifeBase_Hunt = GetConVarInt(iTeamBase_Hunt_count6);
                    }
                }
                else
                    g_iLifeBase_Hunt = GetConVarInt(iPlayerTeamCount_Hunt);
            
                g_iRespawnTeamCount = g_iLifeBase_Hunt;
            
            }
            else
                g_iRespawnTeamCount = GetConVarInt(iLifeBase);
        }
    }
    // PrintToChatAll("IsHunt? %d, individualLives? %d, playercount: %d, g_iLifeBase_Hunt: %d, RespawnTeamCount: %d",g_isHunt,g_IndividualLives, g_playerCount, g_iLifeBase_Hunt,g_iRespawnTeamCount);

}

// Get current player count
public GetTeamSecCount() {
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


//Get current bot count
public GetTeamInsCount()
{
	new bots = 0;
	for( new i = 1; i <= GetMaxClients(); i++ ) {
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i))
		{
            bots++;
		}
	}
	return bots;
}

// Respawn function for console command
public Action:Command_Respawn(client, args)
{
	// Check argument
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_player_respawn <#userid|name>");
		return Plugin_Handled;
	}

	// Retrive argument
	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;
	
	// Get target count
	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_DEAD,
					target_name,
					sizeof(target_name),
					tn_is_ml);
					
	// Check target count
	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	// Team filter dead players, re-order target_list array with new_target_count
	new target, team, new_target_count;

	// Check team
	for (new i = 0; i < target_count; i++)
	{
		target = target_list[i];
		team = GetClientTeam(target);

		if(team >= 2)
		{
			target_list[new_target_count] = target; // re-order
			new_target_count++;
		}
	}

	// Check target count
	if(new_target_count == COMMAND_TARGET_NONE) // No dead players from  team 2 and 3
	{
		ReplyToTargetError(client, new_target_count);
		return Plugin_Handled;
	}
	target_count = new_target_count; // re-set new value.

	// If target exists
	if (tn_is_ml)
		ShowActivity2(client, "[SM] ", "%t", "Toggled respawn on target", target_name);
	else
		ShowActivity2(client, "[SM] ", "%t", "Toggled respawn on target", "_s", target_name);
	
	// Process respawn
	for (new i = 0; i < target_count; i++)
		RespawnPlayer(client);//, target_list[i]);

	return Plugin_Handled;
}

public Action:Command_Help(int client, int args)
{
    ReplyToCommand(client, "Commands: print, settings, respawn",g_playerDelay,GetConVarInt(iLifeBase));
    ReplyToCommand(client, "Cvars: ");
    ReplyToCommand(client, "enable_player_respawn - Enable Respawn Players");
    ReplyToCommand(client, "count - Respawns per team or player");
    ReplyToCommand(client, "delay - Delay till player is respawned");
    ReplyToCommand(client, "reset - Reset lifecount after each objective");
    ReplyToCommand(client, "mode - 1 - Individual lives, 0 - team lives");
    ReplyToCommand(client, "For easy control you may also use: supply30, bot4, delay5, life10, botlife20");
    ReplyToCommand(client, "These will set mp_supply_token_base, bot_damage, respawn delay, and life count for player/bot");
    return Plugin_Handled;
}

public Action:Command_Respawn_Print(int client, int args)
{
    if(g_isHunt)
        ReplyToCommand(client, "Current Team LifeCount: %d",g_iRespawnTeamCount);
    else
        ReplyToCommand(client, "Player LifeBase: %d, Delay: %d",GetConVarInt(iLifeBase),g_playerDelay);
    ReplyToCommand(client, "Current alive bot count: %d", GetTeamInsCount());
    if(g_isCheckpoint) 
    {
        if(GetConVarInt(FindConVar("ins_bot_count_checkpoint")) > 0)
            ReplyToCommand(client, "Bot count set to: %d", GetConVarInt(FindConVar("ins_bot_count_checkpoint")));
        else
            ReplyToCommand(client,"Bot count default for player count is: %d",(GetConVarInt(FindConVar("ins_bot_count_checkpoint_max")) - GetConVarInt(FindConVar("ins_bot_count_checkpoint_min")))*(GetTeamSecCount()-1)/6 + GetConVarInt(FindConVar("ins_bot_count_checkpoint_min")));
    }
    ReplyToCommand(client, "To change these use: settings <lifecount> <respawndelay> or bot_settings <> <>");
    return Plugin_Handled;
}

public Action:Command_Respawn_Settings(int client, int args)
{ 
    char arg1[32], arg2[32];

    if(args == 0)
    {
        ReplyToCommand(client, "Usage: settings <lifecount> <respawndelay>");
        ReplyToCommand(client, "Usage: settings <enable 0/1>");
        return Plugin_Handled;
    }
    else if(args == 1)
    {
        GetCmdArg(1, arg1, sizeof(arg1));
        SetConVarInt(bPlayerRespawnEnabled, StringToInt(arg1))
        if(GetConVarInt(bPlayerRespawnEnabled) == 1) { ReplyToCommand(client, "bot_respawn enabled");}
        else 
        { 
            SetConVarInt(bPlayerRespawnEnabled, 0)
            ReplyToCommand(client, "player_respawn disabled");
        }
        return Plugin_Handled;
    }
    /* Get the first argument */
    GetCmdArg(1, arg1, sizeof(arg1));
    SetConVarInt(iLifeBase,StringToInt(arg1));
    SetConVarInt(iPlayerTeamCount_Hunt,StringToInt(arg1));

    GetCmdArg(2, arg2, sizeof(arg2));
    SetConVarInt(iRespawnDelay,StringToInt(arg2));

    SetConVarInt(bPlayerRespawnEnabled, 1);

    ReplyToCommand(client, "Player Respawn Count: %d, Delay: %d", GetConVarInt(iLifeBase), g_playerDelay);

    return Plugin_Handled;
}


//Called w/o timer
RespawnPlayer(client)
{
    if(!IsPlayer(client))
    {
        return;
    }
    if(g_IndividualLives)
    {
        PrintToChatAll("Respawning %N, who has %d lives remaining",client, g_iRespawnCount[client]);
    }
    else
    {
        PrintToChatAll("Respawning %N, Lives Remaining: %d",client, g_iRespawnTeamCount); 
    }
    //Respawn Player
    SDKCall(g_hPlayerRespawn, client);
    return;
}
