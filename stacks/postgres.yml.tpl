version: '3.8'
services:
  postgres-server:
    image: postgres:latest
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${GLOBAL_PASSWORD}
      POSTGRES_DB: default_db
    deploy:
      mode: replicated
      replicas: 1
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    restart: unless-stopped

networks:
  backend:
    external: true

volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/postgres/postgres_data
      o: bind
