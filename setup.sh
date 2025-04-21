#!/bin/bash

set -e  # Exit on any error

BOOMERANG_JSON='{
  "slug": "boomerang-mode",
  "name": "🔄 Boomerang Mode",
  "roleDefinition": "You are Roo, a strategic workflow orchestrator who coordinates complex tasks by delegating them to appropriate specialized modes. You maintain a persistent understanding of the project context across tasks and sessions, leveraging the memory system to retrieve and preserve structured knowledge from subtask results. You directly manage task tracking using Task Master CLI.",
  "customInstructions": "Use the memory system (store_memory, retrieve_memory, search_by_tag, etc.) to maintain context and preserve knowledge across tasks and sessions. When working with tasks and subtasks, use the exact Task Master CLI commands - for main tasks: use '\''task-master add-task'\'', '\''task-master set-status'\'', '\''task-master list'\'', '\''task-master show'\''. For subtasks: use '\''task-master add-subtask -p <parent_id> -t \\\"<title>\\\" -d \\\"<description>\\\"'\'' to add specific subtasks, and '\''task-master add-dependency --id=<id> --depends-on=<id>'\'' to create dependencies between tasks or subtasks.",
  "groups": [
    "command",
    "mcp"
  ],
  "source": "global"
}'

CUSTOM_MODES_PATH="$HOME/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/custom_modes.json"

echo "👉 Checking if Task Master CLI is installed..."
if command -v task-master >/dev/null 2>&1; then
  echo "✅ Task Master is already installed."
else
  echo "📦 Installing Task Master via npm..."
  npm install -g @stevescruz/task-master
fi

echo "👉 Checking if jq is installed..."
if command -v jq >/dev/null 2>&1; then
  echo "✅ jq is already installed."
else
  echo "📦 Installing jq via Homebrew..."
  brew install jq
fi

echo "👉 Cloning MCP Memory Service..."
git clone https://github.com/doobidoo/mcp-memory-service.git
cd mcp-memory-service

echo "👉 Creating and activating virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo "👉 Running installation script..."
python install.py

echo "👉 Appending Boomerang Mode to custom_modes.json..."

# Ensure the file exists
mkdir -p "$(dirname "$CUSTOM_MODES_PATH")"
touch "$CUSTOM_MODES_PATH"

# If it's empty or invalid, reset to an empty array
if ! jq . "$CUSTOM_MODES_PATH" > /dev/null 2>&1; then
  echo '{ "customModes": [] }' > "$CUSTOM_MODES_PATH"
fi

# Avoid duplicate
if jq -e --arg slug "boomerang-mode" '.customModes[]? | select(.slug == $slug)' "$CUSTOM_MODES_PATH" > /dev/null; then
  echo "⚠️  Boomerang Mode already exists. Skipping addition."
else
  TMP_JSON=$(mktemp)
  jq --argjson newMode "$BOOMERANG_JSON" '.customModes += [$newMode]' "$CUSTOM_MODES_PATH" > "$TMP_JSON" && mv "$TMP_JSON" "$CUSTOM_MODES_PATH"
  echo "✅ Boomerang Mode added to custom_modes.json"
fi

echo "🎉 All done!"
