-- main.lua
-- The main entry point for the game.

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
	game.init()
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

-- Helper function to draw mods and tricks sidebar
local function drawModsTricksSidebar()
	local playerState = game.getPlayerState()

	-- Draw mods section
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Mods (" .. #playerState.ownedMods .. "/5):", 550, 400, 0, 1.2, 1.2)

	local modY = 430
	for i, mod in ipairs(playerState.ownedMods) do
		love.graphics.setColor(0.5, 0.8, 0.5)
		love.graphics.print("• " .. mod.name, 550, modY, 0, 0.9, 0.9)
		modY = modY + 20
	end

	-- Draw tricks section
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Tricks (" .. #playerState.ownedTricks .. "/3):", 550, modY + 10, 0, 1.2, 1.2)

	local trickY = modY + 40
	for i, trick in ipairs(playerState.ownedTricks) do
		-- Draw trick as button
		love.graphics.setColor(0.6, 0.4, 0.8)
		love.graphics.rectangle("fill", 550, trickY, 180, 30, 3, 3)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", 550, trickY, 180, 30, 3, 3)
		love.graphics.print(trick.name .. " [USE]", 560, trickY + 7, 0, 0.9, 0.9)

		trickY = trickY + 35
	end
end

-- Helper function to draw shop UI
local function drawShop()
	local playerState = game.getPlayerState()
	local shopState = game.getShopState()

	-- Background
	love.graphics.setBackgroundColor(0.15, 0.1, 0.2)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("SHOP", 350, 20, 0, 2.5, 2.5)

	-- Coins display
	love.graphics.setColor(1, 0.8, 0)
	love.graphics.print("Coins: " .. playerState.coins, 20, 20, 0, 1.5, 1.5)

	-- Inventory status
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.print(
		"Mods: " .. #playerState.ownedMods .. "/5  |  Tricks: " .. #playerState.ownedTricks .. "/3",
		20,
		50,
		0,
		1.2,
		1.2
	)

	-- Available upgrades
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Available Upgrades:", 20, 100, 0, 1.3, 1.3)

	local upgradeY = 140
	for i, item in ipairs(shopState.availableUpgrades) do
		local upgrade = item.upgrade
		local upgradeType = item.type

		-- Draw upgrade card
		love.graphics.setColor(0.2, 0.2, 0.3)
		love.graphics.rectangle("fill", 20, upgradeY, 700, 80, 5, 5)

		-- Type indicator
		if upgradeType == "mod" then
			love.graphics.setColor(0.5, 0.8, 0.5)
		else
			love.graphics.setColor(0.6, 0.4, 0.8)
		end
		love.graphics.print(string.upper(upgradeType), 30, upgradeY + 10, 0, 1.1, 1.1)

		-- Name and description
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(upgrade.name, 30, upgradeY + 35, 0, 1.3, 1.3)
		love.graphics.setColor(0.8, 0.8, 0.8)
		love.graphics.print(upgrade.description, 30, upgradeY + 58, 0, 0.9, 0.9)

		-- Cost and buy button
		love.graphics.setColor(1, 0.8, 0)
		love.graphics.print(upgrade.cost .. " coins", 550, upgradeY + 15, 0, 1.2, 1.2)

		-- Buy button
		local canAfford = playerState.coins >= upgrade.cost
		local slotsAvailable = (upgradeType == "mod" and #playerState.ownedMods < 5)
			or (upgradeType == "trick" and #playerState.ownedTricks < 3)

		if canAfford and slotsAvailable then
			love.graphics.setColor(0.3, 0.7, 0.3)
		else
			love.graphics.setColor(0.4, 0.4, 0.4)
		end
		love.graphics.rectangle("fill", 550, upgradeY + 45, 100, 30, 3, 3)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", 550, upgradeY + 45, 100, 30, 3, 3)
		love.graphics.print("BUY", 580, upgradeY + 52, 0, 1.1, 1.1)

		upgradeY = upgradeY + 95
	end

	-- Start Game button
	love.graphics.setColor(0.2, 0.5, 0.8)
	love.graphics.rectangle("fill", 300, 550, 200, 40, 5, 5)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("line", 300, 550, 200, 40, 5, 5)
	love.graphics.print("START GAME", 330, 560, 0, 1.3, 1.3)
end

-- Handle mouse clicks.
function love.mousepressed(x, y, button)
	if button ~= 1 then
		return
	end -- Only handle left click

	local state = game.getState()
	if not state then
		return
	end

	if state.phase == "shop" then
		local shopState = game.getShopState()

		-- Check if clicking on upgrade buy buttons
		local upgradeY = 140
		for i, item in ipairs(shopState.availableUpgrades) do
			if x >= 550 and x <= 650 and y >= upgradeY + 45 and y <= upgradeY + 75 then
				game.purchaseUpgrade(item)
				-- Refresh shop after purchase
				game.startShop()
				return
			end
			upgradeY = upgradeY + 95
		end

		-- Check if clicking Start Game button
		if x >= 300 and x <= 500 and y >= 550 and y <= 590 then
			local goalScore = love.math.random(100, 150)
			game.startGameRound(NUM_DICE, MAX_HANDS, MAX_REROLLS, goalScore)
		end
	elseif state.phase == "rolling" or state.phase == "selecting" then
		-- Check if clicking on trick buttons
		local playerState = game.getPlayerState()
		local trickY = 530 + (#playerState.ownedMods * 20)
		for i, trick in ipairs(playerState.ownedTricks) do
			if x >= 550 and x <= 730 and y >= trickY and y <= trickY + 30 then
				if state.phase == "rolling" then
					game.useTrick(i)
					game.startNewHand() -- Restart hand with trick applied
				end
				return
			end
			trickY = trickY + 35
		end

		-- Check if clicking on dice (only during rolling phase)
		if state.phase == "rolling" then
			for i = 1, #state.dice do
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
		local playerState = game.getPlayerState()

		-- Check if clicking Return to Shop button (on victory)
		if game.isWon() then
			if x >= 300 and x <= 500 and y >= 400 and y <= 450 then
				game.awardVictory()
				game.startShop()
			end
		else
			-- Check if clicking Restart button (on loss)
			if x >= 300 and x <= 500 and y >= 400 and y <= 450 then
				game.resetAll()
			end
		end
	end
end

-- Handle keyboard input.
function love.keypressed(key)
	local state = game.getState()
	if not state then
		return
	end

	-- If the key is space and the phase is rolling, use a reroll
	if key == "space" and state.phase == "rolling" then
		if state.rerollsLeft > 0 then
			game.reroll()
		end
	-- If the key is escape, quit the game
	elseif key == "escape" then
		love.event.quit()
	-- If the key is r and in shop or gameover, reset
	elseif key == "r" and (state.phase == "shop" or state.phase == "gameover") then
		game.resetAll()
	end
end

-- Draw game.
function love.draw()
	local state = game.getState()
	if not state then
		return
	end

	if state.phase == "shop" then
		drawShop()
		return
	end

	-- Game phases (rolling, selecting, gameover)
	love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

	local playerState = game.getPlayerState()

	-- Title and score display (top)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("BALUT", 20, 20, 0, 2, 2)

	-- Coins display
	love.graphics.setColor(1, 0.8, 0)
	love.graphics.print("Coins: " .. playerState.coins, 200, 20, 0, 1.2, 1.2)

	if state.phase ~= "gameover" then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Hand: " .. state.currentHand .. "/" .. state.maxHands, 550, 20, 0, 1.3, 1.3)
		love.graphics.print("Score: " .. state.totalScore .. " / Goal: " .. state.goalScore, 550, 45, 0, 1.3, 1.3)
	end

	if state.phase == "rolling" or state.phase == "selecting" then
		-- Draw larger dice at the top center
		for i = 1, #state.dice do
			local diceX = 250 + ((i - 1) % 5) * 110
			local diceY = 80 + (math.floor((i - 1) / 5) * 110)
			local size = 100

			-- Draw die background
			if state.locked[i] then
				love.graphics.setColor(0.3, 0.6, 0.3) -- Green for locked
			else
				love.graphics.setColor(0.5, 0.5, 0.5) -- Gray for unlocked
			end
			love.graphics.rectangle("fill", diceX, diceY, size, size, 5, 5)

			-- Draw die border
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", diceX, diceY, size, size, 5, 5)

			-- Draw die value (larger text)
			love.graphics.print(tostring(state.dice[i]), diceX + 35, diceY + 25, 0, 3, 3)
		end

		-- Draw persistent category table on the left
		drawCategoryTable(state)

		-- Draw mods and tricks sidebar
		drawModsTricksSidebar()

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

			love.graphics.setColor(1, 1, 1)
			love.graphics.print("Final Score: " .. state.totalScore, 300, 330, 0, 1.5, 1.5)
			love.graphics.print("Goal Score: " .. state.goalScore, 300, 360, 0, 1.5, 1.5)

			-- Return to shop button
			love.graphics.setColor(0.2, 0.5, 0.8)
			love.graphics.rectangle("fill", 300, 400, 200, 50, 5, 5)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", 300, 400, 200, 50, 5, 5)
			love.graphics.print("RETURN TO SHOP", 315, 415, 0, 1.2, 1.2)
		else
			love.graphics.setColor(1, 0.3, 0.3)
			love.graphics.print("YOU LOSE!", 310, 270, 0, 2, 2)

			love.graphics.setColor(1, 1, 1)
			love.graphics.print("Final Score: " .. state.totalScore, 300, 330, 0, 1.5, 1.5)
			love.graphics.print("Goal Score: " .. state.goalScore, 300, 360, 0, 1.5, 1.5)

			-- Restart button (reset all progress)
			love.graphics.setColor(0.8, 0.3, 0.3)
			love.graphics.rectangle("fill", 300, 400, 200, 50, 5, 5)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", 300, 400, 200, 50, 5, 5)
			love.graphics.print("RESTART (R)", 330, 415, 0, 1.3, 1.3)
		end
	end
end
