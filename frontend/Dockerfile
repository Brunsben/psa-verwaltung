# ── Stage 1: Build ───────────────────────────────────────────────────────────
FROM node:25-alpine AS build
WORKDIR /app

# Dependencies
COPY package*.json ./
RUN npm ci

# Source
COPY . .

# Vendor-Libs, Icons + Manifest in Vite public/ verschieben
RUN mkdir -p public && \
    { cp -r vendor public/ 2>/dev/null || true; } && \
    { cp -r icons public/ 2>/dev/null || true; } && \
    { cp manifest.json public/ 2>/dev/null || true; } && \
    { cp service-worker.js public/ 2>/dev/null || true; }

# config.js wird NICHT eingebaut (runtime-Konfiguration, via Volume gemountet)
RUN npm run build

# ── Stage 2: Serve ───────────────────────────────────────────────────────────
FROM nginx:1.28-alpine
COPY --from=build /app/dist /usr/share/nginx/html
# nginx.conf + config.js werden per docker-compose Volume gemountet
