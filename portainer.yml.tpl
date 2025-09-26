version: "3.7"
services:
  agent:
    image: portainer/agent:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - frontend
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]

  portainer:
    image: portainer/portainer-ce:latest
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - frontend
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.portainer.rule=Host(`${PORTAINER_SUB}.${MAIN_DOMAIN}`)"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"
        - "traefik.http.routers.portainer.tls.certresolver=le"
        - "traefik.http.routers.portainer.service=portainer"
        - "traefik.docker.network=frontend"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.priority=1"

networks:
  frontend:
    external: true

volumes:
  portainer_data:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/portainer/portainer_data
      o: bind
