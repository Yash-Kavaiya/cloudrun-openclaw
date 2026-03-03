# 🦞 OpenClaw Gateway on Cloud Run

Deploy [OpenClaw](https://docs.openclaw.ai) — a self-hosted AI gateway — on **Google Cloud Run** with **Gemini API** as the primary model provider.

## What is OpenClaw?

OpenClaw is an open-source, multi-channel AI gateway that connects messaging platforms (WhatsApp, Telegram, Discord, Slack, etc.) to AI models. It features:

- **Multi-channel messaging** — One gateway serves all your channels
- **Agent-native** — Built-in tool use, sessions, memory, and multi-agent routing
- **Model-agnostic** — Supports Gemini, Claude, GPT, Ollama, and 20+ providers
- **Self-hosted** — Runs on your infrastructure, your rules

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 Google Cloud Run                 │
│  ┌─────────────────────────────────────────────┐ │
│  │          OpenClaw Gateway (Node.js 22)       │ │
│  │                                              │ │
│  │  ┌──────────┐  ┌──────────┐  ┌───────────┐  │ │
│  │  │ Control  │  │  Agent   │  │  Channel   │  │ │
│  │  │   UI     │  │  Engine  │  │  Manager   │  │ │
│  │  └──────────┘  └────┬─────┘  └───────────┘  │ │
│  │                     │                         │ │
│  │              ┌──────▼──────┐                  │ │
│  │              │ Gemini API  │                  │ │
│  │              │  (2.5 Pro)  │                  │ │
│  │              └─────────────┘                  │ │
│  └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## Prerequisites

- **Google Cloud** account with billing enabled
- **gcloud CLI** installed ([Install guide](https://cloud.google.com/sdk/docs/install))
- **Docker** installed locally (for building/testing)
- **Gemini API Key** ([Get one here](https://aistudio.google.com/apikey))

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Yash-Kavaiya/cloudrun-openclaw.git
cd cloudrun-openclaw
```

### 2. Set Up Environment Variables

```bash
cp .env.example .env
# Edit .env with your values:
#   GEMINI_API_KEY=your-key
#   OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
#   GCP_PROJECT_ID=your-project-id
```

### 3. Test Locally with Docker

```bash
# Build the image
docker build -t openclaw-cloudrun .

# Run locally
docker run -d --name openclaw-local \
  -e GEMINI_API_KEY=your-gemini-api-key \
  -e OPENCLAW_GATEWAY_TOKEN=your-token \
  -p 8080:8080 \
  openclaw-cloudrun

# Open Control UI
open http://localhost:8080
```

### 4. Deploy to Cloud Run (Manual)

```bash
# Set your project
export PROJECT_ID=your-gcp-project-id
export REGION=us-central1

# Authenticate
gcloud auth login
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com

# Create Artifact Registry repository
gcloud artifacts repositories create openclaw \
  --repository-format=docker \
  --location=$REGION

# Store secrets in Secret Manager
echo -n "your-gemini-api-key" | \
  gcloud secrets create GEMINI_API_KEY --data-file=-

echo -n "$(openssl rand -hex 32)" | \
  gcloud secrets create OPENCLAW_GATEWAY_TOKEN --data-file=-

# Build and push image
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/openclaw/openclaw-gateway:latest"
docker build -t $IMAGE .
docker push $IMAGE

# Deploy to Cloud Run
gcloud run deploy openclaw-gateway \
  --image=$IMAGE \
  --region=$REGION \
  --port=8080 \
  --memory=1Gi \
  --cpu=1 \
  --min-instances=1 \
  --max-instances=3 \
  --no-cpu-throttling \
  --allow-unauthenticated \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest,OPENCLAW_GATEWAY_TOKEN=OPENCLAW_GATEWAY_TOKEN:latest"
```

### 5. Deploy via CI/CD (GitHub Actions)

Set these **GitHub repository secrets** (Settings → Secrets → Actions):

| Secret | Description |
|--------|-------------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `GCP_REGION` | GCP region (optional, defaults to `us-central1`) |
| `GCP_SA_KEY` | Service account JSON key (with Cloud Run Admin + Artifact Registry + Secret Manager roles) |
| `GEMINI_API_KEY` | Your Google Gemini API key |
| `OPENCLAW_GATEWAY_TOKEN` | Gateway auth token (generate with `openssl rand -hex 32`) |

> The pipeline automatically syncs `GEMINI_API_KEY` and `OPENCLAW_GATEWAY_TOKEN` from GitHub secrets into GCP Secret Manager, and grants Cloud Run access.

Push to `main` to trigger automatic build & deployment.

## Project Structure

```
cloudrun-openclaw/
├── .github/workflows/
│   └── deploy.yml          # GitHub Actions CI/CD pipeline
├── .dockerignore            # Docker build exclusions
├── .env.example             # Environment variable reference
├── cloudbuild.yaml          # GCP Cloud Build config (alternative to GitHub Actions)
├── Dockerfile               # Container image definition
├── openclaw.json            # OpenClaw base configuration
├── start.sh                 # Container startup script
└── README.md                # This file
```

## Configuration

### Model Configuration

The default model is `google/gemini-2.5-pro`. To change it, edit `openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "google/gemini-2.5-flash"
      }
    }
  }
}
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GEMINI_API_KEY` | ✅ | Google Gemini API key |
| `OPENCLAW_GATEWAY_TOKEN` | ✅ | Gateway auth token |
| `OPENCLAW_SYSTEM_PROMPT` | ❌ | Custom system prompt |
| `PORT` | ❌ | Server port (Cloud Run sets this, default: 8080) |

## Useful Commands

```bash
# View Cloud Run logs
gcloud run services logs read openclaw-gateway --region=us-central1

# Get service URL
gcloud run services describe openclaw-gateway \
  --region=us-central1 --format='value(status.url)'

# Update secrets
echo -n "new-key" | gcloud secrets versions add GEMINI_API_KEY --data-file=-

# Force redeploy
gcloud run services update openclaw-gateway --region=us-central1
```

## Docs & Resources

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Gemini API Docs](https://ai.google.dev/docs)
- [Cloud Run Docs](https://cloud.google.com/run/docs)

## License

MIT