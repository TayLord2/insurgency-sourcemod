I run a coop server with max 4 players and these are more simple respawn scripts to cater to this. For a general overview of these two plugins read below:


dan_player_respawn:
This is for all coop game modes except for hunt. This used to have hunt functionality, but this was removed and moved. For hunt see dan_survival_hunt_mod_v2. 
This plugin allows for fixed number of shared team or player respawns per objective
Respawns can be set for the entire round or on a per objective basis
The bot count can be displayed or not, if not then the players remaining lives will be displayed briefly after respawn
There are no bot respawns in this script, just players. 


dan_survival_hunt_mod_v2:
This is a heavy mod for hunt game mode that comes with two options by setting hunt_mod_enabled to 1 or 2 (0 will disable). 
Mode 1 can be very difficult on large sniper friendly maps as explosive kills are very difficult. For this reason I made option 2.
Both options have a hintText that can be enabled for the screen that shows number of bots till a respawn gained and what player is currently next in queue to be respawned.

1) Hunt-Survival
  Bots will endlessly respawn until the cache is blown at which point each kill is permanement. This typically requires less bots.
  Explosive kills can be made to be permanent kills to allow bots to be whittled down.
  There is a a custom theater I uploaded (All Weapons Coop (Lower Weights)) to reduce the weight of explosives to allow for an rpg and rifle to be carried for this purpose.
  Team starts with a set number of shared respawns (hs_start)
  Team lifecount gets incremented by hs_reward every x (hs_killcount) kills. 
  Team cannot have more than hs_maxLives team lives total
  
2) Finite Bot Respawn
  This operates similar to the normal hunt mode, where the cache must be blown, but could be blown at any time. This typically requires full bot counts. 
  Bots have a set respawn count set by br_botcount
  Team starts with a set number of shared respawns (br_start)
  Team lifecount gets incremented by br_reward every x (br_killcount) kills.
  Team cannot have more than br_maxLives team lives total
