version: '3.8'
services:
  rails:
    image: chatwoot/chatwoot:latest
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=${GLOBAL_32_KEY}
      - FRONTEND_URL=https://${CHATWOOT_SUB}.${MAIN_DOMAIN}
      - WEBSOCKET_URL=wss://${CHATWOOT_SUB}.${MAIN_DOMAIN}/cable
      - FORCE_SSL=true
      - ENABLE_ACCOUNT_SIGNUP=false
      - DEFAULT_LOCALE=
      - HELPCENTER_URL=
      - REDIS_URL=redis://redis-server:6379/4
      - REDIS_PASSWORD=
      - REDIS_SENTINELS=
      - REDIS_SENTINEL_MASTER_NAME=
      - REDIS_SENTINEL_PASSWORD=
      - REDIS_OPENSSL_VERIFY_MODE=
      - POSTGRES_DATABASE=chatwoot
      - POSTGRES_HOST=chatwoot-postgres
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=${GLOBAL_PASSWORD}
      - POSTGRES_STATEMENT_TIMEOUT=14s
      - RAILS_MAX_THREADS=5
      - MAILER_SENDER_EMAIL=Chatwoot <correo@corporativo>
      - SMTP_DOMAIN=dominio-del-servidor-smtp
      - SMTP_ADDRESS=mail.dominio.com
      - SMTP_PORT=587
      - SMTP_USERNAME=email-del-smtp
      - SMTP_PASSWORD=contraseña-smtp
      - SMTP_AUTHENTICATION=plain
      - SMTP_ENABLE_STARTTLS_AUTO=true
      - SMTP_OPENSSL_VERIFY_MODE=peer
      - SMTP_TLS=
      - SMTP_SSL=
      - ACTIVE_STORAGE_SERVICE=local
      - S3_BUCKET_NAME=
      - AWS_ACCESS_KEY_ID=
      - AWS_SECRET_ACCESS_KEY=
      - AWS_REGION=
      - S3_ACCESS_KEY=key-de-minio
      - S3_SECRET_KEY=secret-de-minio
      - S3_BUCKET=chatwoot
      - S3_ENDPOINT=subdominioapi.minio.com
      - DIRECT_UPLOADS_ENABLED=
      - RAILS_LOG_TO_STDOUT=true
      - LOG_LEVEL=info
      - LOG_SIZE=500
      - LOGRAGE_ENABLED=
      - FB_VERIFY_TOKEN=
      - FB_APP_SECRET=
      - FB_APP_ID=
      - IG_VERIFY_TOKEN=
      - TWITTER_APP_ID=
      - TWITTER_CONSUMER_KEY=
      - TWITTER_CONSUMER_SECRET=
      - TWITTER_ENVIRONMENT=
      - SLACK_CLIENT_ID=
      - SLACK_CLIENT_SECRET=
      - GOOGLE_OAUTH_CLIENT_ID=
      - GOOGLE_OAUTH_CLIENT_SECRET=
      - GOOGLE_OAUTH_CALLBACK_URL=
      - AZURE_APP_ID=
      - AZURE_APP_SECRET=
      - IOS_APP_ID=L7YLMN4634.com.chatwoot.app
      - ANDROID_BUNDLE_ID=com.chatwoot.app
      - ANDROID_SHA256_CERT_FINGERPRINT=AC:73:8E:DE:EB:56:EA:CC:10:87:02:A7:65:37:7B:38:D4:5D:D4:53:F8:3B:FB:D3:C6:28:64:1D:AA:08:1E:D8
      - VAPID_PUBLIC_KEY=
      - VAPID_PRIVATE_KEY=
      - FCM_SERVER_KEY=
      - ENABLE_RACK_ATTACK=true
      - RACK_ATTACK_LIMIT=300
      - ENABLE_RACK_ATTACK_WIDGET_API=true
      - SENTRY_DSN=
      - ELASTIC_APM_SERVER_URL=
      - ELASTIC_APM_SECRET_TOKEN=
      - SCOUT_KEY=
      - SCOUT_NAME=
      - SCOUT_MONITOR=
      - NEW_RELIC_LICENSE_KEY=
      - NEW_RELIC_APPLICATION_LOGGING_ENABLED=
      - DD_TRACE_AGENT_URL=
      - OPENAI_API_KEY=
      - REMOVE_STALE_CONTACT_INBOX_JOB_STATUS=false
      - IP_LOOKUP_API_KEY=
      - STRIPE_SECRET_KEY=
      - STRIPE_WEBHOOK_SECRET=
      - RAILS_INBOUND_EMAIL_SERVICE=
      - RAILS_INBOUND_EMAIL_PASSWORD=
      - MAILGUN_INGRESS_SIGNING_KEY=
      - MANDRILL_INGRESS_API_KEY=
      - MAILER_INBOUND_EMAIL_DOMAIN=correo-para recibir respuestas
      - ASSET_CDN_HOST=
      - CW_API_ONLY_SERVER=
      - ENABLE_PUSH_RELAY_SERVER=true
      - SIDEKIQ_CONCURRENCY=10
    volumes:
      - chatwoot_storage:/app/storage
    entrypoint: docker/entrypoints/rails.sh
    command: ['bundle','exec','rails','s','-p','3000','-b','0.0.0.0']
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.chatwoot.rule=Host(`${CHATWOOT_SUB}.${MAIN_DOMAIN}`)"
        - "traefik.http.routers.chatwoot.entrypoints=websecure"
        - "traefik.http.routers.chatwoot.tls=true"
        - "traefik.http.routers.chatwoot.tls.certresolver=le"
        - "traefik.http.services.chatwoot.loadbalancer.server.port=3000"
        - "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=https"
        - "traefik.http.routers.chatwoot.middlewares=sslheader"
    networks:
      - frontend
      - backend

  sidekiq:
    image: chatwoot/chatwoot:latest
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=${GLOBAL_32_KEY}
      - FRONTEND_URL=https://${CHATWOOT_SUB}.${MAIN_DOMAIN}
      - WEBSOCKET_URL=wss://${CHATWOOT_SUB}.${MAIN_DOMAIN}/cable
      - FORCE_SSL=true
      - ENABLE_ACCOUNT_SIGNUP=false
      - DEFAULT_LOCALE=
      - HELPCENTER_URL=
      - REDIS_URL=redis://redis-server:6379/4
      - POSTGRES_DATABASE=chatwoot
      - POSTGRES_HOST=chatwoot-postgres
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=${GLOBAL_PASSWORD}
      - POSTGRES_STATEMENT_TIMEOUT=14s
      - RAILS_MAX_THREADS=5
      - RAILS_LOG_TO_STDOUT=true
      - LOG_LEVEL=info
      - LOG_SIZE=500
      - LOGRAGE_ENABLED=
    volumes:
      - chatwoot_storage:/app/storage
    command: ['bundle','exec','sidekiq','-C','config/sidekiq.yml']
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    networks:
      - backend

  chatwoot-postgres:
    image: pgvector/pgvector:pg16
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${GLOBAL_PASSWORD}
    volumes:
      - chatwoot_postgres:/var/lib/postgresql/data
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    networks:
      - backend

networks:
  frontend:
    external: true
  backend:
    external: true

volumes:
  chatwoot_storage:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/chatwoot/chatwoot_storage
      o: bind
  chatwoot_postgres:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/chatwoot/postgres_data
      o: bind
