# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Balut is a game built with [LÖVE](https://love2d.org/) (LÖVE 11.4), a Lua-based 2D game framework.

### Game Mechanics

For detailed information about how the Balut dice game works, including:
- Game screens (Shop and Game)
- Gameplay rules (hands, rerolls, scoring categories)
- Available upgrades

See **[RULES.md](./RULES.md)** in the repository root.

## Running the Game

To run the game during development:
```bash
love src
```

This executes LÖVE with the current directory, which will load `src/conf.lua` for configuration and `src/main.lua` as the entry point.

## Code Architecture

### Entry Points
- **src/conf.lua**: LÖVE configuration file that sets up the game window (800x600, non-resizable), modules, and engine settings
- **src/main.lua**: Main game logic containing LÖVE callback functions (currently implements `love.draw()`)

### LÖVE Framework Pattern
The game follows LÖVE's callback-based architecture. Key callbacks to implement in `src/main.lua`:
- `love.load()`: Initialize game state
- `love.update(dt)`: Update game logic each frame (dt = delta time)
- `love.draw()`: Render graphics each frame
- `love.keypressed(key)`, `love.keyreleased(key)`: Handle keyboard input
- `love.mousepressed(x, y, button)`: Handle mouse input

All LÖVE framework callbacks should be defined in `src/main.lua` or required modules.

## Project Structure

Source code lives in the `src/` directory. The project uses a flat structure currently with configuration and main logic at the top level.
