#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$DIR/build"
STACK_ROOT="/home/docker"
SERVICES_FILE="$DIR/.services"

set -a; source "$DIR/.env"; set +a

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

render_stack() {
  local tmpl="$1" build_name="$2" folder="$3" filename="$4"
  mkdir -p "$BUILD" "$STACK_ROOT/$folder"
  envsubst < "$tmpl" > "$BUILD/$build_name.yml"
  cp "$BUILD/$build_name.yml" "$STACK_ROOT/$folder/$filename"
}

render_service() {
  case "$1" in
    traefik) render_stack "$DIR/stacks/traefik.yml.tpl" traefik traefik traefik-deploy.yml ;;
    portainer) render_stack "$DIR/stacks/portainer.yml.tpl" portainer portainer portainer-deploy.yml ;;
    redis) render_stack "$DIR/stacks/redis.yml.tpl" redis redis redis-deploy.yml ;;
    postgres) render_stack "$DIR/stacks/postgres.yml.tpl" postgres postgres postgres-deploy.yml ;;
    n8n) render_stack "$DIR/stacks/n8n.yml.tpl" n8n n8n n8n-deploy.yml ;;
    chatwoot) render_stack "$DIR/stacks/chatwoot.yml.tpl" chatwoot chatwoot chatwoot-deploy.yml ;;
    evoapi) render_stack "$DIR/stacks/evoapi.yml.tpl" evoapi evoapi evoapi-deploy.yml ;;
    *)
      echo "Servicio desconocido: $1" >&2
      return 1
      ;;
  esac
}

case "${1:-all}" in
  all)
    load_selected_services
    for svc in "${SELECTED_SERVICES[@]}"; do
      render_service "$svc"
    done
    ;;
  traefik|portainer|redis|postgres|n8n|chatwoot|evoapi)
    render_service "$1"
    ;;
  *)
    echo "Uso: $0 [traefik|portainer|redis|postgres|n8n|chatwoot|evoapi|all]" >&2
    exit 1
    ;;
esac

echo "Plantillas renderizadas en $STACK_ROOT"
