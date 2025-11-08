-- Import modules
local constants = require("constants")
local game = require("game")

-- Game constants
local NUM_DICE = constants.BASE_NUM_DICE
local MAX_HANDS = constants.BASE_MAX_HANDS
local MAX_REROLLS = constants.BASE_MAX_REROLLS

-- Initialize game state.
function love.load()
	love.math.setRandomSeed(os.time())

	-- Set random goal score and create new game
	local goalScore = love.math.random(100, 150)
	game.new(NUM_DICE, MAX_HANDS, MAX_REROLLS, goalScore)
end

-- Helper function to draw the category score table
local function drawCategoryTable(state)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Categories:", 20, 250, 0, 1.5, 1.5)

	local startY = 290
	for i, category in ipairs(state.categories) do
		local y = startY + (i - 1) * 35

		if category.used then
			love.graphics.setColor(0.4, 0.4, 0.4)
			love.graphics.print(category.name .. ": USED", 20, y)
		else
			love.graphics.setColor(1, 1, 1)
			local score = game.getCategoryScore(category.name)
			if state.phase == "selecting" then
				love.graphics.setColor(1, 1, 0.5) -- Highlight during selection
			end
			love.graphics.print(category.name .. ": " .. score, 20, y)
		end
	end
end

-- Handle mouse clicks.
function love.mousepressed(x, y, button)
	if button ~= 1 then
		return
	end -- Only handle left click

	local state = game.getState()

	if state.phase == "rolling" or state.phase == "selecting" then
		-- Check if clicking on dice (only during rolling phase)
		if state.phase == "rolling" then
			for i = 1, NUM_DICE do
				local diceX = 250 + (i - 1) * 110
				local diceY = 80
				local diceSize = 100

				if x >= diceX and x <= diceX + diceSize and y >= diceY and y <= diceY + diceSize then
					game.toggleLock(i)
					return
				end
			end

			-- Check if clicking reroll button (right side, only during rolling)
			if x >= 550 and x <= 750 and y >= 250 and y <= 300 then
				if state.rerollsLeft > 0 then
					game.reroll()
				end
				return
			end
		end

		-- Check if clicking on a category in the table (available in both rolling and selecting phases)
		local startY = 290
		for i, category in ipairs(state.categories) do
			local categoryY = startY + (i - 1) * 35

			if not category.used and x >= 20 and x <= 250 and y >= categoryY and y <= categoryY + 30 then
				game.selectCategory(category.name)
				return
			end
		end
	elseif state.phase == "gameover" then
		-- Click to restart
		if x >= 300 and x <= 500 and y >= 400 and y <= 450 then
			local goalScore = love.math.random(100, 150)
			game.new(NUM_DICE, MAX_HANDS, MAX_REROLLS, goalScore)
		end
	end
end

-- Handle keyboard input.
function love.keypressed(key)
	local state = game.getState()

	-- If the key is space and the phase is rolling, use a reroll
	if key == "space" and state.phase == "rolling" then
		if state.rerollsLeft > 0 then
			game.reroll()
		end
	-- If the key is escape, quit the game
	elseif key == "escape" then
		love.event.quit()
	-- If the key is r and the phase is gameover, restart the game
	elseif key == "r" and state.phase == "gameover" then
		local goalScore = love.math.random(100, 150)
		game.new(NUM_DICE, MAX_HANDS, MAX_REROLLS, goalScore)
	end
end

-- Draw game.
function love.draw()
	love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

	local state = game.getState()

	-- Title and score display (top)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("BALUT", 20, 20, 0, 2, 2)
	love.graphics.print("Hand: " .. state.currentHand .. "/" .. MAX_HANDS, 550, 20, 0, 1.3, 1.3)
	love.graphics.print("Score: " .. state.totalScore .. " / Goal: " .. state.goalScore, 550, 45, 0, 1.3, 1.3)

	if state.phase == "rolling" or state.phase == "selecting" then
		-- Draw larger dice at the top center
		for i = 1, NUM_DICE do
			local x = 250 + (i - 1) * 110
			local y = 80
			local size = 100

			-- Draw die background
			if state.locked[i] then
				love.graphics.setColor(0.3, 0.6, 0.3) -- Green for locked
			else
				love.graphics.setColor(0.5, 0.5, 0.5) -- Gray for unlocked
			end
			love.graphics.rectangle("fill", x, y, size, size, 5, 5)

			-- Draw die border
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", x, y, size, size, 5, 5)

			-- Draw die value (larger text)
			love.graphics.print(tostring(state.dice[i]), x + 35, y + 25, 0, 3, 3)
		end

		-- Draw persistent category table on the left
		drawCategoryTable(state)

		-- Draw controls on the right side
		if state.phase == "rolling" then
			love.graphics.setColor(1, 1, 1)
			love.graphics.print("Rerolls left: " .. state.rerollsLeft, 550, 220, 0, 1.2, 1.2)

			-- Reroll button
			if state.rerollsLeft > 0 then
				love.graphics.setColor(0.2, 0.5, 0.8)
			else
				love.graphics.setColor(0.3, 0.3, 0.3)
			end
			love.graphics.rectangle("fill", 550, 250, 200, 50, 5, 5)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", 550, 250, 200, 50, 5, 5)
			love.graphics.print("REROLL (Space)", 570, 267, 0, 1.2, 1.2)

			-- Instructions
			love.graphics.setColor(0.7, 0.7, 0.7)
			love.graphics.print("Click dice to lock/unlock", 250, 200, 0, 1.1, 1.1)
			love.graphics.setColor(1, 1, 0.5)
			love.graphics.print("Click a category", 550, 330, 0, 1.2, 1.2)
			love.graphics.print("to score anytime", 550, 355, 0, 1.2, 1.2)
		elseif state.phase == "selecting" then
			-- Instructions for selecting phase
			love.graphics.setColor(1, 1, 0.5)
			love.graphics.print("Click a category", 550, 250, 0, 1.3, 1.3)
			love.graphics.print("to score this hand", 550, 275, 0, 1.3, 1.3)
		end
	elseif state.phase == "gameover" then
		-- Game over screen
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("GAME OVER", 280, 200, 0, 2.5, 2.5)

		if game.isWon() then
			love.graphics.setColor(0.3, 1, 0.3)
			love.graphics.print("YOU WIN!", 320, 270, 0, 2, 2)
		else
			love.graphics.setColor(1, 0.3, 0.3)
			love.graphics.print("YOU LOSE!", 310, 270, 0, 2, 2)
		end

		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Final Score: " .. state.totalScore, 300, 330, 0, 1.5, 1.5)
		love.graphics.print("Goal Score: " .. state.goalScore, 300, 360, 0, 1.5, 1.5)

		-- Restart button
		love.graphics.setColor(0.2, 0.5, 0.8)
		love.graphics.rectangle("fill", 300, 400, 200, 50, 5, 5)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", 300, 400, 200, 50, 5, 5)
		love.graphics.print("RESTART (R)", 330, 415, 0, 1.3, 1.3)
	end
end
