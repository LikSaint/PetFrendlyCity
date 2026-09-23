FROM node:24.12.0-bookworm-slim

WORKDIR /workspace

COPY --chown=node:node package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY --chown=node:node scripts ./scripts
COPY --chown=node:node supabase ./supabase

ENV NODE_ENV=production
ENV HOME=/tmp

USER node

ENTRYPOINT ["node", "scripts/deploy-database.mjs"]
