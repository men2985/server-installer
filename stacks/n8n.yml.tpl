version: '3.8'
services:
  n8n-db:
    image: docker.io/bitnami/postgresql:16
    restart: always
    user: root
    environment:
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_DATABASE=n8n
      - POSTGRESQL_PASSWORD=${GLOBAL_PASSWORD}
    networks:
      - backend
    deploy:
      replicas: 1
      placement:
        constraints: [node.role == manager]
    volumes:
      - n8n_db:/bitnami/postgresql

  n8n_editor:
    image: n8nio/n8n:latest
    restart: always
    user: root
    environment:
      - N8N_ENCRYPTION_KEY=${GLOBAL_32_KEY}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=${GLOBAL_PASSWORD}
      - N8N_PROTOCOL=https
      - N8N_HOST=${N8N_SUB}.${MAIN_DOMAIN}
      - N8N_EDITOR_BASE_URL=https://${N8N_SUB}.${MAIN_DOMAIN}
      - WEBHOOK_URL=https://${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}
      - NODE_ENV=production
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
      - EXECUTIONS_MODE=queue
      - N8N_TRUST_PROXY=true
      - QUEUE_BULL_REDIS_HOST=redis-server
      - QUEUE_BULL_REDIS_DB=2
      - QUEUE_BULL_REDIS_PORT=6379
      - OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true
      - N8N_RUNNERS_ENABLED=true
      - N8N_SECURE_COOKIE=false
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.http.routers.n8n_editor.rule=Host(`${N8N_SUB}.${MAIN_DOMAIN}`)
        - traefik.http.routers.n8n_editor.service=n8n_editor
        - traefik.http.routers.n8n_editor.entrypoints=websecure
        - traefik.http.routers.n8n_editor.tls.certresolver=le
        - traefik.http.routers.n8n_editor.tls=true
        - traefik.http.services.n8n_editor.loadbalancer.server.port=5678
    volumes:
      - n8n_data:/home/node/.n8n
      - n8n_local-files:/files
    networks:
      - frontend
      - backend

  n8n_worker:
    image: n8nio/n8n:latest
    restart: always
    user: root
    command: worker --concurrency=5
    environment:
      - N8N_ENCRYPTION_KEY=${GLOBAL_32_KEY}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=${GLOBAL_PASSWORD}
      - N8N_PROTOCOL=https
      - N8N_HOST=${N8N_SUB}.${MAIN_DOMAIN}
      - N8N_EDITOR_BASE_URL=https://${N8N_SUB}.${MAIN_DOMAIN}
      - WEBHOOK_URL=https://${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}
      - NODE_ENV=production
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
      - EXECUTIONS_MODE=queue
      - N8N_TRUST_PROXY=true
      - QUEUE_BULL_REDIS_HOST=redis-server
      - QUEUE_BULL_REDIS_DB=2
      - QUEUE_BULL_REDIS_PORT=6379
      - OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true
      - N8N_RUNNERS_ENABLED=true
      - N8N_SECURE_COOKIE=false
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
    volumes:
      - n8n_data:/home/node/.n8n
      - n8n_local-files:/files
    networks:
      - backend

  n8n_webhook:
    image: n8nio/n8n:latest
    restart: always
    user: root
    command: webhook
    environment:
      - N8N_ENCRYPTION_KEY=${GLOBAL_32_KEY}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=${GLOBAL_PASSWORD}
      - N8N_PROTOCOL=https
      - N8N_HOST=${N8N_SUB}.${MAIN_DOMAIN}
      - N8N_EDITOR_BASE_URL=https://${N8N_SUB}.${MAIN_DOMAIN}
      - WEBHOOK_URL=https://${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}
      - NODE_ENV=production
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
      - EXECUTIONS_MODE=queue
      - N8N_TRUST_PROXY=true
      - QUEUE_BULL_REDIS_HOST=redis-server
      - QUEUE_BULL_REDIS_DB=2
      - QUEUE_BULL_REDIS_PORT=6379
      - OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true
      - N8N_RUNNERS_ENABLED=true
      - N8N_SECURE_COOKIE=false
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.http.routers.n8n_webhook.rule=Host(`${N8N_WEBHOOK_SUB}.${MAIN_DOMAIN}`)
        - traefik.http.routers.n8n_webhook.service=n8n_webhook
        - traefik.http.routers.n8n_webhook.entrypoints=websecure
        - traefik.http.routers.n8n_webhook.tls.certresolver=le
        - traefik.http.routers.n8n_webhook.tls=true
        - traefik.http.services.n8n_webhook.loadbalancer.server.port=5678
    volumes:
      - n8n_data:/home/node/.n8n
      - n8n_local-files:/files
    networks:
      - frontend
      - backend

networks:
  frontend:
    external: true
  backend:
    external: true

volumes:
  n8n_db:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/n8n/db
      o: bind
  n8n_data:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/n8n/data
      o: bind
  n8n_local-files:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/n8n/local-files
      o: bind
