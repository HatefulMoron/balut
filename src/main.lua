-- Game constants
local NUM_DICE = 5
local MAX_HANDS = 7
local MAX_REROLLS = 2

-- Game state
local gameState = {
	dice = {}, -- Array of 5 dice values (1-6)
	locked = {}, -- Array of 5 booleans
	rerollsLeft = 0,
	currentHand = 1,
	totalScore = 0,
	goalScore = 0,
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

-- Helper function: Count occurrences of a value in dice
local function countDice(value)
	local count = 0
	for i = 1, NUM_DICE do
		if gameState.dice[i] == value then
			count = count + 1
		end
	end
	return count
end

-- Helper function: Get counts of each die value
local function getDieCounts()
	local counts = { 0, 0, 0, 0, 0, 0 }
	for i = 1, NUM_DICE do
		counts[gameState.dice[i]] = counts[gameState.dice[i]] + 1
	end
	return counts
end

-- Scoring functions
local function scoreFours()
	return countDice(4) * 4
end

local function scoreFives()
	return countDice(5) * 5
end

local function scoreSixes()
	return countDice(6) * 6
end

local function scoreStraight()
	local sorted = {}
	for i = 1, NUM_DICE do
		table.insert(sorted, gameState.dice[i])
	end
	table.sort(sorted)

	-- Check for 1-2-3-4-5
	local isSmallStraight = true
	for i = 1, NUM_DICE do
		if sorted[i] ~= i then
			isSmallStraight = false
			break
		end
	end

	-- Check for 2-3-4-5-6
	local isLargeStraight = true
	for i = 1, NUM_DICE do
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
		for i = 1, NUM_DICE do
			sum = sum + gameState.dice[i]
		end
		return sum
	end
	return 0
end

local function scoreChoice()
	local sum = 0
	for i = 1, NUM_DICE do
		sum = sum + gameState.dice[i]
	end
	return sum
end

local function scoreBalut()
	local firstValue = gameState.dice[1]
	for i = 2, NUM_DICE do
		if gameState.dice[i] ~= firstValue then
			return 0
		end
	end
	return 30
end

-- Get score for a category
local function getCategoryScore(categoryName)
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

-- Roll all unlocked dice
local function rollDice()
	for i = 1, NUM_DICE do
		if not gameState.locked[i] then
			gameState.dice[i] = love.math.random(1, 6)
		end
	end
end

-- Start a new hand
local function startNewHand()
	for i = 1, NUM_DICE do
		gameState.dice[i] = 0
		gameState.locked[i] = false
	end
	gameState.rerollsLeft = MAX_REROLLS
	gameState.phase = "rolling"
	rollDice()
end

-- Initialize game
function love.load()
	love.math.setRandomSeed(os.time())

	-- Set random goal score
	gameState.goalScore = love.math.random(100, 150)

	startNewHand()
end

-- Handle mouse clicks
function love.mousepressed(x, y, button)
	if button == 1 then -- Left click
		-- Check if clicking on dice (positioned at y=100-150)
		if gameState.phase == "rolling" then
			for i = 1, NUM_DICE do
				local diceX = 50 + (i - 1) * 80
				local diceY = 100
				local diceSize = 60

				if x >= diceX and x <= diceX + diceSize and y >= diceY and y <= diceY + diceSize then
					gameState.locked[i] = not gameState.locked[i]
				end
			end

			-- Check if clicking reroll button (positioned at y=200)
			if x >= 300 and x <= 500 and y >= 200 and y <= 240 then
				if gameState.rerollsLeft > 0 then
					rollDice()
					gameState.rerollsLeft = gameState.rerollsLeft - 1
				else
					gameState.phase = "selecting"
				end
			end
		elseif gameState.phase == "selecting" then
			-- Check if clicking on a category
			local startY = 300
			for i, category in ipairs(gameState.categories) do
				local categoryY = startY + (i - 1) * 30

				if not category.used and x >= 20 and x <= 400 and y >= categoryY and y <= categoryY + 25 then
					-- Select this category
					local score = getCategoryScore(category.name)
					gameState.totalScore = gameState.totalScore + score
					category.used = true

					-- Move to next hand or end game
					if gameState.currentHand < MAX_HANDS then
						gameState.currentHand = gameState.currentHand + 1
						startNewHand()
					else
						gameState.phase = "gameover"
					end
					break
				end
			end
		elseif gameState.phase == "gameover" then
			-- Click to restart
			if x >= 300 and x <= 500 and y >= 400 and y <= 440 then
				-- Reset game
				gameState.currentHand = 1
				gameState.totalScore = 0
				gameState.goalScore = love.math.random(100, 150)
				for i, category in ipairs(gameState.categories) do
					category.used = false
				end
				startNewHand()
			end
		end
	end
end

-- Handle keyboard input
function love.keypressed(key)
	if key == "space" and gameState.phase == "rolling" then
		if gameState.rerollsLeft > 0 then
			rollDice()
			gameState.rerollsLeft = gameState.rerollsLeft - 1
		else
			gameState.phase = "selecting"
		end
	elseif key == "escape" then
		love.event.quit()
	elseif key == "r" and gameState.phase == "gameover" then
		-- Reset game
		gameState.currentHand = 1
		gameState.totalScore = 0
		gameState.goalScore = love.math.random(100, 150)
		for i, category in ipairs(gameState.categories) do
			category.used = false
		end
		startNewHand()
	end
end

-- Draw game
function love.draw()
	love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("BALUT", 20, 20, 0, 2, 2)

	-- Score display
	love.graphics.print("Hand: " .. gameState.currentHand .. "/" .. MAX_HANDS, 20, 60)
	love.graphics.print("Score: " .. gameState.totalScore .. " / Goal: " .. gameState.goalScore, 200, 60)

	if gameState.phase == "rolling" then
		-- Draw dice
		for i = 1, NUM_DICE do
			local x = 50 + (i - 1) * 80
			local y = 100
			local size = 60

			-- Draw die background
			if gameState.locked[i] then
				love.graphics.setColor(0.3, 0.6, 0.3) -- Green for locked
			else
				love.graphics.setColor(0.5, 0.5, 0.5) -- Gray for unlocked
			end
			love.graphics.rectangle("fill", x, y, size, size)

			-- Draw die border
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", x, y, size, size)

			-- Draw die value
			love.graphics.print(tostring(gameState.dice[i]), x + 20, y + 15, 0, 2, 2)
		end

		-- Draw reroll button/info
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Rerolls left: " .. gameState.rerollsLeft, 300, 180)

		if gameState.rerollsLeft > 0 then
			love.graphics.setColor(0.2, 0.5, 0.8)
			love.graphics.rectangle("fill", 300, 200, 200, 40)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", 300, 200, 200, 40)
			love.graphics.print("REROLL (Space)", 320, 212)
		else
			love.graphics.setColor(0.8, 0.5, 0.2)
			love.graphics.rectangle("fill", 300, 200, 200, 40)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", 300, 200, 200, 40)
			love.graphics.print("SELECT CATEGORY", 310, 212)
		end

		-- Instructions
		love.graphics.print("Click dice to lock/unlock", 50, 250)
	elseif gameState.phase == "selecting" then
		-- Show current dice (locked)
		for i = 1, NUM_DICE do
			local x = 50 + (i - 1) * 80
			local y = 100
			local size = 60

			love.graphics.setColor(0.3, 0.3, 0.3)
			love.graphics.rectangle("fill", x, y, size, size)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", x, y, size, size)
			love.graphics.print(tostring(gameState.dice[i]), x + 20, y + 15, 0, 2, 2)
		end

		-- Show categories
		love.graphics.print("Select a category:", 20, 270)
		local startY = 300
		for i, category in ipairs(gameState.categories) do
			local y = startY + (i - 1) * 30

			if category.used then
				love.graphics.setColor(0.5, 0.5, 0.5)
				love.graphics.print(category.name .. " (used)", 20, y)
			else
				love.graphics.setColor(1, 1, 1)
				local score = getCategoryScore(category.name)
				love.graphics.print(category.name .. ": " .. score .. " points", 20, y)
			end
		end
	elseif gameState.phase == "gameover" then
		-- Game over screen
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("GAME OVER", 300, 200, 0, 2, 2)

		local won = gameState.totalScore >= gameState.goalScore
		if won then
			love.graphics.setColor(0.3, 1, 0.3)
			love.graphics.print("YOU WIN!", 320, 250, 0, 2, 2)
		else
			love.graphics.setColor(1, 0.3, 0.3)
			love.graphics.print("YOU LOSE!", 320, 250, 0, 2, 2)
		end

		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Final Score: " .. gameState.totalScore, 300, 300)
		love.graphics.print("Goal Score: " .. gameState.goalScore, 300, 330)

		-- Restart button
		love.graphics.setColor(0.2, 0.5, 0.8)
		love.graphics.rectangle("fill", 300, 400, 200, 40)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", 300, 400, 200, 40)
		love.graphics.print("RESTART (R)", 330, 412)
	end
end
