#!/usr/bin/env bash
set -euo pipefail
# Traefik
mkdir -p /home/docker/traefik/letsencrypt
# Portainer
mkdir -p /home/docker/portainer/portainer_data
# Redis
mkdir -p /home/docker/redis/redis_cache /home/docker/redis/redisinsight
# Postgres
mkdir -p /home/docker/postgres/postgres_data
# n8n
mkdir -p /home/docker/n8n/db /home/docker/n8n/data /home/docker/n8n/local-files
# Chatwoot
mkdir -p /home/docker/chatwoot/chatwoot_storage /home/docker/chatwoot/postgres_data
# Evolution API
mkdir -p /home/docker/evoapi/evolution_instances /home/docker/evoapi/evolution_postgres_data /home/docker/evoapi/rabbitmq_data
