#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
STACK_ROOT="/home/docker"
SERVICES_FILE="$DIR/.services"

load_selected_services() {
  SELECTED_SERVICES=()
  if [[ -f "$SERVICES_FILE" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && SELECTED_SERVICES+=("$line")
    done <"$SERVICES_FILE"
  fi
  if [[ ${#SELECTED_SERVICES[@]} -eq 0 ]]; then
    SELECTED_SERVICES=(traefik portainer redis postgres n8n chatwoot evoapi)
  fi
}

stack_compose_path() {
  case "$1" in
    traefik) echo "$STACK_ROOT/traefik/traefik-deploy.yml" ;;
    portainer) echo "$STACK_ROOT/portainer/portainer-deploy.yml" ;;
    redis) echo "$STACK_ROOT/redis/redis-deploy.yml" ;;
    postgres) echo "$STACK_ROOT/postgres/postgres-deploy.yml" ;;
    n8n) echo "$STACK_ROOT/n8n/n8n-deploy.yml" ;;
    chatwoot) echo "$STACK_ROOT/chatwoot/chatwoot-deploy.yml" ;;
    evoapi) echo "$STACK_ROOT/evoapi/evoapi-deploy.yml" ;;
    *) return 1 ;;
  esac
}

deploy_service() {
  local svc="$1"
  local file
  file=$(stack_compose_path "$svc") || {
    echo "No se encontró el archivo de stack para $svc" >&2
    return 1
  }
  docker stack deploy -c "$file" "$svc"
}

case "${1:-all}" in
  all)
    load_selected_services
    for svc in "${SELECTED_SERVICES[@]}"; do
      deploy_service "$svc"
    done
    ;;
  traefik|portainer|redis|postgres|n8n|chatwoot|evoapi)
    deploy_service "$1"
    ;;
  *)
    echo "Uso: $0 [traefik|portainer|redis|postgres|n8n|chatwoot|evoapi|all]" >&2
    exit 1
    ;;
esac
