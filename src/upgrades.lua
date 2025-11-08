-- Upgrades module: Defines all mods and tricks available in the shop

local upgrades = {}

-- Mod definitions (persistent upgrades)
upgrades.mods = {
	{
		id = "extra_reroll",
		name = "Extra Reroll",
		description = "Gain +1 reroll per hand",
		cost = 8,
		effect = function(gameParams)
			gameParams.maxRerolls = gameParams.maxRerolls + 1
		end,
	},
	{
		id = "bonus_hand",
		name = "Bonus Hand",
		description = "Play one additional hand",
		cost = 10,
		effect = function(gameParams)
			gameParams.maxHands = gameParams.maxHands + 1
		end,
	},
	{
		id = "lucky_sixes",
		name = "Lucky Sixes",
		description = "Sixes score x7 instead of x6",
		cost = 7,
		effect = function(gameParams)
			gameParams.sixesMultiplier = 7
		end,
	},
	{
		id = "hot_streak",
		name = "Hot Streak",
		description = "Roll one extra die",
		cost = 12,
		effect = function(gameParams)
			gameParams.numDice = gameParams.numDice + 1
		end,
	},
	{
		id = "double_down",
		name = "Double Down",
		description = "Fours score x8 instead of x4",
		cost = 7,
		effect = function(gameParams)
			gameParams.foursMultiplier = 8
		end,
	},
	{
		id = "ace_in_hole",
		name = "Ace in the Hole",
		description = "Gain +2 rerolls per hand",
		cost = 15,
		effect = function(gameParams)
			gameParams.maxRerolls = gameParams.maxRerolls + 2
		end,
	},
	{
		id = "high_roller",
		name = "High Roller",
		description = "Fives score x7 instead of x5",
		cost = 8,
		effect = function(gameParams)
			gameParams.fivesMultiplier = 7
		end,
	},
}

-- Trick definitions (consumable, one-time use)
upgrades.tricks = {
	{
		id = "double_dip",
		name = "Double Dip",
		description = "Double the dice for one hand",
		cost = 5,
		-- Trick effects are applied when used, not at game start
	},
}

-- Get all available mods that player doesn't own
function upgrades.getAvailableMods(ownedMods)
	local available = {}
	for _, mod in ipairs(upgrades.mods) do
		local owned = false
		for _, ownedMod in ipairs(ownedMods) do
			if ownedMod.id == mod.id then
				owned = true
				break
			end
		end
		if not owned then
			table.insert(available, mod)
		end
	end
	return available
end

-- Get all tricks (can be purchased multiple times)
function upgrades.getAvailableTricks()
	return upgrades.tricks
end

-- Get random selection of upgrades for shop
function upgrades.getShopSelection(ownedMods, count)
	local selection = {}
	local availableMods = upgrades.getAvailableMods(ownedMods)
	local availableTricks = upgrades.getAvailableTricks()

	-- Combine available mods and tricks
	local allAvailable = {}
	for _, mod in ipairs(availableMods) do
		table.insert(allAvailable, { type = "mod", upgrade = mod })
	end
	for _, trick in ipairs(availableTricks) do
		table.insert(allAvailable, { type = "trick", upgrade = trick })
	end

	-- Shuffle and select random items
	for i = #allAvailable, 2, -1 do
		local j = love.math.random(i)
		allAvailable[i], allAvailable[j] = allAvailable[j], allAvailable[i]
	end

	-- Take first 'count' items
	for i = 1, math.min(count, #allAvailable) do
		table.insert(selection, allAvailable[i])
	end

	return selection
end

-- Find upgrade by id
function upgrades.findById(id)
	for _, mod in ipairs(upgrades.mods) do
		if mod.id == id then
			return { type = "mod", upgrade = mod }
		end
	end
	for _, trick in ipairs(upgrades.tricks) do
		if trick.id == id then
			return { type = "trick", upgrade = trick }
		end
	end
	return nil
end

return upgrades
