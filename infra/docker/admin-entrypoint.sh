#!/bin/sh
set -eu

: "${SUPABASE_URL:?SUPABASE_URL is required}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY is required}"
: "${APP_ENV:=production}"
export APP_ENV

envsubst '${SUPABASE_URL} ${SUPABASE_ANON_KEY} ${APP_ENV}' \
  < /opt/pet-friendly/runtime-config.template.js \
  > /usr/share/nginx/html/config/runtime-config.js

exec nginx -g 'daemon off;'
