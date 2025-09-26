version: '3.8'
services:
  traefik:
    image: traefik:latest
    restart: unless-stopped
    command:
      - "--log.level=DEBUG"
      - "--api=true"
      - "--api.dashboard=true"
      - "--providers.swarm.endpoint=unix:///var/run/docker.sock"
      - "--providers.swarm.exposedbydefault=false"
      - "--providers.swarm.network=frontend"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.websecure.transport.respondingTimeouts.idleTimeout=3600"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--certificatesresolvers.le.acme.httpchallenge=true"
      - "--certificatesresolvers.le.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.le.acme.email=${LETSENCRYPT_EMAIL}"
      - "--certificatesresolvers.le.acme.storage=/letsencrypt/acme.json"
    ports:
      - 80:80
      - 443:443
    networks:
      - frontend
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_letsencrypt:/letsencrypt
    deploy:
      mode: global
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.http.routers.traefik.rule=Host(`${TRAEFIK_SUB}.${MAIN_DOMAIN}`)
        - traefik.http.routers.traefik.entrypoints=websecure
        - traefik.http.routers.traefik.tls.certresolver=le
        - traefik.http.routers.traefik.service=api@internal
        - traefik.http.routers.traefik.middlewares=auth
        - traefik.http.middlewares.auth.basicauth.users=admin:$$2y$$05$$4ouF.ij352o2TL6c5Aj0j.KJqwvNDI4omfB/MAI3O8oX95C26kELq
        - "traefik.http.services.dummy-svc.loadbalancer.server.port=9999"

networks:
  frontend:
    external: true

volumes:
  traefik_letsencrypt:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/traefik/letsencrypt
      o: bind
