#!/bin/bash
set -e

# Default to 1000 if not set
USER_ID=${HOST_UID:-1000}
GROUP_ID=${HOST_GID:-1000}

echo "Configuring environment for UID: $USER_ID, GID: $GROUP_ID..."

# Update the 'node' user ID and group ID to match the host
# -o allow using non-unique IDs if necessary
# We ignore errors if the ID is already set correctly
if [ "$(id -u node)" != "$USER_ID" ]; then
    usermod -u $USER_ID -o node
fi

if [ "$(id -g node)" != "$GROUP_ID" ]; then
    groupmod -g $GROUP_ID -o node
fi

# Ensure internal directories are owned by the updated user
# We strictly limit this to the home directory to avoid touching the mounted /app volume
# which can be slow and is usually unnecessary if UIDs match.
chown -R node:node /home/node

# Add go to path for the user if not present (defensive)
export PATH=$PATH:/usr/local/go/bin:/home/node/go/bin

# Detect and activate Python virtual environment if present
# This checks the target directory for common venv locations
TARGET_DIR=""
if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        TARGET_DIR="$1"
    elif [ -f "$1" ]; then
        TARGET_DIR="$(dirname "$1")"
    fi
fi

# If we have a target directory, check for virtual environment
if [ -n "$TARGET_DIR" ]; then
    # Check for venv in priority order: .venv, venv, env
    for venv_name in .venv venv env; do
        venv_path="$TARGET_DIR/$venv_name"
        if [ -d "$venv_path" ]; then
            if [ -f "$venv_path/bin/activate" ]; then
                echo "Found Python virtual environment at: $venv_path"
                echo "Activating virtual environment..."
                # Export the VIRTUAL_ENV variable and update PATH
                export VIRTUAL_ENV="$venv_path"
                export PATH="$venv_path/bin:$PATH"
                # Unset PYTHONHOME if set (can interfere with venv)
                unset PYTHONHOME
                echo "Virtual environment activated successfully"
                break
            else
                echo "Warning: Found venv directory at $venv_path but it appears incomplete (missing bin/activate)"
                echo "Continuing without virtual environment activation..."
            fi
        fi
    done
fi

# Helper logic: If the first argument is a directory, file, or starts with '-', 
# assume the user wants to pass it to 'opencode' rather than run it as a command.
if [ -n "$1" ]; then
    if [ -d "$1" ] || [ -f "$1" ] || [ "${1:0:1}" = "-" ]; then
        set -- opencode "$@"
    fi
fi

echo "Starting OpenCode..."
exec gosu node "$@"
