FROM node:22-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    socat curl ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user directories for OpenClaw
RUN mkdir -p /home/node/.openclaw/workspace \
    && chown -R node:node /home/node

WORKDIR /app

# Install OpenClaw globally
RUN npm install -g openclaw@latest

# Copy OpenClaw configuration
COPY openclaw.json /home/node/.openclaw/openclaw.json

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh \
    && chown -R node:node /app /home/node/.openclaw

# Run as non-root user
USER node

ENV HOME=/home/node
ENV NODE_ENV=production
ENV PORT=8080

EXPOSE 8080

CMD ["/app/start.sh"]
