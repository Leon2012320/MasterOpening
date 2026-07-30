# syntax=docker/dockerfile:1

# ── Bauen ────────────────────────────────────────────────────────────────────
FROM node:22-slim AS build

WORKDIR /app

# Prisma braucht OpenSSL, um seine Engine zu laden.
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Erst die Abhängigkeiten: die ändern sich seltener als der Code, und so
# bleibt die Schicht zwischen zwei Bauten gültig.
COPY package.json package-lock.json ./
COPY prisma ./prisma
RUN npm ci

COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

# ── Laufen ───────────────────────────────────────────────────────────────────
FROM node:22-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production

RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist

# Die SQLite-Datei liegt im Volume, nicht im Abbild.
VOLUME ["/data"]
ENV DATABASE_URL="file:/data/masteropening.db"

# Nicht als root: der Dienst braucht keine Rechte, die er nicht nutzt.
RUN chown -R node:node /app /data 2>/dev/null || true
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Schema anlegen oder fortschreiben, dann starten.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
