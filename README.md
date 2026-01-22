# OpenCode Isolated Environment

An isolated, Dockerized development sandbox for [OpenCode](https://opencode.ai) featuring [Chrome DevTools MCP](https://github.com), **Go**, and **Python (uv)**.

## Configuration (`opencode.jsonc`)

To enable the browser agent, ensure your `~/.config/opencode/opencode.jsonc` on your **host machine** includes the following MCP block. The container will use this via the volume mount.

```jsonc
{
  "$schema": "https://opencode.aiconfig.json",
  "theme": "opencode",
  "model": "anthropic/claude-3-5-sonnet", 
  "mcp": {
    "chrome-devtools": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "chrome-devtools-mcp@latest",
        "--headless"
      ],
      "enabled": true
    }
  }
}
```


## Deployment & Launch

Build the Environment:
Installs Chromium, Go 1.23, uv, and Postgres tools.
    
```bash
docker compose build
```

### Start a New Session:
Launches the OpenCode agent in an interactive terminal.

To start in a specific project (mapped from `~/projects` on your host to `/projects` in the container):

```bash
docker compose run --rm opencode /projects/my-project-name
```

To start in the default directory:

```bash
docker compose run --rm opencode
```

### Session Management
#### Open a new bash shell inside the existing container
```bash
docker exec -it opencode-isolated /bin/bash
```

#### Re-attach your STDIN/STDOUT to the running agent process
```bash
docker attach opencode-isolated
```

## Data Persistence
Chat sessions and other data are persisted in a Docker volume named `opencode_data`. This ensures that your chat history is preserved across container restarts.

To clear the session history (and fix permission issues after an update), remove the volume:

```bash
docker compose down -v
```

## Included Toolchain

Browser: Headless Chromium (Path: /usr/bin/chromium-browser)
Python: uv for ultra-fast dependency management.
Go: Go 1.23 stable.
DB Tools: psql (PostgreSQL client) and libpq-dev.

## Troubleshooting Volume Permissions
If you encounter permission issues writing to your project folder, ensure you export your local user IDs before running:

```bash
export UID=$(id -u)
export GID=$(id -g)
docker-compose run --rm opencode
```
