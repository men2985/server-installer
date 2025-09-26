#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/scripts/utils.sh"
while true; do
  echo ""
  echo "==== MENÚ ===="
  echo "1) Ver configuración actual"
  echo "2) Cambiar dominio principal"
  echo "3) Cambiar subdominios"
  echo "4) Reiniciar Portainer"
  echo "5) Actualizar herramienta (solo imágenes :latest)"
  echo "6) Backup (/home → /home/backups)"
  echo "7) Restore (desde /home/backups/*.tar.gz)"
  echo "8) Ver URLs y credenciales"
  echo "9) Cambiar servicios instalados"
  echo "10) Salir"
  echo -n "> "; read -r opt

  case "$opt" in
    1) show_current_config ;;
    2)
      echo -n "Nuevo dominio: "; read -r nd
      confirm_domain "$nd" || continue
      set_main_domain "$nd"
      render_all
      redeploy_for_domain_change
      ;;
    3)
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
    4) restart_portainer ;;
    5) update_tool ;;
    6) do_backup ;;
    7) do_restore ;;
    8) show_urls_summary ;;
    9)
      if "$DIR/scripts/select_services.sh"; then
        reset_services_cache
        render_all
        "$DIR/scripts/deploy.sh" all
        show_urls_summary
      else
        echo "No se modificaron los servicios."
      fi
      ;;
    10) exit 0 ;;
    *) echo "Opción inválida" ;;
  esac
done
