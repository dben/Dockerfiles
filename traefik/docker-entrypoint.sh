#!/bin/sh
set -e

# replace cluster definition
sed -i "s/CLUSTER_HOST/$CLUSTER_HOST/;s/ENVIRONMENT/$ENVIRONMENT/;s/AWS_REGION/$AWS_REGION/;s/DOMAIN/$DOMAIN/;s/EMAIL/$EMAIL/" /etc/traefik/traefik.toml

touch /shared/acme.json
chmod 600 /shared/acme.json

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- traefik "$@"
fi

# if our command is a valid Traefik subcommand, let's invoke it through Traefik instead
# (this allows for "docker run traefik version", etc)
if traefik "$1" --help 2>&1 >/dev/null | grep "help requested" /dev/null 2>&1; then
    set -- traefik "$@"
fi

exec "$@"
