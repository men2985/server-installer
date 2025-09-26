#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$DIR/.env"
DOM_FILE="$DIR/config/domains.yml"
BUILD_DIR="$DIR/build"
STACK_ROOT="/home/docker"

SERVICES_FILE="$DIR/.services"
SERVICES_CACHE_LOADED=0
SERVICES_CACHE_EMPTY=1
SERVICES_CACHE=()

load_services_cache() {
  if (( SERVICES_CACHE_LOADED )); then
    return
  fi
  SERVICES_CACHE_LOADED=1
  SERVICES_CACHE=()
  if [[ -f "$SERVICES_FILE" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && SERVICES_CACHE+=("$line")
    done <"$SERVICES_FILE"
  fi
  if (( ${#SERVICES_CACHE[@]} )); then
    SERVICES_CACHE_EMPTY=0
  fi
}

service_enabled() {
  local svc="$1"
  load_services_cache
  if (( SERVICES_CACHE_EMPTY )); then
    return 0
  fi
  for item in "${SERVICES_CACHE[@]}"; do
    if [[ "$item" == "$svc" ]]; then
      return 0
    fi
  done
  return 1
}

reset_services_cache() {
  SERVICES_CACHE_LOADED=0
  SERVICES_CACHE_EMPTY=1
  SERVICES_CACHE=()
}

ensure_stack_enabled() {
  local stack="$1" label="${2:-$1}"
  if ! service_enabled "$stack"; then
    echo "El servicio '$label' no está habilitado en este servidor. Usa el menú (opción de servicios) o scripts/select_services.sh para activarlo." >&2
    return 1
  fi
}

enabled_services_list() {
  load_services_cache
  if (( SERVICES_CACHE_EMPTY )); then
    printf '%s
' traefik portainer redis postgres n8n chatwoot evoapi
  else
    printf '%s
' "${SERVICES_CACHE[@]}"
  fi
}

subdomain_tools_list() {
  local items=()
  service_enabled traefik && items+=(traefik)
  service_enabled portainer && items+=(portainer)
  service_enabled redis && items+=(redisinsight)
  service_enabled n8n && items+=(n8n n8n_webhook)
  service_enabled chatwoot && items+=(chatwoot)
  service_enabled evoapi && items+=(evoapi rabbitmq_evoapi)
  if (( ${#items[@]} == 0 )); then
    return 1
  fi
  printf '%s' "${items[0]}"
  for ((i=1; i<${#items[@]}; ++i)); do
    printf ', %s' "${items[i]}"
  done
}

require_env() { [[ -f "$ENV_FILE" ]] || { echo "Falta $ENV_FILE"; exit 1; }; set -a; source "$ENV_FILE"; set +a; }

confirm_domain() {
  local d="$1"
  [[ -n "$d" ]] || { echo "Dominio vacío"; return 1; }
  echo "Has escrito: $d. ¿Confirmas? (si/no)"; read -r ok
  [[ "$ok" == "si" ]]
}

yaml_get() { # yaml_get key fallback
  python3 - <<PY2 2>/dev/null || echo "$2"
import sys,yaml
d=yaml.safe_load(open("$DOM_FILE"))
keys=sys.argv[1].split(".")
v=d
for k in keys:
  v=v.get(k,{})
print(v if isinstance(v,str) else "")
PY2
}

yaml_set() { # yaml_set key value
python3 - "$DOM_FILE" "$1" "$2" <<'PY3'
import sys,yaml
dom_file, key_path, val = sys.argv[1:4]
k=key_path.split(".")
with open(dom_file) as f: d=yaml.safe_load(f) or {}
v=d
for kk in k[:-1]:
  if kk not in v or not isinstance(v[kk],dict): v[kk]={}
  v=v[kk]
v[k[-1]]=val
with open(dom_file,"w") as f: yaml.safe_dump(d,f,sort_keys=False)
PY3
}

set_main_domain() {
  local new="$1"
  require_env
  sed -i "s/^MAIN_DOMAIN=.*/MAIN_DOMAIN=$new/" "$ENV_FILE"
  yaml_set "main_domain" "$new"
  update_global_env_file
  echo "Dominio principal actualizado a: $new"
}

set_subdomain() {
  local tool="$1" new="$2" key=
  case "$tool" in
    traefik) key="traefik";;
    portainer) key="portainer";;
    redisinsight) key="redisinsight";;
    n8n) key="n8n";;
    n8n_webhook) key="n8n_webhook";;
    chatwoot) key="chatwoot";;
    evoapi) key="evoapi";;
    rabbitmq_evoapi) key="rabbitmq_evoapi";;
    *) echo "Herramienta desconocida"; return 1;;
  esac
  local stack
  if ! stack=$(stack_key_from_tool "$tool"); then
    echo "Herramienta desconocida" >&2
    return 1
  fi
  ensure_stack_enabled "$stack" "$tool" || return 1
  require_env
  sed -i "s/^$(echo ${tool^^} | tr - _)_SUB=.*/$(echo ${tool^^} | tr - _)_SUB=$new/" "$ENV_FILE" || true
  yaml_set "subdomains.$key" "$new"
  write_subdomain_file "$tool" "$new"
  echo "Subdominio $tool actualizado a: $new"
}

render_all() {
  "$DIR/scripts/render.sh" all
}

render_for_tool() {
  local tool="$1"
  local stack
  if ! stack=$(stack_key_from_tool "$tool"); then
    echo "Servicio desconocido: $tool" >&2
    return 1
  fi
  ensure_stack_enabled "$stack" "$tool" || return 1
  "$DIR/scripts/render.sh" "$stack"
}

redeploy_for_domain_change() {
  local file
  if service_enabled traefik; then
    file=$(stack_file traefik)
    [[ -f "$file" ]] && docker stack deploy -c "$file" traefik
  fi
  if service_enabled portainer; then
    file=$(stack_file portainer)
    [[ -f "$file" ]] && docker stack deploy -c "$file" portainer
  fi
  if service_enabled redis; then
    file=$(stack_file redis)
    [[ -f "$file" ]] && docker stack deploy -c "$file" redis
  fi
  if service_enabled postgres; then
    file=$(stack_file postgres)
    [[ -f "$file" ]] && docker stack deploy -c "$file" postgres
  fi
  if service_enabled n8n; then
    file=$(stack_file n8n)
    [[ -f "$file" ]] && docker stack deploy -c "$file" n8n
  fi
  if service_enabled evoapi; then
    file=$(stack_file evoapi)
    [[ -f "$file" ]] && docker stack deploy -c "$file" evoapi
  fi
  if service_enabled chatwoot; then
    file=$(stack_file chatwoot)
    if [[ -f "$file" ]]; then
      docker stack deploy -c "$file" chatwoot
      prepare_chatwoot_db || true
    fi
  fi
}

redeploy_for_tool() {
  local tool="$1"
  local stack
  if ! stack=$(stack_key_from_tool "$tool" 2>/dev/null); then
    stack="$tool"
  fi
  ensure_stack_enabled "$stack" "$tool" || return 1
  case "$tool" in
    traefik) docker stack deploy -c "$(stack_file traefik)" traefik ;;
    portainer) docker stack deploy -c "$(stack_file portainer)" portainer ;;
    redis|redisinsight) docker stack deploy -c "$(stack_file redis)" redis ;;
    n8n|n8n_webhook) docker stack deploy -c "$(stack_file n8n)" n8n ;;
    chatwoot)
      docker stack deploy -c "$(stack_file chatwoot)" chatwoot
      prepare_chatwoot_db || true
      ;;
    evoapi|rabbitmq_evoapi)
      docker stack deploy -c "$(stack_file evoapi)" evoapi
      ;;
    postgres)
      docker stack deploy -c "$(stack_file postgres)" postgres
      ;;
    *)
      echo "Servicio desconocido: $tool" >&2
      return 1
      ;;
  esac
}

stack_key_from_tool() {
  case "$1" in
    traefik) printf 'traefik' ;;
    portainer) printf 'portainer' ;;
    redis|redisinsight) printf 'redis' ;;
    postgres) printf 'postgres' ;;
    n8n|n8n_webhook) printf 'n8n' ;;
    chatwoot) printf 'chatwoot' ;;
    evoapi|rabbitmq_evoapi) printf 'evoapi' ;;
    *) return 1 ;;
  esac
}

stack_file() {
  local key="$1"
  case "$key" in
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

write_subdomain_file() {
  local tool="$1" value="$2" dir key file
  if [[ "$tool" == "n8n_webhook" ]]; then
    dir="$STACK_ROOT/n8n"
    file="$dir/.subdomain_webhook"
  elif [[ "$tool" == "rabbitmq_evoapi" ]]; then
    dir="$STACK_ROOT/evoapi"
    file="$dir/.subdomain_rabbitmq"
  else
    key=$(stack_key_from_tool "$tool") || return 1
    dir="$STACK_ROOT/$key"
    file="$dir/.subdomain"
  fi
  mkdir -p "$dir"
  printf '%s
' "$value" > "$file"
}

update_global_env_file() {
  require_env
  mkdir -p "$STACK_ROOT"
  cat > "$STACK_ROOT/.env.global" <<EOF
COMMON_PASSWORD=${GLOBAL_PASSWORD:-}
BASE_DOMAIN=${MAIN_DOMAIN:-}
SECRET_KEY=${GLOBAL_32_KEY:-}
EOF
}

chatwoot_run() {
  docker run --rm \
    --network backend \
    --env-file "$ENV_FILE" \
    -e RAILS_ENV=production \
    -v /home/docker/chatwoot/chatwoot_storage:/app/storage \
    chatwoot/chatwoot:latest \
    bash -lc "$*"
}

prepare_chatwoot_db() {
  local timeout=300
  local interval=5
  local elapsed=0
  local delay=30
  local log_file="${TMPDIR:-/tmp}/chatwoot_prepare.log"

  echo "Preparando base de datos de Chatwoot..."
  require_env
  sleep "$delay"

  if ! docker network inspect backend >/dev/null 2>&1; then
    echo "No se encontró la red backend; omitiendo preparación automática."
    return 1
  fi

  if chatwoot_run "bundle exec rails runner 'exit(ActiveRecord::Base.connection.table_exists?(:installation_configs) ? 0 : 1)'" >/dev/null 2>&1; then
    echo "Chatwoot ya está inicializado."
    return 0
  fi

  echo "Esperando a que chatwoot-postgres esté disponible..."
  while (( elapsed < timeout )); do
    if docker service ps chatwoot_chatwoot-postgres --format '{{.CurrentState}}' | grep -q '^Running'; then
      break
    fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  if (( elapsed >= timeout )); then
    echo "chatwoot-postgres no alcanzó el estado Running; omitiendo preparación."
    return 1
  fi

  echo "Ejecutando db:chatwoot_prepare (ver $log_file)..."
  if chatwoot_run "bundle exec rails db:chatwoot_prepare" >"$log_file" 2>&1; then
    echo "Chatwoot listo. Reiniciando servicios..."
    docker service update --force chatwoot_rails >/dev/null 2>&1 || true
    docker service update --force chatwoot_sidekiq >/dev/null 2>&1 || true
    return 0
  fi

  echo "No se pudo preparar Chatwoot automáticamente. Revisa $log_file o ejecuta manualmente:"
  echo "  docker exec -it \$(docker ps -q -f name=chatwoot_rails) bundle exec rails db:chatwoot_prepare" >&2
  return 1
}

restart_portainer() {
  echo -n "¿Reiniciar Portainer ahora? (si/no): "; read -r ans
  [[ "$ans" == "si" ]] && docker service update --force portainer_portainer || echo "Ok, no se reinicia."
}

update_tool() {
  echo "Elige herramienta: traefik | portainer | redis | postgres | n8n | chatwoot | evoapi"
  read -r tool
  local stack
  if ! stack=$(stack_key_from_tool "$tool" 2>/dev/null); then
    stack="$tool"
  fi
  if ! service_enabled "$stack"; then
    echo "El servicio '$tool' no está habilitado. Actívalo desde el selector de servicios antes de actualizar." >&2
    return 1
  fi
  case "$tool" in
    traefik) docker service update --image traefik:latest traefik_traefik ;;
    portainer)
      docker service update --image portainer/agent:latest portainer_agent || true
      docker service update --image portainer/portainer-ce:latest portainer_portainer ;;
    redis)
      docker service update --image redis:latest redis_redis-server || true
      docker service update --image redislabs/redisinsight:latest redis_redisinsight || true ;;
    postgres)
      docker service update --image postgres:latest postgres_postgres-server ;;
    n8n)
      docker service update --image n8nio/n8n:latest n8n_n8n_editor || true
      docker service update --image n8nio/n8n:latest n8n_n8n_worker || true
      docker service update --image n8nio/n8n:latest n8n_n8n_webhook || true
      ;;
    chatwoot)
      docker service update --image chatwoot/chatwoot:latest chatwoot_rails || true
      docker service update --image chatwoot/chatwoot:latest chatwoot_sidekiq || true
      ;;
    evoapi)
      docker service update --image evoapicloud/evolution-api:latest evoapi_evolution-api || true
      docker service update --image postgres:15 evoapi_postgres-evoapi || true
      docker service update --image rabbitmq:management evoapi_rabbitmq || true
      ;;
    *) echo "Herramienta inválida" ;;
  esac
}

show_current_config() {
  require_env
  echo "Dominio principal: $MAIN_DOMAIN"
  echo "Subdominios:"
  local printed=0
  if service_enabled traefik; then
    echo "  Traefik: ${TRAEFIK_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled portainer; then
    echo "  Portainer: ${PORTAINER_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled redis; then
    echo "  RedisInsight: ${REDISINSIGHT_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled n8n; then
    echo "  n8n: ${N8N_SUB}.${MAIN_DOMAIN}"
    echo "  n8n webhook: ${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled chatwoot; then
    echo "  Chatwoot: ${CHATWOOT_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled evoapi; then
    echo "  Evolution API: ${EVOAPI_SUB}.${MAIN_DOMAIN}"
    echo "  RabbitMQ Evolution: ${RABBITMQ_EVOAPI_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if (( ! printed )); then
    echo "  <ningún servicio habilitado>"
  fi
}

show_urls_summary() {
  require_env
  echo ""
  echo "Accesos:"
  local printed=0
  if service_enabled traefik; then
    printf '  %-21s %s
' 'Traefik:' "https://${TRAEFIK_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled portainer; then
    printf '  %-21s %s
' 'Portainer:' "https://${PORTAINER_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled redis; then
    printf '  %-21s %s
' 'RedisInsight:' "https://${REDISINSIGHT_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled n8n; then
    printf '  %-21s %s
' 'n8n:' "https://${N8N_SUB}.${MAIN_DOMAIN}"
    printf '  %-21s %s
' 'n8n webhook:' "https://${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled chatwoot; then
    printf '  %-21s %s
' 'Chatwoot:' "https://${CHATWOOT_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if service_enabled evoapi; then
    printf '  %-21s %s
' 'Evolution API:' "https://${EVOAPI_SUB}.${MAIN_DOMAIN}"
    printf '  %-21s %s
' 'RabbitMQ Evolution:' "https://${RABBITMQ_EVOAPI_SUB}.${MAIN_DOMAIN}"
    printed=1
  fi
  if (( ! printed )); then
    echo "  <sin servicios habilitados>"
  fi
  echo ""
  echo "Credenciales/keys (guárdalas):"
  echo "  GLOBAL_PASSWORD: ${GLOBAL_PASSWORD:-<no definido>}"
  echo "  GLOBAL_32_KEY:   ${GLOBAL_32_KEY:-<no definido>}"
}
