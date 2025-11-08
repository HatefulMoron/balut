-- game.lua
-- Contains core game logic.

local game = {}
local upgrades = require("upgrades")

-- Private game state (will be initialized by game.new)
local state = nil

-- Persistent player state (survives across game rounds)
local playerState = {
	coins = 10,
	ownedMods = {},
	ownedTricks = {},
}

-- Shop state
local shopState = {
	availableUpgrades = {},
}

-- Count occurrences of a value in dice.
local function countDice(value)
	local count = 0
	for i = 1, #state.dice do
		if state.dice[i] == value then
			count = count + 1
		end
	end
	return count
end

-- Get counts of each die value.
local function getDieCounts()
	local counts = { 0, 0, 0, 0, 0, 0 }
	for i = 1, #state.dice do
		counts[state.dice[i]] = counts[state.dice[i]] + 1
	end
	return counts
end

-- Score the fours (respects mod multipliers).
local function scoreFours()
	local multiplier = state.gameParams.foursMultiplier or 4
	return countDice(4) * multiplier
end

-- Score the fives (respects mod multipliers).
local function scoreFives()
	local multiplier = state.gameParams.fivesMultiplier or 5
	return countDice(5) * multiplier
end

-- Score the sixes (respects mod multipliers).
local function scoreSixes()
	local multiplier = state.gameParams.sixesMultiplier or 6
	return countDice(6) * multiplier
end

-- Score the straight.
local function scoreStraight()
	local sorted = {}
	for i = 1, #state.dice do
		table.insert(sorted, state.dice[i])
	end
	table.sort(sorted)

	-- Check for 1-2-3-4-5
	local isSmallStraight = true
	for i = 1, #state.dice do
		if sorted[i] ~= i then
			isSmallStraight = false
			break
		end
	end

	-- Check for 2-3-4-5-6
	local isLargeStraight = true
	for i = 1, #state.dice do
		if sorted[i] ~= i + 1 then
			isLargeStraight = false
			break
		end
	end

	if isSmallStraight or isLargeStraight then
		return 50
	end
	return 0
end

-- Score the full house.
local function scoreFullHouse()
	local counts = getDieCounts()
	local hasThree = false
	local hasTwo = false

	for i = 1, 6 do
		if counts[i] == 3 then
			hasThree = true
		elseif counts[i] == 2 then
			hasTwo = true
		end
	end

	if hasThree and hasTwo then
		local sum = 0
		for i = 1, #state.dice do
			sum = sum + state.dice[i]
		end
		return sum
	end
	return 0
end

-- Score the choice.
local function scoreChoice()
	local sum = 0
	for i = 1, #state.dice do
		sum = sum + state.dice[i]
	end
	return sum
end

-- Score the balut.
local function scoreBalut()
	local firstValue = state.dice[1]
	for i = 2, #state.dice do
		if state.dice[i] ~= firstValue then
			return 0
		end
	end
	return 30
end

-- Get score for a category.
function game.getCategoryScore(categoryName)
	if categoryName == "Fours" then
		return scoreFours()
	elseif categoryName == "Fives" then
		return scoreFives()
	elseif categoryName == "Sixes" then
		return scoreSixes()
	elseif categoryName == "Straight" then
		return scoreStraight()
	elseif categoryName == "Full House" then
		return scoreFullHouse()
	elseif categoryName == "Choice" then
		return scoreChoice()
	elseif categoryName == "Balut" then
		return scoreBalut()
	end
	return 0
end

-- Roll all unlocked dice.
function game.rollDice()
	for i = 1, #state.dice do
		if not state.locked[i] then
			state.dice[i] = love.math.random(1, 6)
		end
	end
end

-- Toggle lock state of a die.
function game.toggleLock(diceIndex)
	if diceIndex >= 1 and diceIndex <= #state.dice then
		state.locked[diceIndex] = not state.locked[diceIndex]
	end
end

-- Start a new hand.
function game.startNewHand()
	local numDice = state.numDice

	-- Apply active trick effects
	for i, trick in ipairs(state.activeTricks) do
		if trick.id == "double_dip" then
			numDice = numDice * 2
		end
	end

	for i = 1, numDice do
		state.dice[i] = 0
		state.locked[i] = false
	end
	state.rerollsLeft = state.maxRerolls
	state.phase = "rolling"
	state.activeTricks = {} -- Clear active tricks after applying
	game.rollDice()
end

-- Select a category and score the current hand.
function game.selectCategory(categoryName)
	-- Find the category
	for i, category in ipairs(state.categories) do
		if category.name == categoryName and not category.used then
			-- Score it
			local score = game.getCategoryScore(category.name)
			state.totalScore = state.totalScore + score
			category.used = true

			-- Move to next hand or end game
			if state.currentHand < state.maxHands then
				state.currentHand = state.currentHand + 1
				game.startNewHand()
			else
				state.phase = "gameover"
			end
			return true
		end
	end
	return false
end

-- Use a reroll.
function game.reroll()
	if state.rerollsLeft > 0 then
		game.rollDice()
		state.rerollsLeft = state.rerollsLeft - 1
		return true
	end
	return false
end

-- Move to category selection phase.
function game.moveToSelecting()
	state.phase = "selecting"
end

-- Get current game state (for rendering).
function game.getState()
	return state
end

-- Get player state (coins, mods, tricks).
function game.getPlayerState()
	return playerState
end

-- Get shop state.
function game.getShopState()
	return shopState
end

-- Check if game is won.
function game.isWon()
	return state.totalScore >= state.goalScore
end

-- Apply mod effects to game parameters.
local function applyModEffects(baseParams)
	local params = {
		numDice = baseParams.numDice,
		maxHands = baseParams.maxHands,
		maxRerolls = baseParams.maxRerolls,
		foursMultiplier = 4,
		fivesMultiplier = 5,
		sixesMultiplier = 6,
	}

	for _, mod in ipairs(playerState.ownedMods) do
		if mod.effect then
			mod.effect(params)
		end
	end

	return params
end

-- Start shop phase.
function game.startShop()
	-- Generate 3-5 random upgrades
	local count = love.math.random(3, 5)
	shopState.availableUpgrades = upgrades.getShopSelection(playerState.ownedMods, count)

	if state then
		state.phase = "shop"
	else
		-- Initialize minimal state for shop
		state = { phase = "shop" }
	end
end

-- Purchase an upgrade from shop.
function game.purchaseUpgrade(upgradeItem)
	local upgrade = upgradeItem.upgrade
	local upgradeType = upgradeItem.type

	-- Check if player can afford it
	if playerState.coins < upgrade.cost then
		return false, "Not enough coins"
	end

	-- Check slot limits
	if upgradeType == "mod" then
		if #playerState.ownedMods >= 5 then
			return false, "Mod slots full (max 5)"
		end
	elseif upgradeType == "trick" then
		if #playerState.ownedTricks >= 3 then
			return false, "Trick slots full (max 3)"
		end
	end

	-- Deduct coins
	playerState.coins = playerState.coins - upgrade.cost

	-- Add to inventory
	if upgradeType == "mod" then
		table.insert(playerState.ownedMods, upgrade)
	elseif upgradeType == "trick" then
		table.insert(playerState.ownedTricks, upgrade)
	end

	return true, "Purchase successful"
end

-- Use a trick during gameplay.
function game.useTrick(trickIndex)
	if trickIndex < 1 or trickIndex > #playerState.ownedTricks then
		return false
	end

	local trick = playerState.ownedTricks[trickIndex]

	-- Mark trick as active for this hand
	if not state.activeTricks then
		state.activeTricks = {}
	end
	table.insert(state.activeTricks, trick)

	-- Remove trick from inventory (consumed)
	table.remove(playerState.ownedTricks, trickIndex)

	return true
end

-- Start a new game round (after shop).
function game.startGameRound(baseNumDice, baseMaxHands, baseMaxRerolls, goalScore)
	-- Apply mod effects to base parameters
	local gameParams = applyModEffects({
		numDice = baseNumDice,
		maxHands = baseMaxHands,
		maxRerolls = baseMaxRerolls,
	})

	state = {
		numDice = gameParams.numDice,
		maxHands = gameParams.maxHands,
		maxRerolls = gameParams.maxRerolls,
		gameParams = gameParams, -- Store for scoring
		dice = {},
		locked = {},
		rerollsLeft = 0,
		currentHand = 1,
		totalScore = 0,
		goalScore = goalScore,
		phase = "rolling",
		activeTricks = {},
		categories = {
			{ name = "Fours", used = false },
			{ name = "Fives", used = false },
			{ name = "Sixes", used = false },
			{ name = "Straight", used = false },
			{ name = "Full House", used = false },
			{ name = "Choice", used = false },
			{ name = "Balut", used = false },
		},
	}

	game.startNewHand()
	return state
end

-- Award coins on victory.
function game.awardVictory()
	local coinsEarned = 10 -- Base reward
	playerState.coins = playerState.coins + coinsEarned
	return coinsEarned
end

-- Reset everything (new game from scratch).
function game.resetAll()
	playerState.coins = 10
	playerState.ownedMods = {}
	playerState.ownedTricks = {}
	game.startShop()
end

-- Initialize game (called once at startup).
function game.init()
	game.startShop()
end

return game
