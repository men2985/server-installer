#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
set -a; source "$DIR/.env"; set +a

SERVICES_FILE="$DIR/.services"
ENABLED_SERVICES=()
SERVICES_EMPTY=1
if [[ -f "$SERVICES_FILE" ]]; then
  while IFS= read -r svc; do
    [[ -n "$svc" ]] && ENABLED_SERVICES+=("$svc")
  done <"$SERVICES_FILE"
fi
if (( ${#ENABLED_SERVICES[@]} )); then
  SERVICES_EMPTY=0
fi

service_enabled() {
  local svc="$1"
  if (( SERVICES_EMPTY )); then
    return 0
  fi
  for item in "${ENABLED_SERVICES[@]}"; do
    if [[ "$item" == "$svc" ]]; then
      return 0
    fi
  done
  return 1
}

echo ""
echo "=== RESUMEN DE INSTALACIÓN ==="
if service_enabled traefik; then
  printf 'Traefik:       https://%s
' "${TRAEFIK_SUB}.${MAIN_DOMAIN}"
fi
if service_enabled portainer; then
  printf 'Portainer:     https://%s
' "${PORTAINER_SUB}.${MAIN_DOMAIN}"
fi
if service_enabled redis; then
  printf 'RedisInsight:  https://%s
' "${REDISINSIGHT_SUB}.${MAIN_DOMAIN}"
fi
if service_enabled n8n; then
  printf 'n8n:           https://%s
' "${N8N_SUB}.${MAIN_DOMAIN}"
  printf 'n8n webhook:   https://%s
' "${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}"
fi
if service_enabled chatwoot; then
  printf 'Chatwoot:      https://%s
' "${CHATWOOT_SUB}.${MAIN_DOMAIN}"
fi
if service_enabled evoapi; then
  printf 'Evolution API: https://%s
' "${EVOAPI_SUB}.${MAIN_DOMAIN}"
  printf 'RabbitMQ Evolution: https://%s
' "${RABBITMQ_EVOAPI_SUB}.${MAIN_DOMAIN}"
fi

echo ""
echo "GLOBAL_PASSWORD: ${GLOBAL_PASSWORD}"
echo "GLOBAL_32_KEY:   ${GLOBAL_32_KEY}"

echo ""
if service_enabled chatwoot; then
  echo "────────────────────────────────────────────────────"
  echo " Paso manual requerido: inicializar Chatwoot"
  echo "────────────────────────────────────────────────────"
  echo "Ejecuta en el servidor (una sola vez tras el despliegue):"
  echo "  docker exec -it \$(docker ps -q -f name=chatwoot_rails) bundle exec rails db:chatwoot_prepare"
  echo "Si actualizas la configuración después, puedes refrescar los servicios con:"
  echo "  docker service update --force chatwoot_rails chatwoot_sidekiq"
  echo ""
fi
if service_enabled portainer; then
  echo "Ve a Portainer y crea tu usuario ahora."
  echo -n "¿Reiniciar Portainer ahora? (si/no): "
  read -r ans
  [[ "$ans" == "si" ]] && docker service update --force portainer_portainer || echo "Ok, no se reinicia."
fi
