#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/env.sh"
WARDEN_ENV_PATH="$(pwd -P)"

# TODO: If the .env file already exists; prompt user instead of overwriting
# TODO: Prompt user for inputs when arguments remain unspecified

WARDEN_ENV_NAME="${WARDEN_PARAMS[0]:-}"
WARDEN_ENV_TYPE="${WARDEN_PARAMS[1]:-}"

# Require the user inputs the required environment name parameter
[[ ! ${WARDEN_ENV_NAME} ]] && >&2 echo -e "\033[31mMissing required argument. Please use --help to to print usage.\033[0m" && exit 1

# Verify the auto-select and/or type path resolves correctly before setting it
assertValidEnvType || exit $?

# Write the .env file to current working directory
cat > "${WARDEN_ENV_PATH}/.env" <<EOF
WARDEN_ENV_NAME=${WARDEN_ENV_NAME}
WARDEN_ENV_TYPE=${WARDEN_ENV_TYPE}
WARDEN_WEB_ROOT=/

TRAEFIK_DOMAIN=${WARDEN_ENV_NAME}.test
TRAEFIK_SUBDOMAIN=app
EOF

if [[ "${WARDEN_ENV_TYPE}" == "magento1" ]]; then
  cat >> "${WARDEN_ENV_PATH}/.env" <<-EOT

		WARDEN_DB=1
		WARDEN_REDIS=1
		WARDEN_MAILHOG=1

		MARIADB_VERSION=10.3
		NODE_VERSION=10
		PHP_VERSION=7.2
		REDIS_VERSION=5.0

		WARDEN_SELENIUM=0
		WARDEN_SELENIUM_DEBUG=0
		WARDEN_BLACKFIRE=0

		BLACKFIRE_CLIENT_ID=
		BLACKFIRE_CLIENT_TOKEN=
		BLACKFIRE_SERVER_ID=
		BLACKFIRE_SERVER_TOKEN=
	EOT
fi

if [[ "${WARDEN_ENV_TYPE}" == "magento2" ]]; then
  cat >> "${WARDEN_ENV_PATH}/.env" <<-EOT

		WARDEN_DB=1
		WARDEN_ELASTICSEARCH=1
		WARDEN_VARNISH=1
		WARDEN_RABBITMQ=1
		WARDEN_REDIS=1
		WARDEN_MAILHOG=1

		ELASTICSEARCH_VERSION=6.8
		MARIADB_VERSION=10.3
		NODE_VERSION=10
		PHP_VERSION=7.3
		RABBITMQ_VERSION=3.7
		REDIS_VERSION=5.0
		VARNISH_VERSION=6.0

		WARDEN_SYNC_IGNORE=

		WARDEN_ALLURE=0
		WARDEN_SELENIUM=0
		WARDEN_SELENIUM_DEBUG=0
		WARDEN_BLACKFIRE=0
		WARDEN_SPLIT_SALES=0
		WARDEN_SPLIT_CHECKOUT=0
		WARDEN_TEST_DB=0

		BLACKFIRE_CLIENT_ID=
		BLACKFIRE_CLIENT_TOKEN=
		BLACKFIRE_SERVER_ID=
		BLACKFIRE_SERVER_TOKEN=
	EOT
fi

if [[ "${WARDEN_ENV_TYPE}" == "laravel" ]]; then
  cat >> "${WARDEN_ENV_PATH}/.env" <<-EOT

		MARIADB_VERSION=10.3
		NODE_VERSION=10
		PHP_VERSION=7.2
		REDIS_VERSION=5.0

		WARDEN_DB=1
		WARDEN_REDIS=1
		WARDEN_MAILHOG=1

		## Laravel Config
		APP_URL=http://app.${WARDEN_ENV_NAME}.test
		APP_KEY=base64:$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64)

		APP_ENV=local
		APP_DEBUG=true

		DB_CONNECTION=mysql
		DB_HOST=db
		DB_PORT=3306
		DB_DATABASE=laravel
		DB_USERNAME=laravel
		DB_PASSWORD=laravel

		CACHE_DRIVER=redis
		SESSION_DRIVER=redis
		
		REDIS_HOST=redis
		REDIS_PORT=6379
		
		MAIL_DRIVER=sendmail
	EOT
fi

if [[ "${WARDEN_ENV_TYPE}" == "symfony" ]]; then
  cat >> "${WARDEN_ENV_PATH}/.env" <<-EOT

		MARIADB_VERSION=10.3
		NODE_VERSION=10
		PHP_VERSION=7.4
		RABBITMQ_VERSION=3.7
		REDIS_VERSION=5.0
		VARNISH_VERSION=6.0

		WARDEN_MARIADB=1
		WARDEN_REDIS=1
		WARDEN_MAILHOG=1
		WARDEN_RABBITMQ=1
		WARDEN_ELASTICSEARCH=0
		WARDEN_VARNISH=0
	EOT
fi
