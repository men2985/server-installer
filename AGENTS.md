# Repository Guidelines

## Estructura del proyecto
El código operativo vive en `scripts/` (prerrequisitos, selección, render, deploy, secretos). Las plantillas Docker Swarm están en `stacks/` y los auxiliares de directorios en `bootstrap/`. Los valores base residen en `.env.template` y `config/domains.yml`; al renderizar se copian a `/home/docker/<servicio>/`. Versiona únicamente plantillas, scripts y docs, nunca artefactos generados ni archivos en `/home/docker/`.

## Comandos clave de instalación y desarrollo
Verifica dependencias con `./scripts/prereqs.sh` (Docker activo, Python3, redes overlay). Selecciona o reconfigura módulos con `./scripts/select_services.sh`; actualiza `.services`, habilita dependencias (Redis para Chatwoot/Evolution) y elimina stacks obsoletos. Genera manifiestos con `./scripts/render.sh [servicio|all]` y despliega con `./scripts/deploy.sh [servicio|all]`. Para un alta completa ejecuta `./install_core.sh`. Valida cada script tocado con `bash -n scripts/<archivo>.sh` y, si está disponible, `shellcheck`.

## Estilo y convenciones
Todos los scripts comienzan con `#!/usr/bin/env bash` y `set -euo pipefail`. Mantén nombres en minúsculas con guiones en `scripts/` y variables en MAYÚSCULAS con guion bajo (`GLOBAL_PASSWORD`, `EVOAPI_SUB`). Usa sangría de dos espacios en YAML y alinea etiquetas Traefik para revisiones claras. Evita credenciales embebidas; apóyate en placeholders y `gen_secrets.sh`.

## Guía de pruebas
No hay framework dedicado; las validaciones son manuales. Tras editar un script, corre `bash -n` y `shellcheck`. Si tocas una plantilla, ejecuta `./scripts/render.sh servicio`, revisa `build/<servicio>.yml` y valida en staging con `docker stack deploy --compose-file build/<servicio>.yml --prune --with-registry-auth <servicio>`. Documenta en la PR las verificaciones manuales (acceso a Traefik, alta inicial en Portainer/Chatwoot).

## Commits y Pull Requests
Sigue prefijos estilo Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`) y limita el asunto a 72 caracteres. Agrupa cambios relacionados por commit. Las PR deben explicar alcance, listar comandos ejecutados (`select_services`, `render`, `deploy`, validaciones manuales) y referenciar issues. Incluye fragmentos antes/después para YAML o variables que afecten la instalación.

## Seguridad y configuración
Trata `.env`, `/home/docker/.env.global` y cualquier archivo bajo `/home/docker/<servicio>/` como secretos. Al añadir un módulo, declara sus claves en `env_template.txt`, usa `gen_alnum` y registra dependencias en `scripts/select_services.sh`. Verifica que `bootstrap/mkdirs.sh` cubra nuevos directorios antes de desplegar y evita usar `docker stack deploy` sobre archivos no generados con `render.sh`.
