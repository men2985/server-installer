#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$DIR/.env"

gen_alnum() {
  local len="$1"
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$len"
}

# GLOBAL_PASSWORD (10) y GLOBAL_32_KEY (32)
grep -q '^GLOBAL_PASSWORD=' "$ENV_FILE" || echo "GLOBAL_PASSWORD=" >> "$ENV_FILE"
grep -q '^GLOBAL_32_KEY=' "$ENV_FILE" || echo "GLOBAL_32_KEY=" >> "$ENV_FILE"

if [[ -z "$(grep '^GLOBAL_PASSWORD=' "$ENV_FILE" | cut -d= -f2-)" ]]; then
  sed -i "s/^GLOBAL_PASSWORD=.*/GLOBAL_PASSWORD=$(gen_alnum 10)/" "$ENV_FILE"
fi
if [[ -z "$(grep '^GLOBAL_32_KEY=' "$ENV_FILE" | cut -d= -f2-)" ]]; then
  sed -i "s/^GLOBAL_32_KEY=.*/GLOBAL_32_KEY=$(gen_alnum 32)/" "$ENV_FILE"
fi

set -a; source "$ENV_FILE"; set +a
mkdir -p /home/docker
cat > /home/docker/.env.global <<EOF
COMMON_PASSWORD=${GLOBAL_PASSWORD}
BASE_DOMAIN=${MAIN_DOMAIN}
SECRET_KEY=${GLOBAL_32_KEY}
EOF
