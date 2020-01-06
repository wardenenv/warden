#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

WARDEN_ENV_PATH="$(pwd)"

# TODO: If the .env file already exists; prompt user instead of overwriting
# TODO: Prompt user for inputs when arguments remain unspecified

WARDEN_ENV_NAME="${WARDEN_PARAMS[0]:-}"
WARDEN_ENV_TYPE="${WARDEN_PARAMS[1]:-magento2}"

# Require the user inputs the required environment name parameter
[[ ! ${WARDEN_ENV_NAME} ]] && >&2 echo -e "\033[31mMissing required argument. Please use --help to to print usage.\033[0m" && exit 1

# Verify the auto-select and/or type path resolves correctly before setting it
[[ ! -f "${WARDEN_DIR}/environments/${WARDEN_ENV_TYPE}.base.yml" ]] \
  && >&2 echo -e "\033[31mInvalid environment type \"${WARDEN_ENV_TYPE}\" specified.\033[0m" && exit 1

# Write the .env file to current working directory
cat > "${WARDEN_ENV_PATH}/.env" <<EOF
WARDEN_ENV_NAME=${WARDEN_ENV_NAME}
WARDEN_ENV_TYPE=${WARDEN_ENV_TYPE}
TRAEFIK_DOMAIN=${WARDEN_ENV_NAME}.test
TRAEFIK_SUBDOMAIN=app
EOF

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
