Spawn Restrict restricts players from firing certain weapons and using certain buildings in spawn.

This plugin is useful for:
 - Keeping snipers out of spawn
 - Preventing demomen from shooting grenades over spawn walls in certain maps
 - Preventing soldiers from spamming rockets out of spawn
 - Removing sentry nests in spawn
 - In general, getting people out of the spawn to play the map

Tips:
 - Use tf/cfg/mapname.cfg for map specific configs
 - Disable weapons only if a map needs it (ex: for surf_air_arena, you would only need to disable sniper rifles or rocket launchers but not grenade/sticky launchers)
 - Use sr_extend to extend the area where player's weapons are checked if the map has a lot of extra space for buildings (ex: surf_bathroom)
 - You can restrict any weapon in spawn (ex: sr_weapon tf_weapon_laser_pointer to restrict the engineer's wrangler). See http://wiki.teamfortress.com/wiki/User:Kemerover/Memo for a full list of weapons

Default Cvars:
sr_enable = 1
 - Enable/Disable Spawn Restrict - 1 = Enable, 0 = Disable

sr_extend = 256
 - Extend The Spawn Triggers By The Specified Amount

Admin/Server Commands:
sr_weapon <weapon> (rocketlauncher, grenadelauncher, stickylauncher, sniperrifle)
 - Adds the specified weapon to the restricted weapon list
 - See http://wiki.teamfortress.com/wiki/User:Kemerover/Memo for a full list of weapons
 - Aliases:
  - rocket/rocketlauncher - tf_weapon_rocketlauncher
  - grenade/grenadelauncher - tf_weapon_grenadelauncher
  - sticky/stickylauncher - tf_weapon_pipebomblauncher
  - sniper/sniperrifle - tf_weapon_sniperrifle

sr_weapon_clear
 - Clears the restricted weapon list

sr_building <building> (sentry, dispenser, teleporter)
 - Adds the specified building to the restricted building list.
 - Aliases:
  - sentry - obj_sentrygun
  - dispenser - obj_dispenser
  - tele/teleporter - obj_teleporter

sr_building_clear
 - Clears the restricted building list

sr_clear
 - Clears both the restricted weapon list and the restricted building list

If you have any questions, bug reports, or suggestions, contact me on steam: Panzerhandschuh