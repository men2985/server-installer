#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

source "$DIR/scripts/utils.sh"

# 1) Prerrequisitos
"$DIR/scripts/prereqs.sh"

# 2) Prompt variables + confirmación de dominio + subdominios
"$DIR/scripts/prompt_env.sh"

# 3) Generar secretos (si faltan): GLOBAL_PASSWORD (10) + GLOBAL_32_KEY (32)
"$DIR/scripts/gen_secrets.sh"

# 4) Seleccionar servicios/perfil
"$DIR/scripts/select_services.sh"

# 5) Crear directorios en /home/docker/* (si faltan)
"$DIR/bootstrap/mkdirs.sh"

# 6) Renderizar plantillas .tpl → build/*.yml
"$DIR/scripts/render.sh"

# 7) Deploy ordenado
"$DIR/scripts/deploy.sh"

# 8) Resumen + menú interactivo
"$DIR/scripts/summary.sh"
"$DIR/menu.sh"
