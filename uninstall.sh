#!/usr/bin/env bash
set -euo pipefail

echo "Esto eliminará los stacks (chatwoot, n8n, postgres, redis, portainer, traefik). ¿Continuar? (si/no)"
read -r ok
[[ "$ok" == "si" ]] || { echo "Cancelado"; exit 0; }

# Detener stacks
for s in chatwoot n8n postgres redis portainer traefik; do
  docker stack rm "$s" || true
done

# Guardar certificado de Traefik si existe
TMP_CERT_DIR="${TMPDIR:-/tmp}/traefik-cert"
CERT_PATH="/home/docker/traefik/letsencrypt/acme.json"

mkdir -p "$TMP_CERT_DIR"
if [[ -f "$CERT_PATH" ]]; then
  cp "$CERT_PATH" "$TMP_CERT_DIR/acme.json"
fi

# Eliminar directorios
rm -rf /home/docker /home/infra

# Restaurar certificado y estructura mínima
mkdir -p /home/docker/traefik/letsencrypt
if [[ -f "$TMP_CERT_DIR/acme.json" ]]; then
  cp "$TMP_CERT_DIR/acme.json" /home/docker/traefik/letsencrypt/acme.json
  echo "Certificado de Traefik restaurado."
else
  echo "No se encontró certificado previo; se pedirá uno nuevo en la próxima instalación."
fi
rm -rf "$TMP_CERT_DIR"

echo "Stacks eliminados y directorios limpiados (se conservó el certificado de Traefik si existía)."
