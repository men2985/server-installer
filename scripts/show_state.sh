#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$DIR/.env"
SERVICES_FILE="$DIR/.services"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }

print_domain_info() {
  if [[ ! -f "$ENV_FILE" ]]; then
    return
  fi
  set -a
  source "$ENV_FILE"
  set +a
  if [[ -z "${MAIN_DOMAIN:-}" ]]; then
    return
  fi
  bold "Dominio detectado"
  echo "  Principal: ${MAIN_DOMAIN}"
  [[ -n "${TRAEFIK_SUB:-}" ]] && echo "  Traefik: ${TRAEFIK_SUB}.${MAIN_DOMAIN}"
  [[ -n "${PORTAINER_SUB:-}" ]] && echo "  Portainer: ${PORTAINER_SUB}.${MAIN_DOMAIN}"
  [[ -n "${REDISINSIGHT_SUB:-}" ]] && echo "  RedisInsight: ${REDISINSIGHT_SUB}.${MAIN_DOMAIN}"
  [[ -n "${N8N_SUB:-}" ]] && echo "  n8n: ${N8N_SUB}.${MAIN_DOMAIN}"
  [[ -n "${N8N_WEBHOOK_SUB:-}" ]] && echo "  n8n webhook: ${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}"
  [[ -n "${CHATWOOT_SUB:-}" ]] && echo "  Chatwoot: ${CHATWOOT_SUB}.${MAIN_DOMAIN}"
  [[ -n "${EVOAPI_SUB:-}" ]] && echo "  Evolution API: ${EVOAPI_SUB}.${MAIN_DOMAIN}"
  [[ -n "${RABBITMQ_EVOAPI_SUB:-}" ]] && echo "  RabbitMQ Evolution: ${RABBITMQ_EVOAPI_SUB}.${MAIN_DOMAIN}"
  echo ""
}

print_services_file() {
  local services=()
  if [[ -f "$SERVICES_FILE" ]]; then
    while IFS= read -r svc; do
      [[ -n "$svc" ]] && services+=("$svc")
    done <"$SERVICES_FILE"
  fi
  bold "Servicios seleccionados (.services)"
  if (( ${#services[@]} )); then
    printf '  %s\n' "${services[@]}"
  else
    echo "  <no se encontró .services; se asumirá perfil completo>"
  fi
  echo ""
}

print_running_stacks() {
  if ! command -v docker >/dev/null 2>&1; then
    return
  fi
  local stacks
  stacks=$(docker stack ls --format '{{.Name}}' 2>/dev/null || true)
  bold "Stacks Swarm activos"
  if [[ -n "$stacks" ]]; then
    while IFS= read -r name; do
      [[ -n "$name" ]] && echo "  $name"
    done <<<"$stacks"
  else
    echo "  <sin stacks desplegados>"
  fi
  echo ""
}

print_domain_info
print_services_file
print_running_stacks
