# ============================================================
# Backend – multi-stage distroless production image
# ============================================================

# ── Base (build toolchain only) ──────────────────────────────
FROM node:20-alpine AS base
WORKDIR /app

# ── Dependencies (cached layer) ─────────────────────────────
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci --ignore-scripts

# ── Build ────────────────────────────────────────────────────
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY prisma ./prisma
COPY prisma.config.ts ./
RUN npx prisma generate
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ── Prune (keep only production deps) ────────────────────────
FROM base AS prune
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
RUN npm prune --omit=dev && rm -rf /app/node_modules/.cache

# ── Production (distroless – no shell, no OS packages) ───────
FROM gcr.io/distroless/nodejs20-debian12:nonroot AS production

WORKDIR /app

# Production dependencies – chown to nonroot (uid 65532) for prisma engine access
COPY --from=prune --chown=65532:65532 /app/node_modules ./node_modules

# Prisma artefacts
COPY --from=build --chown=65532:65532 /app/src/generated ./src/generated
COPY --chown=65532:65532 prisma ./prisma
COPY --chown=65532:65532 prisma.config.ts ./

# Application code
COPY --from=build --chown=65532:65532 /app/dist ./dist
COPY --chown=65532:65532 package.json ./
COPY --chown=65532:65532 entrypoint.mjs ./

EXPOSE 3000

# distroless/nodejs sets ENTRYPOINT ["/nodejs/bin/node"]
# Node.js ≥ 20 handles SIGTERM properly as PID 1
CMD ["entrypoint.mjs"]
