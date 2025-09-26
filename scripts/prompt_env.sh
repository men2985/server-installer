#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$DIR/.env"
DOM_FILE="$DIR/config/domains.yml"
SERVICES_FILE="$DIR/.services"
DEFAULT_SERVICES=(traefik portainer redis postgres n8n chatwoot evoapi)

if [[ ! -f "$DIR/.env.template" ]]; then
  cat > "$DIR/.env.template" <<'TPL'
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
TPL
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
[[ -f "$DOM_FILE" ]] || cat > "$DOM_FILE" <<'YAML'
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

set -a; source "$ENV_FILE"; set +a

SELECTED_SERVICES=()
if [[ -f "$SERVICES_FILE" ]]; then
  while IFS= read -r svc; do
    [[ -n "$svc" ]] && SELECTED_SERVICES+=("$svc")
  done <"$SERVICES_FILE"
fi
if (( ${#SELECTED_SERVICES[@]} == 0 )); then
  SELECTED_SERVICES=("${DEFAULT_SERVICES[@]}")
fi

service_selected() {
  local needle="$1"
  for svc in "${SELECTED_SERVICES[@]}"; do
    if [[ "$svc" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

default_or() {
  local current="$1" fallback="$2"
  if [[ -n "$current" ]]; then
    printf '%s' "$current"
  else
    printf '%s' "$fallback"
  fi
}

ask() {
  local prompt="$2" def="$3" val
  read -r -p "$prompt [${def}]: " val
  echo "${val:-$def}"
}

prompt_domain() {
  while true; do
    read -r -p "Dominio principal (ej. midominio.com): " MAIN
    [[ -n "$MAIN" ]] || { echo "No puede estar vacío."; continue; }
    echo "Has escrito: $MAIN. ¿Confirmas? (si/no)"; read -r ok
    [[ "${ok:-no}" == "si" ]] && break
  done
}

CURRENT_MAIN_DOMAIN=${MAIN_DOMAIN:-}
if [[ -n "$CURRENT_MAIN_DOMAIN" ]]; then
  read -r -p "Se detectó dominio actual ($CURRENT_MAIN_DOMAIN). ¿Mantenerlo? (si/no) [si]: " keep_domain
  keep_domain=${keep_domain:-si}
  if [[ "$keep_domain" == "si" ]]; then
    MAIN="$CURRENT_MAIN_DOMAIN"
  else
    prompt_domain
  fi
else
  prompt_domain
fi

CURRENT_ACME=${LETSENCRYPT_EMAIL:-}
if [[ -n "$CURRENT_ACME" ]]; then
  read -r -p "Email para Let's Encrypt [$CURRENT_ACME]: " ACME
  ACME=${ACME:-$CURRENT_ACME}
else
  read -r -p "Email para Let's Encrypt: " ACME
fi

TRAEFIK_DEFAULT=$(default_or "${TRAEFIK_SUB:-}" traefik)
PORTAINER_DEFAULT=$(default_or "${PORTAINER_SUB:-}" portainer)
REDIS_DEFAULT=$(default_or "${REDISINSIGHT_SUB:-}" redis)
N8N_DEFAULT=$(default_or "${N8N_SUB:-}" n8n)
N8N_WEBHOOK_DEFAULT=$(default_or "${N8N_WEBHOOK_SUB:-}" webhook.n8n)
CHATWOOT_DEFAULT=$(default_or "${CHATWOOT_SUB:-}" chatwoot)
EVOAPI_DEFAULT=$(default_or "${EVOAPI_SUB:-}" evoapi)
RABBIT_DEFAULT=$(default_or "${RABBITMQ_EVOAPI_SUB:-}" rabbitmq-evoapi)

if service_selected traefik; then
  TRAEFIK_SUB=$(ask TRAEFIK_SUB "Subdominio Traefik" "$TRAEFIK_DEFAULT")
else
  TRAEFIK_SUB="$TRAEFIK_DEFAULT"
fi

if service_selected portainer; then
  PORTAINER_SUB=$(ask PORTAINER_SUB "Subdominio Portainer" "$PORTAINER_DEFAULT")
else
  PORTAINER_SUB="$PORTAINER_DEFAULT"
fi

if service_selected redis; then
  REDISINSIGHT_SUB=$(ask REDISINSIGHT_SUB "Subdominio RedisInsight" "$REDIS_DEFAULT")
else
  REDISINSIGHT_SUB="$REDIS_DEFAULT"
fi

if service_selected n8n; then
  N8N_SUB=$(ask N8N_SUB "Subdominio n8n" "$N8N_DEFAULT")
  N8N_WEBHOOK_SUB=$(ask N8N_WEBHOOK_SUB "Subdominio n8n webhook" "$N8N_WEBHOOK_DEFAULT")
else
  N8N_SUB="$N8N_DEFAULT"
  N8N_WEBHOOK_SUB="$N8N_WEBHOOK_DEFAULT"
fi

if service_selected chatwoot; then
  CHATWOOT_SUB=$(ask CHATWOOT_SUB "Subdominio Chatwoot" "$CHATWOOT_DEFAULT")
else
  CHATWOOT_SUB="$CHATWOOT_DEFAULT"
fi

if service_selected evoapi; then
  EVOAPI_SUB=$(ask EVOAPI_SUB "Subdominio Evolution API" "$EVOAPI_DEFAULT")
  RABBITMQ_EVOAPI_SUB=$(ask RABBITMQ_EVOAPI_SUB "Subdominio RabbitMQ Evolution" "$RABBIT_DEFAULT")
else
  EVOAPI_SUB="$EVOAPI_DEFAULT"
  RABBITMQ_EVOAPI_SUB="$RABBIT_DEFAULT"
fi

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

STACK_ROOT="/home/docker"
declare -A STACK_SUBS=()
if service_selected traefik; then STACK_SUBS[traefik]="$TRAEFIK_SUB"; fi
if service_selected portainer; then STACK_SUBS[portainer]="$PORTAINER_SUB"; fi
if service_selected redis; then STACK_SUBS[redis]="$REDISINSIGHT_SUB"; fi
if service_selected n8n; then STACK_SUBS[n8n]="$N8N_SUB"; fi
if service_selected chatwoot; then STACK_SUBS[chatwoot]="$CHATWOOT_SUB"; fi
if service_selected evoapi; then STACK_SUBS[evoapi]="$EVOAPI_SUB"; fi
if service_selected postgres; then STACK_SUBS[postgres]="postgres"; fi

mkdir -p "$STACK_ROOT"
for svc in "${!STACK_SUBS[@]}"; do
  mkdir -p "$STACK_ROOT/$svc"
  printf '%s\n' "${STACK_SUBS[$svc]}" > "$STACK_ROOT/$svc/.subdomain"
done

if service_selected n8n; then
  mkdir -p "$STACK_ROOT/n8n"
  printf '%s\n' "$N8N_WEBHOOK_SUB" > "$STACK_ROOT/n8n/.subdomain_webhook"
fi

if service_selected evoapi; then
  mkdir -p "$STACK_ROOT/evoapi"
  printf '%s\n' "$RABBITMQ_EVOAPI_SUB" > "$STACK_ROOT/evoapi/.subdomain_rabbitmq"
fi
