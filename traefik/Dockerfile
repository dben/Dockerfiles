FROM      traefik:v1.6-alpine

COPY      traefik_ecs.toml /etc/traefik/traefik.toml

COPY      docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
