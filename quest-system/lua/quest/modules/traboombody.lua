local MODULE = {}

MODULE.Class = "TraWepBoombody"
MODULE.Name = "Hoch die Händ.. Leichen!"
MODULE.Description = [[
Gehe in den Traitorshop 
und kaufe ein
Boombody %d mal
]]
MODULE.Chance = 25 // Lower the chance, because we'll use 4 almost similar quests. 100 (default chance) / 4 (items)
MODULE.TargetValue = 20

MODULE.RewardType = TTTQuests.RewardType.Experience
MODULE.Reward = 25

if ( SERVER ) then
	// This is database parameters
	// It needs to create table in database
	// Key is name of parameter
	// Value is default value and type of parameter  
	MODULE.DBParameters = {}
	MODULE.DBParameters["SteamID"] = "\"\"" // Must have
	MODULE.DBParameters["BoomBodyBought"] = 0

	// Hooks functions are called on a specific event
	// We shall use them to calculate quest condition
	// and give a reward to a player who fulfilled the condition
	MODULE.Hooks = {}
	MODULE.Hooks["TTTOrderedEquipment"] = function(ply, equip, is_item)
	
		if ( #player.GetAll() >= TTTQuests.Config.MinPlayers ) then

		// Player must be valid
		if IsValid(ply) then

			// Check quest status
			if TTTQuests.HasPlayerQuest(ply, "TraWepBoombody") && !TTTQuests.IsQuestComplete(ply, "TraWepBoombody") then

				// A player must be detective
				if ply:IsTraitor() then
					
					// Check equipment type
					if ( equip == "weapon_boombody" ) then

						// Select a row from table
						local row = sql.MySQLQuery("SELECT BoomBodyBought FROM TTTQuests_TraWepBoombody WHERE SteamID = \"%s\"", ply:SteamID() )

						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local current = row[1].BoomBodyBought

							// Check our condition
							if ( current + 1 >= TTTQuests.Quests["TraWepBoombody"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", ply, "TraWepBoombody")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_TraWepBoombody SET BoomBodyBought=%d WHERE SteamID = \"%s\"", current + 1, ply:SteamID() )
						end
					end
				end
			end
		end
	end
end
end

// Register our quest module
TTTQuests:RegisterQuest(MODULE)