version: '3.8'
services:
  evolution-api:
    image: evoapicloud/evolution-api:latest
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: any
        delay: 5s
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.evolution-api.rule=Host(`${EVOAPI_SUB}.${MAIN_DOMAIN}`)"
        - "traefik.http.routers.evolution-api.entrypoints=websecure"
        - "traefik.http.routers.evolution-api.tls=true"
        - "traefik.http.routers.evolution-api.tls.certresolver=le"
        - "traefik.http.services.evolution-api.loadbalancer.server.port=8080"
        - "traefik.docker.network=frontend"
    networks:
      - frontend
      - backend
    volumes:
      - evolution_instances:/evolution/instances
    environment:
      - SUBDOMAIN=${EVOAPI_SUB}
      - DOMAIN=${MAIN_DOMAIN}
      - PASSWORD=${GLOBAL_PASSWORD}
      - SECRET_KEY=${GLOBAL_32_KEY}
      - SERVER_TYPE=http
      - SERVER_PORT=8080
      - SERVER_URL=https://${EVOAPI_SUB}.${MAIN_DOMAIN}
      - SENTRY_DSN=
      - CORS_ORIGIN=*
      - CORS_METHODS=GET,POST,PUT,DELETE
      - CORS_CREDENTIALS=true
      - LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG,VERBOSE,DARK,WEBHOOKS,WEBSOCKET
      - LOG_COLOR=true
      - LOG_BAILEYS=error
      - EVENT_EMITTER_MAX_LISTENERS=50
      - DEL_INSTANCE=false
      - DATABASE_PROVIDER=postgresql
      - DATABASE_CONNECTION_URI=postgresql://postgres:${GLOBAL_PASSWORD}@postgres-evoapi:5432/evolution2?schema=public
      - DATABASE_CONNECTION_CLIENT_NAME=evoapi
      - DATABASE_SAVE_DATA_INSTANCE=true
      - DATABASE_SAVE_DATA_NEW_MESSAGE=true
      - DATABASE_SAVE_MESSAGE_UPDATE=true
      - DATABASE_SAVE_DATA_CONTACTS=true
      - DATABASE_SAVE_DATA_CHATS=true
      - DATABASE_SAVE_DATA_LABELS=true
      - DATABASE_SAVE_DATA_HISTORIC=true
      - DATABASE_SAVE_IS_ON_WHATSAPP=true
      - DATABASE_SAVE_IS_ON_WHATSAPP_DAYS=7
      - DATABASE_DELETE_MESSAGE=true
      - RABBITMQ_ENABLED=true
      - RABBITMQ_URI=amqp://evo-rabbit:${GLOBAL_PASSWORD}@rabbitmq:5672/default
      - RABBITMQ_EXCHANGE_NAME=evolution
      - RABBITMQ_ERLANG_COOKIE=${GLOBAL_PASSWORD}
      - RABBITMQ_DEFAULT_VHOST=default
      - RABBITMQ_DEFAULT_USER=evo-rabbit
      - RABBITMQ_DEFAULT_PASS=${GLOBAL_PASSWORD}
      - RABBITMQ_GLOBAL_ENABLED=false
      - RABBITMQ_EVENTS_APPLICATION_STARTUP=false
      - RABBITMQ_EVENTS_INSTANCE_CREATE=false
      - RABBITMQ_EVENTS_INSTANCE_DELETE=false
      - RABBITMQ_EVENTS_QRCODE_UPDATED=false
      - RABBITMQ_EVENTS_MESSAGES_SET=false
      - RABBITMQ_EVENTS_MESSAGES_UPSERT=false
      - RABBITMQ_EVENTS_MESSAGES_EDITED=false
      - RABBITMQ_EVENTS_MESSAGES_UPDATE=false
      - RABBITMQ_EVENTS_MESSAGES_DELETE=false
      - RABBITMQ_EVENTS_SEND_MESSAGE=false
      - RABBITMQ_EVENTS_CONTACTS_SET=false
      - RABBITMQ_EVENTS_CONTACTS_UPSERT=false
      - RABBITMQ_EVENTS_CONTACTS_UPDATE=false
      - RABBITMQ_EVENTS_PRESENCE_UPDATE=false
      - RABBITMQ_EVENTS_CHATS_SET=false
      - RABBITMQ_EVENTS_CHATS_UPSERT=false
      - RABBITMQ_EVENTS_CHATS_UPDATE=false
      - RABBITMQ_EVENTS_CHATS_DELETE=false
      - RABBITMQ_EVENTS_GROUPS_UPSERT=false
      - RABBITMQ_EVENTS_GROUP_UPDATE=false
      - RABBITMQ_EVENTS_GROUP_PARTICIPANTS_UPDATE=false
      - RABBITMQ_EVENTS_CONNECTION_UPDATE=false
      - RABBITMQ_EVENTS_REMOVE_INSTANCE=false
      - RABBITMQ_EVENTS_LOGOUT_INSTANCE=false
      - RABBITMQ_EVENTS_CALL=false
      - RABBITMQ_EVENTS_TYPEBOT_START=false
      - RABBITMQ_EVENTS_TYPEBOT_CHANGE_STATUS=false
      - SQS_ENABLED=false
      - SQS_ACCESS_KEY_ID=
      - SQS_SECRET_ACCESS_KEY=
      - SQS_ACCOUNT_ID=
      - SQS_REGION=
      - WEBSOCKET_ENABLED=false
      - WEBSOCKET_GLOBAL_EVENTS=false
      - PUSHER_ENABLED=false
      - PUSHER_GLOBAL_ENABLED=false
      - PUSHER_GLOBAL_APP_ID=
      - PUSHER_GLOBAL_KEY=
      - PUSHER_GLOBAL_SECRET=
      - PUSHER_GLOBAL_CLUSTER=
      - PUSHER_GLOBAL_USE_TLS=true
      - PUSHER_EVENTS_APPLICATION_STARTUP=true
      - PUSHER_EVENTS_QRCODE_UPDATED=true
      - PUSHER_EVENTS_MESSAGES_SET=true
      - PUSHER_EVENTS_MESSAGES_UPSERT=true
      - PUSHER_EVENTS_MESSAGES_EDITED=true
      - PUSHER_EVENTS_MESSAGES_UPDATE=true
      - PUSHER_EVENTS_MESSAGES_DELETE=true
      - PUSHER_EVENTS_SEND_MESSAGE=true
      - PUSHER_EVENTS_CONTACTS_SET=true
      - PUSHER_EVENTS_CONTACTS_UPSERT=true
      - PUSHER_EVENTS_CONTACTS_UPDATE=true
      - PUSHER_EVENTS_PRESENCE_UPDATE=true
      - PUSHER_EVENTS_CHATS_SET=true
      - PUSHER_EVENTS_CHATS_UPSERT=true
      - PUSHER_EVENTS_CHATS_UPDATE=true
      - PUSHER_EVENTS_CHATS_DELETE=true
      - PUSHER_EVENTS_GROUPS_UPSERT=true
      - PUSHER_EVENTS_GROUPS_UPDATE=true
      - PUSHER_EVENTS_GROUP_PARTICIPANTS_UPDATE=true
      - PUSHER_EVENTS_CONNECTION_UPDATE=true
      - PUSHER_EVENTS_LABELS_EDIT=true
      - PUSHER_EVENTS_LABELS_ASSOCIATION=true
      - PUSHER_EVENTS_CALL=true
      - PUSHER_EVENTS_TYPEBOT_START=false
      - PUSHER_EVENTS_TYPEBOT_CHANGE_STATUS=false
      - WA_BUSINESS_TOKEN_WEBHOOK=evolution
      - WA_BUSINESS_URL=https://graph.facebook.com
      - WA_BUSINESS_VERSION=v23.0
      - WA_BUSINESS_LANGUAGE=en_US
      - WEBHOOK_GLOBAL_ENABLED=false
      - WEBHOOK_GLOBAL_URL=''
      - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false
      - WEBHOOK_EVENTS_APPLICATION_STARTUP=false
      - WEBHOOK_EVENTS_QRCODE_UPDATED=true
      - WEBHOOK_EVENTS_MESSAGES_SET=true
      - WEBHOOK_EVENTS_MESSAGES_UPSERT=true
      - WEBHOOK_EVENTS_MESSAGES_EDITED=true
      - WEBHOOK_EVENTS_MESSAGES_UPDATE=true
      - WEBHOOK_EVENTS_MESSAGES_DELETE=true
      - WEBHOOK_EVENTS_SEND_MESSAGE=true
      - WEBHOOK_EVENTS_CONTACTS_SET=true
      - WEBHOOK_EVENTS_CONTACTS_UPSERT=true
      - WEBHOOK_EVENTS_CONTACTS_UPDATE=true
      - WEBHOOK_EVENTS_PRESENCE_UPDATE=true
      - WEBHOOK_EVENTS_CHATS_SET=true
      - WEBHOOK_EVENTS_CHATS_UPSERT=true
      - WEBHOOK_EVENTS_CHATS_UPDATE=true
      - WEBHOOK_EVENTS_CHATS_DELETE=true
      - WEBHOOK_EVENTS_GROUPS_UPSERT=true
      - WEBHOOK_EVENTS_GROUPS_UPDATE=true
      - WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE=true
      - WEBHOOK_EVENTS_CONNECTION_UPDATE=true
      - WEBHOOK_EVENTS_REMOVE_INSTANCE=false
      - WEBHOOK_EVENTS_LOGOUT_INSTANCE=false
      - WEBHOOK_EVENTS_LABELS_EDIT=true
      - WEBHOOK_EVENTS_LABELS_ASSOCIATION=true
      - WEBHOOK_EVENTS_CALL=true
      - WEBHOOK_EVENTS_TYPEBOT_START=false
      - WEBHOOK_EVENTS_TYPEBOT_CHANGE_STATUS=false
      - WEBHOOK_EVENTS_ERRORS=false
      - WEBHOOK_EVENTS_ERRORS_WEBHOOK=
      - CONFIG_SESSION_PHONE_CLIENT=Evolution API
      - CONFIG_SESSION_PHONE_NAME=Chrome
      - CONFIG_SESSION_PHONE_VERSION=2.3000.1023204200
      - QRCODE_LIMIT=30
      - QRCODE_COLOR='#175197'
      - TYPEBOT_ENABLED=true
      - TYPEBOT_API_VERSION=latest
      - CHATWOOT_ENABLED=true
      - CHATWOOT_MESSAGE_READ=true
      - CHATWOOT_MESSAGE_DELETE=true
      - CHATWOOT_BOT_CONTACT=true
      - CHATWOOT_IMPORT_DATABASE_CONNECTION_URI=postgresql://postgres:${GLOBAL_PASSWORD}@chatwoot-postgres:5432/chatwoot?sslmode=disable
      - CHATWOOT_IMPORT_PLACEHOLDER_MEDIA_MESSAGE=true
      - OPENAI_ENABLED=false
      - DIFY_ENABLED=false
      - CACHE_REDIS_ENABLED=true
      - CACHE_REDIS_URI=redis://redis-server:6379/3
      - CACHE_REDIS_TTL=604800
      - CACHE_REDIS_PREFIX_KEY=evolution
      - CACHE_REDIS_SAVE_INSTANCES=false
      - CACHE_LOCAL_ENABLED=false
      - S3_ENABLED=false
      - S3_ACCESS_KEY=
      - S3_SECRET_KEY=
      - S3_BUCKET=evolution
      - S3_PORT=443
      - S3_ENDPOINT=s3.domain.com
      - S3_REGION=eu-west-3
      - S3_USE_SSL=true
      - AUTHENTICATION_API_KEY=${GLOBAL_32_KEY}
      - AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
      - LANGUAGE=es

  postgres-evoapi:
    image: postgres:15
    networks:
      - backend
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: any
        delay: 5s
    environment:
      - POSTGRES_DB=evolution2
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${GLOBAL_PASSWORD}
    volumes:
      - evolution_postgres_data:/var/lib/postgresql/data

  rabbitmq:
    image: rabbitmq:management
    entrypoint: docker-entrypoint.sh
    command: rabbitmq-server
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: any
        delay: 5s
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.rabbitmq.rule=Host(`${RABBITMQ_EVOAPI_SUB}.${MAIN_DOMAIN}`)"
        - "traefik.http.routers.rabbitmq.entrypoints=websecure"
        - "traefik.http.routers.rabbitmq.tls=true"
        - "traefik.http.routers.rabbitmq.tls.certresolver=le"
        - "traefik.http.services.rabbitmq.loadbalancer.server.port=15672"
        - "traefik.docker.network=frontend"
    networks:
      - frontend
      - backend
    volumes:
      - evolution_rabbitmq_data:/var/lib/rabbitmq/
    environment:
      - RABBITMQ_ERLANG_COOKIE=${GLOBAL_PASSWORD}
      - RABBITMQ_DEFAULT_VHOST=default
      - RABBITMQ_DEFAULT_USER=evo-rabbit
      - RABBITMQ_DEFAULT_PASS=${GLOBAL_PASSWORD}

networks:
  frontend:
    external: true
  backend:
    external: true

volumes:
  evolution_instances:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/evoapi/evolution_instances
      o: bind
  evolution_postgres_data:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/evoapi/evolution_postgres_data
      o: bind
  evolution_rabbitmq_data:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/evoapi/rabbitmq_data
      o: bind
