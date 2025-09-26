#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$DIR/.env"
DOM_FILE="$DIR/config/domains.yml"

if [[ ! -f "$DIR/.env.template" ]]; then
  cat > "$DIR/.env.template" <<'EOF'
MAIN_DOMAIN=
LETSENCRYPT_EMAIL=
TRAEFIK_SUB=traefik
PORTAINER_SUB=portainer
REDISINSIGHT_SUB=redis
N8N_SUB=n8n
N8N_WEBHOOK_SUB=webhook.n8n
CHATWOOT_SUB=chatwoot
EVOAPI_SUB=evoapi
RABBITMQ_EVOAPI_SUB=rabbitmq-evoapi
GLOBAL_PASSWORD=
GLOBAL_32_KEY=
EOF
fi

grep -q '^EVOAPI_SUB=' "$DIR/.env.template" || echo 'EVOAPI_SUB=evoapi' >> "$DIR/.env.template"
grep -q '^RABBITMQ_EVOAPI_SUB=' "$DIR/.env.template" || echo 'RABBITMQ_EVOAPI_SUB=rabbitmq-evoapi' >> "$DIR/.env.template"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$DIR/.env.template" "$ENV_FILE"
fi

for entry in "EVOAPI_SUB=evoapi" "RABBITMQ_EVOAPI_SUB=rabbitmq-evoapi"; do
  key=${entry%%=*}
  grep -q "^${key}=" "$ENV_FILE" || echo "$entry" >> "$ENV_FILE"
done

mkdir -p "$DIR/config"
[[ -f "$DOM_FILE" ]] || cat > "$DOM_FILE" <<YAML
main_domain:
subdomains:
  traefik: traefik
  portainer: portainer
  redisinsight: redis
  n8n: n8n
  n8n_webhook: webhook.n8n
  chatwoot: chatwoot
  evoapi: evoapi
  rabbitmq_evoapi: rabbitmq-evoapi
YAML

ask() { local var="$1" prompt="$2" def="$3"; read -r -p "$prompt [${def}]: " val; echo "${val:-$def}"; }

while true; do
  read -r -p "Dominio principal (ej. midominio.com): " MAIN
  [[ -n "$MAIN" ]] || { echo "No puede estar vacío."; continue; }
  echo "Has escrito: $MAIN. ¿Confirmas? (si/no)"; read -r ok
  [[ "$ok" == "si" ]] && break
done

read -r -p "Email para Let's Encrypt: " ACME

TRAEFIK_SUB=$(ask TRAEFIK_SUB "Subdominio Traefik" "traefik")
PORTAINER_SUB=$(ask PORTAINER_SUB "Subdominio Portainer" "portainer")
REDISINSIGHT_SUB=$(ask REDISINSIGHT_SUB "Subdominio RedisInsight" "redis")
N8N_SUB=$(ask N8N_SUB "Subdominio n8n" "n8n")
N8N_WEBHOOK_SUB=$(ask N8N_WEBHOOK_SUB "Subdominio n8n webhook" "webhook.n8n")
CHATWOOT_SUB=$(ask CHATWOOT_SUB "Subdominio Chatwoot" "chatwoot")
EVOAPI_SUB=$(ask EVOAPI_SUB "Subdominio Evolution API" "evoapi")
RABBITMQ_EVOAPI_SUB=$(ask RABBITMQ_EVOAPI_SUB "Subdominio RabbitMQ Evolution" "rabbitmq-evoapi")

# Escribir .env
sed -i "s/^MAIN_DOMAIN=.*/MAIN_DOMAIN=$MAIN/" "$ENV_FILE"
sed -i "s/^LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=$ACME/" "$ENV_FILE"
sed -i "s/^TRAEFIK_SUB=.*/TRAEFIK_SUB=$TRAEFIK_SUB/" "$ENV_FILE"
sed -i "s/^PORTAINER_SUB=.*/PORTAINER_SUB=$PORTAINER_SUB/" "$ENV_FILE"
sed -i "s/^REDISINSIGHT_SUB=.*/REDISINSIGHT_SUB=$REDISINSIGHT_SUB/" "$ENV_FILE"
sed -i "s/^N8N_SUB=.*/N8N_SUB=$N8N_SUB/" "$ENV_FILE"
sed -i "s/^N8N_WEBHOOK_SUB=.*/N8N_WEBHOOK_SUB=$N8N_WEBHOOK_SUB/" "$ENV_FILE"
sed -i "s/^CHATWOOT_SUB=.*/CHATWOOT_SUB=$CHATWOOT_SUB/" "$ENV_FILE"
sed -i "s/^EVOAPI_SUB=.*/EVOAPI_SUB=$EVOAPI_SUB/" "$ENV_FILE"
sed -i "s/^RABBITMQ_EVOAPI_SUB=.*/RABBITMQ_EVOAPI_SUB=$RABBITMQ_EVOAPI_SUB/" "$ENV_FILE"

# Escribir config/domains.yml
python3 - <<PY
import yaml
f="$DOM_FILE"
d=yaml.safe_load(open(f)) or {}
d["main_domain"]="$MAIN"
d["subdomains"]={
  "traefik":"$TRAEFIK_SUB",
  "portainer":"$PORTAINER_SUB",
  "redisinsight":"$REDISINSIGHT_SUB",
  "n8n":"$N8N_SUB",
  "n8n_webhook":"$N8N_WEBHOOK_SUB",
  "chatwoot":"$CHATWOOT_SUB",
  "evoapi":"$EVOAPI_SUB",
  "rabbitmq_evoapi":"$RABBITMQ_EVOAPI_SUB",
}
open(f,"w").write(yaml.safe_dump(d,sort_keys=False))
PY

# Guardar subdominios por servicio
STACK_ROOT="/home/docker"
declare -A STACK_SUBS=(
  [traefik]="$TRAEFIK_SUB"
  [portainer]="$PORTAINER_SUB"
  [redis]="$REDISINSIGHT_SUB"
  [n8n]="$N8N_SUB"
  [chatwoot]="$CHATWOOT_SUB"
  [evoapi]="$EVOAPI_SUB"
  [postgres]="postgres"
)

mkdir -p "$STACK_ROOT"
for svc in "${!STACK_SUBS[@]}"; do
  mkdir -p "$STACK_ROOT/$svc"
  printf '%s\n' "${STACK_SUBS[$svc]}" > "$STACK_ROOT/$svc/.subdomain"
done
mkdir -p "$STACK_ROOT/n8n"
printf '%s\n' "$N8N_WEBHOOK_SUB" > "$STACK_ROOT/n8n/.subdomain_webhook"
mkdir -p "$STACK_ROOT/evoapi"
printf '%s\n' "$RABBITMQ_EVOAPI_SUB" > "$STACK_ROOT/evoapi/.subdomain_rabbitmq"
