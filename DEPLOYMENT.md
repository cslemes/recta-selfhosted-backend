# Backend Deployment (Railway)

## Prerequisites

1. A [Railway](https://railway.app) account
2. A GitHub repository for the backend code

## Setup

### 1. Create Railway Project

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Create project (or link existing)
railway init
```

### 2. Add Services in Railway Dashboard

1. **PostgreSQL**: Add → Database → PostgreSQL
2. **Redis**: Add → Database → Redis
3. **Backend**: Add → GitHub Repo → Select your backend repo

### 3. Configure Environment Variables

In Railway Dashboard → Backend Service → Variables:

```env
# Database (auto-generated if using Railway Postgres)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Redis (auto-generated if using Railway Redis)
REDIS_URL=${{Redis.REDIS_URL}}

# Server
PORT=3000
NODE_ENV=production

# CORS – your Vercel frontend URL
ALLOWED_ORIGINS=https://your-app.vercel.app

# Firebase Admin (required)
GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-service-account.json
# OR use individual credentials:
# FIREBASE_PROJECT_ID=your-project-id
# FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com
# FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### 4. Firebase Service Account

Since Railway doesn't support file mounts, use the individual credentials approach:

1. Go to Firebase Console → Project Settings → Service Accounts
2. Generate new private key
3. Add each field to Railway environment variables

### 5. GitHub Actions Secrets

In your GitHub repository → Settings → Secrets and variables → Actions:

| Secret | Description |
|--------|-------------|
| `RAILWAY_TOKEN` | Railway API token from [Account Settings](https://railway.app/account/tokens) |

### 6. (Optional) Repository Variables

In GitHub → Settings → Secrets → Variables:

| Variable | Description |
|----------|-------------|
| `RAILWAY_SERVICE_NAME` | Service name in Railway (default: `backend`) |

## Deployment

Push to `main` branch triggers automatic deployment via GitHub Actions.

### Manual Deployment

```bash
railway up
```

## Cron Job Service

For recurring transactions processing, create a second service in Railway:

1. Add → GitHub Repo → Same backend repo
2. Set a different service name (e.g., `cron`)
3. Configure in Railway Dashboard → Service → Settings:
   - **Start Command**: `node dist/jobs/processRecurrences.js`
   - **Cron Schedule**: `0 5 * * *` (daily at 5 AM UTC)

Environment variables for cron service:

```env
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
NODE_ENV=production
RAILWAY_CRON_SERVICE=true
```
