.PHONY: all dev start check fix clean

# Project name
GAME_NAME = balut

# Directories
SRC_DIR = src
BUILD_DIR = build

# Output file
LOVE_FILE = $(BUILD_DIR)/$(GAME_NAME).love

all:
	@mkdir -p $(BUILD_DIR)
	@echo "Building $(LOVE_FILE)..."
	@cd $(SRC_DIR) && zip -9 -r ../$(LOVE_FILE) .
	@echo "Build complete: $(LOVE_FILE)"

# Run the game from source
# Use this for development
dev:
	love $(SRC_DIR)

# Run the built .love file
# Use this for testing the build
start: all
	love $(LOVE_FILE)

# Check the code for issues
check:
	stylua $(SRC_DIR) --check

# Fix the code for issues
fix:
	stylua $(SRC_DIR)

# Clean build artifacts
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Build directory cleaned"
