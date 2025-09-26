#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/scripts/utils.sh"

cmd="${1:-interactive}"

case "$cmd" in
  set-main)
    new="${2:-}"
    [[ -n "$new" ]] || { echo "Uso: $0 set-main nuevo-dominio.com"; exit 1; }
    set_main_domain "$new"
    render_all
    redeploy_for_domain_change
    show_urls_summary
    ;;
  set-sub)
    tool="${2:-}"; new="${3:-}"
    [[ -n "$tool" && -n "$new" ]] || { echo "Uso: $0 set-sub <traefik|portainer|redisinsight|n8n|n8n_webhook|chatwoot|evoapi|rabbitmq_evoapi> <subdominio>"; exit 1; }
    if set_subdomain "$tool" "$new"; then
      render_for_tool "$tool"
      redeploy_for_tool "$tool"
      show_urls_summary
    else
      echo "No se actualizó el subdominio."
      exit 1
    fi
    ;;
  services)
    if "$DIR/scripts/select_services.sh"; then
      reset_services_cache
      render_all
      "$DIR/scripts/deploy.sh" all
      show_urls_summary
    else
      echo "No se modificaron los servicios."
    fi
    ;;
  show)
    show_current_config
    ;;
  *)
    # interactivo básico
    while true; do
      echo "== Reconfiguración =="
      echo "1) Cambiar dominio principal"
      echo "2) Cambiar subdominios"
      echo "3) Ver configuración actual"
      echo "4) Cambiar servicios instalados"
      echo "5) Salir"
      read -r opt
      case "$opt" in
        1)
          echo -n "Nuevo dominio: "; read -r nd
          confirm_domain "$nd" || continue
          set_main_domain "$nd"
          render_all
          redeploy_for_domain_change
          ;;
        2)
          if ! tools_list=$(subdomain_tools_list); then
            echo "No hay servicios con subdominio configurables en esta instalación."
            continue
          fi
          echo "Herramientas: $tools_list"
          echo -n "Cuál?: "; read -r tool
          echo -n "Nuevo subdominio: "; read -r ns
          if set_subdomain "$tool" "$ns"; then
            render_for_tool "$tool"
            redeploy_for_tool "$tool"
          else
            echo "No se actualizó el subdominio."
          fi
          ;;
        3) show_current_config ;;
        4)
          if "$DIR/scripts/select_services.sh"; then
            reset_services_cache
            render_all
            "$DIR/scripts/deploy.sh" all
            show_urls_summary
          else
            echo "No se modificaron los servicios."
          fi
          ;;
        5) exit 0 ;;
        *) echo "Opción inválida" ;;
      esac
    done
    ;;
esac
