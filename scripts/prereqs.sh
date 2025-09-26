#!/usr/bin/env bash
set -euo pipefail

# Docker presente?
command -v docker >/dev/null || { echo "Instala Docker antes de continuar"; exit 1; }

# Dependencias auxiliares
command -v python3 >/dev/null || { echo "Instala python3 antes de continuar"; exit 1; }
command -v envsubst >/dev/null || { echo "Instala envsubst (paquete gettext) antes de continuar"; exit 1; }

# Swarm
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
  docker swarm init || true
fi

# Redes overlay
for net in frontend backend; do
  if docker network inspect "$net" >/dev/null 2>&1; then
    attachable=$(docker network inspect "$net" --format '{{.Attachable}}' 2>/dev/null || echo false)
    if [[ "$attachable" != "true" ]]; then
      docker network rm "$net" >/dev/null 2>&1 || true
      docker network create -d overlay --attachable "$net"
    fi
  else
    docker network create -d overlay --attachable "$net"
  fi
done

# Backups dir
mkdir -p /home/backups
