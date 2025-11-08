-- Game module: Contains core Balut game logic

local game = {}

-- Private game state (will be initialized by game.new)
local state = nil

-- Count occurrences of a value in dice.
-- For example, countDice(5) will return the number of 5's in the dice.
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
-- For example, getDieCounts() will return a table with the counts of each die value.
local function getDieCounts()
	local counts = { 0, 0, 0, 0, 0, 0 }
	for i = 1, #state.dice do
		counts[state.dice[i]] = counts[state.dice[i]] + 1
	end
	return counts
end

-- Score the fours.
local function scoreFours()
	return countDice(4) * 4
end

-- Score the fives.
local function scoreFives()
	return countDice(5) * 5
end

-- Score the sixes.
local function scoreSixes()
	return countDice(6) * 6
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
	for i = 1, state.numDice do
		state.dice[i] = 0
		state.locked[i] = false
	end
	state.rerollsLeft = state.maxRerolls
	state.phase = "rolling"
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

-- Check if game is won.
function game.isWon()
	return state.totalScore >= state.goalScore
end

-- Initialize a new game with parameters.
function game.new(numDice, maxHands, maxRerolls, goalScore)
	state = {
		numDice = numDice,
		maxHands = maxHands,
		maxRerolls = maxRerolls,
		dice = {},
		locked = {},
		rerollsLeft = 0,
		currentHand = 1,
		totalScore = 0,
		goalScore = goalScore,
		phase = "rolling", -- "rolling", "selecting", "gameover"
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

return game
