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

# Helper logic: If the first argument is a directory, file, or starts with '-', 
# assume the user wants to pass it to 'opencode' rather than run it as a command.
if [ -n "$1" ]; then
    if [ -d "$1" ] || [ -f "$1" ] || [ "${1:0:1}" = "-" ]; then
        set -- opencode "$@"
    fi
fi

echo "Starting OpenCode..."
exec gosu node "$@"
