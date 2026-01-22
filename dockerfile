# Dockerfile for OpenCode Isolated (Node 20 LTS)
FROM node:20.19.0-bullseye

# Set working directory
WORKDIR /app

# Install OS dependencies
# - postgresql-client: for DB utils
# - gosu: for stepping down from root in entrypoint
# - curl: for downloading Go
RUN apt-get update && apt-get install -y \
     build-essential \
     chromium \
     chromium-driver \
     python3-pip \
     python3-venv \
     postgresql-client \
     gosu \
     curl \
     && rm -rf /var/lib/apt/lists/* && \
     pip3 install pipx

# Install Golang (Latest Stable)
RUN curl -L https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Set python pipx environment
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx ensurepath
ENV PATH="/root/.local/bin:${PATH}"

# Install uv
RUN pipx install uv

# Install OpenCode CLI globally
RUN npm install -g opencode-ai

# Copy source
COPY . .

# Setup entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create necessary directories (owned by node initially)
# Note: The 'node' user exists in the base image
RUN mkdir -p /home/node/.local/share/opencode && \
    mkdir -p /home/node/.config/opencode && \
    mkdir -p /home/node/.cache/uv && \
    mkdir -p /home/node/go/pkg/mod && \
    chown -R node:node /home/node

# Set Chrome path environment variable
ENV CHROME_PATH=/usr/bin/chromium

# Set Entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default to no arguments (will start in /app)
CMD ["opencode"]
