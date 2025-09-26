#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

source "$DIR/scripts/utils.sh"

# 1) Prerrequisitos
"$DIR/scripts/prereqs.sh"

# 2) Mostrar estado detectado
"$DIR/scripts/show_state.sh"

# 3) Seleccionar servicios/perfil
"$DIR/scripts/select_services.sh"

# 4) Prompt variables + confirmación de dominio + subdominios
"$DIR/scripts/prompt_env.sh"

# 5) Generar secretos (si faltan): GLOBAL_PASSWORD (10) + GLOBAL_32_KEY (32)
"$DIR/scripts/gen_secrets.sh"

# 6) Crear directorios en /home/docker/* (si faltan)
"$DIR/bootstrap/mkdirs.sh"

# 7) Renderizar plantillas .tpl → build/*.yml
"$DIR/scripts/render.sh"

# 8) Deploy ordenado
"$DIR/scripts/deploy.sh"

# 9) Resumen + menú interactivo
"$DIR/scripts/summary.sh"
"$DIR/menu.sh"
