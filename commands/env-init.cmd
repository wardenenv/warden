#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

WARDEN_ENV_PATH="$(pwd)"

# TODO: If the .env file already exists; prompt user instead of overwriting
# TODO: Prompt user for inputs when arguments remain unspecified

WARDEN_ENV_NAME="${WARDEN_PARAMS[0]:-}"
WARDEN_ENV_TYPE="${WARDEN_PARAMS[1]:-}"

# Require the user inputs the required environment name parameter
[[ ! ${WARDEN_ENV_NAME} ]] && >&2 echo -e "\033[31mMissing required argument. Please use --help to to print usage.\033[0m" && exit 1

# Verify the auto-select and/or type path resolves correctly before setting it
[[ ! -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.base.yml" ]] && [[ ! -f "${WARDEN_DIR}/custom_environments/${WARDEN_ENV_TYPE}.yml" ]] \
  && >&2 echo -e "\033[31mInvalid environment type \"${WARDEN_ENV_TYPE}\" specified.\033[0m" && exit 1

# Write the .env file to current working directory
cat > "${WARDEN_ENV_PATH}/.env" <<EOF
WARDEN_ENV_NAME=${WARDEN_ENV_NAME}
WARDEN_ENV_TYPE=${WARDEN_ENV_TYPE}
TRAEFIK_DOMAIN=${WARDEN_ENV_NAME}.test
TRAEFIK_SUBDOMAIN=app
EOF

if [[ "${WARDEN_ENV_TYPE}" == "magento1" ]]; then
  cat >> "${WARDEN_ENV_PATH}/.env" <<-EOT

		MARIADB_VERSION=10.3
		NODE_VERSION=10
		PHP_VERSION=7.2
		REDIS_VERSION=5.0

		WARDEN_SELENIUM=0
		WARDEN_BLACKFIRE=0

		BLACKFIRE_CLIENT_ID=<client_id>
		BLACKFIRE_CLIENT_TOKEN=<client_token>
		BLACKFIRE_SERVER_ID=<server_id>
		BLACKFIRE_SERVER_TOKEN=<server_token>
	EOT
fi

if [[ "${WARDEN_ENV_TYPE}" == "magento2" ]]; then
  cat >> "${WARDEN_ENV_PATH}/.env" <<-EOT

		BYPASS_VARNISH=false

		ELASTICSEARCH_VERSION=5.6
		MARIADB_VERSION=10.3
		NODE_VERSION=10
		PHP_VERSION=7.2
		RABBITMQ_VERSION=3.7.14
		REDIS_VERSION=5.0
		VARNISH_VERSION=4.1

		WARDEN_SELENIUM=0
		WARDEN_BLACKFIRE=0
		WARDEN_SPLIT_SALES=0
		WARDEN_SPLIT_CHECKOUT=0

		BLACKFIRE_CLIENT_ID=<client_id>
		BLACKFIRE_CLIENT_TOKEN=<client_token>
		BLACKFIRE_SERVER_ID=<server_id>
		BLACKFIRE_SERVER_TOKEN=<server_token>
	EOT
fi

if [[ "${WARDEN_ENV_TYPE}" == "laravel" ]]; then
  cat >> "${WARDEN_ENV_PATH}/.env" <<-EOT

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
