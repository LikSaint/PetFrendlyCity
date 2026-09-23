FROM node:24.12.0-bookworm-slim AS build

WORKDIR /app
COPY web/admin/package.json web/admin/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY web/admin/ ./
RUN npm run build

FROM nginx:1.29-alpine

COPY infra/docker/admin-nginx.conf /etc/nginx/nginx.conf
COPY infra/docker/admin-runtime-config.template.js /opt/pet-friendly/runtime-config.template.js
COPY infra/docker/admin-entrypoint.sh /usr/local/bin/pet-friendly-admin-entrypoint
COPY --from=build --chown=nginx:nginx /app/dist/pet-friendly-admin/browser /usr/share/nginx/html

RUN chmod 755 /usr/local/bin/pet-friendly-admin-entrypoint \
  && mkdir -p /usr/share/nginx/html/config \
  && chown -R nginx:nginx /usr/share/nginx/html/config

USER nginx
EXPOSE 8080

ENTRYPOINT ["pet-friendly-admin-entrypoint"]
