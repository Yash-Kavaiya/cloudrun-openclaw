#!/bin/bash
set -e

echo "=== OpenClaw Gateway Startup ==="
echo "PORT: ${PORT:-8080}"

# Configure Gemini API key from environment variable
if [ -n "$GEMINI_API_KEY" ]; then
  echo "Configuring Gemini API key..."
  openclaw config set agents.defaults.model.primary "google/gemini-2.5-pro"
  openclaw config set agents.defaults.providers.google.apiKey "$GEMINI_API_KEY"
else
  echo "WARNING: GEMINI_API_KEY not set. The gateway will start but AI responses will fail."
fi

# Configure gateway auth token from environment variable
if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
  echo "Configuring gateway auth token..."
  openclaw config set gateway.auth.token "$OPENCLAW_GATEWAY_TOKEN"
fi

# Configure system prompt if provided
if [ -n "$OPENCLAW_SYSTEM_PROMPT" ]; then
  echo "Configuring custom system prompt..."
  openclaw config set agents.defaults.systemPrompt "$OPENCLAW_SYSTEM_PROMPT"
fi

echo "Starting OpenClaw Gateway on port ${PORT:-8080}..."

# Start the gateway, binding to all interfaces (required by Cloud Run)
exec openclaw gateway --port "${PORT:-8080}" --bind lan
