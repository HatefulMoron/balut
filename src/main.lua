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

-- Handle mouse clicks.
function love.mousepressed(x, y, button)
	if button ~= 1 then
		return
	end -- Only handle left click

	local state = game.getState()

	if state.phase == "rolling" then
		-- Check if clicking on dice
		for i = 1, NUM_DICE do
			local diceX = 50 + (i - 1) * 80
			local diceY = 100
			local diceSize = 60

			if x >= diceX and x <= diceX + diceSize and y >= diceY and y <= diceY + diceSize then
				game.toggleLock(i)
				return
			end
		end

		-- Check if clicking reroll button
		if x >= 300 and x <= 500 and y >= 200 and y <= 240 then
			if state.rerollsLeft > 0 then
				game.reroll()
			else
				game.moveToSelecting()
			end
		end
	elseif state.phase == "selecting" then
		-- Check if clicking on a category
		local startY = 300
		for i, category in ipairs(state.categories) do
			local categoryY = startY + (i - 1) * 30

			if not category.used and x >= 20 and x <= 400 and y >= categoryY and y <= categoryY + 25 then
				game.selectCategory(category.name)
				return
			end
		end
	elseif state.phase == "gameover" then
		-- Click to restart
		if x >= 300 and x <= 500 and y >= 400 and y <= 440 then
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
		else
			game.moveToSelecting()
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

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("BALUT", 20, 20, 0, 2, 2)

	-- Score display
	love.graphics.print("Hand: " .. state.currentHand .. "/" .. MAX_HANDS, 20, 60)
	love.graphics.print("Score: " .. state.totalScore .. " / Goal: " .. state.goalScore, 200, 60)

	if state.phase == "rolling" then
		-- Draw dice
		for i = 1, NUM_DICE do
			local x = 50 + (i - 1) * 80
			local y = 100
			local size = 60

			-- Draw die background
			if state.locked[i] then
				love.graphics.setColor(0.3, 0.6, 0.3) -- Green for locked
			else
				love.graphics.setColor(0.5, 0.5, 0.5) -- Gray for unlocked
			end
			love.graphics.rectangle("fill", x, y, size, size)

			-- Draw die border
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", x, y, size, size)

			-- Draw die value
			love.graphics.print(tostring(state.dice[i]), x + 20, y + 15, 0, 2, 2)
		end

		-- Draw reroll button/info
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Rerolls left: " .. state.rerollsLeft, 300, 180)

		if state.rerollsLeft > 0 then
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
	elseif state.phase == "selecting" then
		-- Show current dice (locked)
		for i = 1, NUM_DICE do
			local x = 50 + (i - 1) * 80
			local y = 100
			local size = 60

			love.graphics.setColor(0.3, 0.3, 0.3)
			love.graphics.rectangle("fill", x, y, size, size)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", x, y, size, size)
			love.graphics.print(tostring(state.dice[i]), x + 20, y + 15, 0, 2, 2)
		end

		-- Show categories
		love.graphics.print("Select a category:", 20, 270)
		local startY = 300
		for i, category in ipairs(state.categories) do
			local y = startY + (i - 1) * 30

			if category.used then
				love.graphics.setColor(0.5, 0.5, 0.5)
				love.graphics.print(category.name .. " (used)", 20, y)
			else
				love.graphics.setColor(1, 1, 1)
				local score = game.getCategoryScore(category.name)
				love.graphics.print(category.name .. ": " .. score .. " points", 20, y)
			end
		end
	elseif state.phase == "gameover" then
		-- Game over screen
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("GAME OVER", 300, 200, 0, 2, 2)

		if game.isWon() then
			love.graphics.setColor(0.3, 1, 0.3)
			love.graphics.print("YOU WIN!", 320, 250, 0, 2, 2)
		else
			love.graphics.setColor(1, 0.3, 0.3)
			love.graphics.print("YOU LOSE!", 320, 250, 0, 2, 2)
		end

		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Final Score: " .. state.totalScore, 300, 300)
		love.graphics.print("Goal Score: " .. state.goalScore, 300, 330)

		-- Restart button
		love.graphics.setColor(0.2, 0.5, 0.8)
		love.graphics.rectangle("fill", 300, 400, 200, 40)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", 300, 400, 200, 40)
		love.graphics.print("RESTART (R)", 330, 412)
	end
end
