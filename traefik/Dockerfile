FROM      traefik:v1.7-alpine

COPY      traefik_ecs.toml /etc/traefik/traefik.toml

COPY      docker-entrypoint.sh /docker-entrypoint.sh

RUN       mkdir /shared

VOLUME    /shared

ENTRYPOINT ["/docker-entrypoint.sh"]
