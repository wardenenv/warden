#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  warden backup --help || exit $? && exit $?
fi

### load connection information for the mysql service
DB_VOLUME="${WARDEN_ENV_NAME}_dbdata"
REDIS_VOLUME="${WARDEN_ENV_NAME}_redis"
ES_VOLUME="${WARDEN_ENV_NAME}_esdata"
CONTAINER_NAME="${WARDEN_ENV_NAME}_backup"
ENV_PHP_LOC="$(pwd)/app/etc/env.php"
AUTH_LOC="$(pwd)/auth.json"

"${WARDEN_DIR}/bin/warden" env down

if [ ! -d ".warden/" ]; then
  mkdir .warden/
fi

if [ ! -d ".warden/backups" ]; then
  mkdir .warden/backups/
fi

ID=$(date +%s)
BACKUP_LOC="$(pwd)/.warden/backups/$ID/"
mkdir $BACKUP_LOC

echo ""
echo ""
echo "------------------ STARTING BACKUP IN: $BACKUP_LOC (no output nor progress) ---------------------"
echo ""

case "${WARDEN_PARAMS[0]}" in
    db)

        docker run \
            --rm --name $CONTAINER_NAME \
            --mount source=$DB_VOLUME,target=/data -v \
            $BACKUP_LOC:/backup ubuntu bash \
            -c "tar -czvf /backup/db.tar.gz /data"


    ;;
    redis)

        docker run \
            --rm --name $CONTAINER_NAME \
            --mount source=$REDIS_VOLUME,target=/data -v \
            $BACKUP_LOC:/backup ubuntu bash \
            -c "tar -czvf /backup/redis.tar.gz /data"

    ;;
    elasticserach)

        docker run \
            --rm --name $CONTAINER_NAME \
            --mount source=$ES_VOLUME,target=/data -v \
            $BACKUP_LOC:/backup ubuntu bash \
            -c "tar -czvf /backup/es.tar.gz /data"

    ;;
    all)

        docker run \
            --rm --name $CONTAINER_NAME \
            --mount source=$DB_VOLUME,target=/data -v \
            $BACKUP_LOC:/backup ubuntu bash \
            -c "tar -czvf /backup/db.tar.gz /data"

        docker run \
            --rm --name $CONTAINER_NAME \
            --mount source=$REDIS_VOLUME,target=/data -v \
            $BACKUP_LOC:/backup ubuntu bash \
            -c "tar -czvf /backup/redis.tar.gz /data"

        docker run \
            --rm --name $CONTAINER_NAME \
            --mount source=$ES_VOLUME,target=/data -v \
            $BACKUP_LOC:/backup ubuntu bash \
            -c "tar -czvf /backup/es.tar.gz /data"

        if [ -f "$ENV_PHP_LOC" ]; then
          cp $ENV_PHP_LOC $BACKUP_LOC
        fi

        if [ -f "$AUTH_LOC" ]; then
          cp "$AUTH_LOC" $BACKUP_LOC
        fi

    ;;
    *)
        fatal "The command \"${WARDEN_PARAMS[0]}\" does not exist. Please use --help for usage."
        ;;
esac

tar -czvf "$(pwd)"/.warden/backups/latest.tar.gz $BACKUP_LOC

echo ""
echo ""
echo "------------------ FNISHED BACKUP WITH ID: $ID ---------------------"
echo ""
