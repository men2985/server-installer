version: '3.7'
services:
  redis-server:
    image: redis:latest
    command: redis-server --loglevel warning
    deploy:
      replicas: 1
      restart_policy:
        condition: any
    volumes:
      - redis_cache:/data
    networks:
      - backend

  redisinsight:
    image: redislabs/redisinsight:latest
    deploy:
      mode: replicated
      replicas: 1
      labels:
       - "traefik.enable=true"
       - "traefik.http.routers.redisinsight.rule=Host(`${REDISINSIGHT_SUB}.${MAIN_DOMAIN}`)"
       - "traefik.http.routers.redisinsight.service=redisinsight"
       - "traefik.http.routers.redisinsight.entrypoints=websecure"
       - "traefik.http.routers.redisinsight.tls.certresolver=le"
       - "traefik.http.routers.redisinsight.tls=true"
       - "traefik.http.services.redisinsight.loadbalancer.server.port=5540"
    volumes:
      - redisinsight:/data
    networks:
      - backend
      - frontend

networks:
  backend:
    external: true
  frontend:
    external: true

volumes:
  redis_cache:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/redis/redis_cache
      o: bind
  redisinsight:
    driver: local
    driver_opts:
      type: none
      device: /home/docker/redis/redisinsight
      o: bind
