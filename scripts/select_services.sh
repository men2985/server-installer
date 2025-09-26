#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICES_FILE="$DIR/.services"

declare -a AVAILABLE_SERVICES=(
  traefik
  portainer
  redis
  postgres
  n8n
  chatwoot
  evoapi
)

declare -A SERVICE_LABELS=(
  [traefik]="Traefik (proxy / certificados)"
  [portainer]="Portainer (panel de Docker)"
  [redis]="Redis + RedisInsight"
  [postgres]="Postgres genérico"
  [n8n]="n8n (automatización)"
  [chatwoot]="Chatwoot (atención)"
  [evoapi]="Evolution API + RabbitMQ"
)

declare -A DEPENDENCIES=(
  [n8n]="redis"
  [chatwoot]="redis"
  [evoapi]="redis"
)

declare -A PROFILES=(
  [completo]="traefik portainer redis postgres n8n chatwoot evoapi"
  [basico]="traefik portainer redis"
  [automatizacion]="traefik redis n8n"
  [atencion]="traefik portainer redis chatwoot evoapi"
)

declare -a DETECTED_STACKS=()
declare -a CURRENT_SELECTION=()

contains() {
  local needle="$1"; shift
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

read_list_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  while IFS= read -r line; do
    [[ -n "$line" ]] && echo "$line"
  done <"$file"
}

join_by() {
  local IFS="$1"; shift
  echo "$*"
}

print_service_list() {
  local prefix="$1"; shift
  local services=("$@")
  if (( ${#services[@]} )); then
    echo "${prefix}$(join_by ', ' "${services[@]}")"
  else
    echo "${prefix}(ninguno)"
  fi
}

detect_running_stacks() {
  command -v docker >/dev/null 2>&1 || return 0
  docker stack ls --format '{{.Name}}' 2>/dev/null | while IFS= read -r stack; do
    for svc in "${AVAILABLE_SERVICES[@]}"; do
      if [[ "$stack" == "$svc" ]]; then
        echo "$stack"
      fi
    done
  done | sort -u
}

prompt_yes_no() {
  local question="$1" default="${2:-si}" answer
  local def_lower=${default,,}
  local options="[${def_lower}]"
  while true; do
    read -r -p "$question ${options}: " answer || answer=""
    answer=${answer:-$default}
    answer=${answer,,}
    case "$answer" in
      si|s|yes|y) return 0 ;;
      no|n) return 1 ;;
      *) echo "Responde si o no." ;;
    esac
  done
}

select_profile_menu() {
  local choice default_choice=1
  echo ""
  if (( ${#CURRENT_SELECTION[@]} )); then
    print_service_list "Selección actual (.services): " "${CURRENT_SELECTION[@]}"
  fi
  if (( ${#DETECTED_STACKS[@]} )); then
    print_service_list "Stacks detectados en Docker Swarm: " "${DETECTED_STACKS[@]}"
  fi
  echo ""
  echo "Perfiles disponibles:"
  echo "  1) Completo (todos los servicios)"
  echo "  2) Básico (Traefik, Portainer, Redis)"
  echo "  3) Automatización (Traefik, Redis, n8n)"
  echo "  4) Atención + Bots (Traefik, Portainer, Redis, Chatwoot, EvoAPI)"
  local opt_keep=-1
  local opt_detected=-1
  local next_option=5
  if (( ${#CURRENT_SELECTION[@]} )); then
    opt_keep=$next_option
    echo "  ${next_option}) Mantener selección actual"
    default_choice=$opt_keep
    ((next_option++))
  fi
  if (( ${#DETECTED_STACKS[@]} )); then
    opt_detected=$next_option
    echo "  ${next_option}) Usar stacks detectados"
    if (( default_choice == 1 )); then
      default_choice=$opt_detected
    fi
    ((next_option++))
  fi
  echo "  0) Personalizado"

  read -r -p "Elige un perfil [${default_choice}]: " choice
  choice=${choice:-$default_choice}

  if [[ "$choice" == "0" ]]; then
    echo "custom"
    return
  fi

  if (( opt_keep > 0 )) && [[ "$choice" == "$opt_keep" ]]; then
    echo "CURRENT"
    return
  fi

  if (( opt_detected > 0 )) && [[ "$choice" == "$opt_detected" ]]; then
    echo "DETECTED"
    return
  fi

  case "$choice" in
    1) echo "${PROFILES[completo]}" ;;
    2) echo "${PROFILES[basico]}" ;;
    3) echo "${PROFILES[automatizacion]}" ;;
    4) echo "${PROFILES[atencion]}" ;;
    *) echo "${PROFILES[completo]}" ;;
  esac
}

prompt_custom_selection() {
  local preselected=("$@")
  local selection=()
  for svc in "${AVAILABLE_SERVICES[@]}"; do
    local default="no"
    if [[ "$svc" == "traefik" ]]; then
      default="si"
    elif contains "$svc" "${preselected[@]}"; then
      default="si"
    fi
    if prompt_yes_no "¿Habilitar ${SERVICE_LABELS[$svc]}?" "$default"; then
      selection+=("$svc")
    fi
  done
  echo "${selection[*]}"
}

write_services_file() {
  local services=("$@")
  if (( ${#services[@]} == 0 )); then
    rm -f "$SERVICES_FILE"
    return
  fi
  {
    for svc in "${services[@]}"; do
      echo "$svc"
    done
  } > "$SERVICES_FILE"
}

remove_disabled_stacks() {
  local stacks=("$@")
  command -v docker >/dev/null 2>&1 || return
  for stack in "${stacks[@]}"; do
    docker stack ls --format '{{.Name}}' 2>/dev/null | grep -qx "$stack" || continue
    if prompt_yes_no "¿Eliminar stack Docker '${stack}'?" "si"; then
      docker stack rm "$stack"
    fi
  done
}

sort_services() {
  local input=("$@")
  if (( ${#input[@]} == 0 )); then
    echo ""
    return
  fi
  printf '%s\n' "${input[@]}" | sort
}

main() {
  while IFS= read -r stack; do
    [[ -n "$stack" ]] && DETECTED_STACKS+=("$stack")
  done < <(detect_running_stacks)

  while IFS= read -r svc; do
    [[ -n "$svc" ]] && CURRENT_SELECTION+=("$svc")
  done < <(read_list_from_file "$SERVICES_FILE")

  local profile_choice
  profile_choice=$(select_profile_menu)

  local chosen_list
  case "$profile_choice" in
    custom)
      local preselected=("${CURRENT_SELECTION[@]}")
      for stack in "${DETECTED_STACKS[@]}"; do
        contains "$stack" "${preselected[@]}" || preselected+=("$stack")
      done
      chosen_list=$(prompt_custom_selection "${preselected[@]}")
      ;;
    CURRENT)
      chosen_list="${CURRENT_SELECTION[*]}"
      ;;
    DETECTED)
      chosen_list="${DETECTED_STACKS[*]}"
      ;;
    *)
      chosen_list="$profile_choice"
      ;;
  esac

  read -r -a selected <<<"${chosen_list:-${PROFILES[completo]}}"

  if (( ${#selected[@]} == 0 )); then
    echo "No se seleccionó ningún servicio; se usará el perfil completo."
    read -r -a selected <<<"${PROFILES[completo]}"
  fi

  declare -A selected_map=()
  declare -a final_selection=()
  for svc in "${selected[@]}"; do
    [[ -n "$svc" ]] || continue
    if [[ -z "${selected_map[$svc]:-}" ]]; then
      selected_map[$svc]=1
      final_selection+=("$svc")
    fi
  done

  declare -a added_deps=()
  for svc in "${final_selection[@]}"; do
    if [[ -n "${DEPENDENCIES[$svc]:-}" ]]; then
      for dep in ${DEPENDENCIES[$svc]}; do
        if [[ -z "${selected_map[$dep]:-}" ]]; then
          selected_map[$dep]=1
          final_selection+=("$dep")
          added_deps+=("$dep")
        fi
      done
    fi
  done

  if (( ${#added_deps[@]} )); then
    # deduplicate additions for message
    declare -A dep_seen=()
    declare -a deps_msg=()
    for dep in "${added_deps[@]}"; do
      if [[ -z "${dep_seen[$dep]:-}" ]]; then
        dep_seen[$dep]=1
        deps_msg+=("$dep")
      fi
    done
    print_service_list "Dependencias añadidas automáticamente: " "${deps_msg[@]}"
  fi

  if [[ -z "${selected_map[traefik]:-}" ]]; then
    echo "Traefik es obligatorio; se añadirá automáticamente."
    selected_map[traefik]=1
    final_selection+=(traefik)
  fi

  local sorted
  sorted=$(sort_services "${final_selection[@]}")
  read -r -a final_selection <<<"$sorted"

  print_service_list "Servicios habilitados: " "${final_selection[@]}"

  declare -a disabled=()
  for svc in "${CURRENT_SELECTION[@]}"; do
    [[ -n "$svc" ]] || continue
    if [[ -z "${selected_map[$svc]:-}" ]]; then
      disabled+=("$svc")
    fi
  done

  write_services_file "${final_selection[@]}"
  echo "Archivo .services actualizado."

  if (( ${#disabled[@]} )); then
    print_service_list "Servicios deshabilitados: " "${disabled[@]}"
    remove_disabled_stacks "${disabled[@]}"
  fi
}

main "$@"
