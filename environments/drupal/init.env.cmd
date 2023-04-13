# If Drupal directories exist, make sure the minimum user-content upload directories exist
if [[ -d "${WARDEN_ENV_PATH}/web/sites/default" ]] && [[ ! -d "${WARDEN_ENV_PATH}/web/sites/default/files" ]]
then
	echo -e "\033[1;33m[!] \033[0mCreating missing user-content directory: \"\033[36m${WARDEN_ENV_PATH}/web/sites/default/files\033[0m\"."
	mkdir -p "${WARDEN_ENV_PATH}/web/sites/default/files"
fi

if [[ ! -d "${WARDEN_ENV_PATH}/web/sites/default/private" ]]; then
	echo -e "\033[1;33m[!] \033[0mCreating missing private user-content directory: \"\033[36m${WARDEN_ENV_PATH}/web/sites/default/private\033[0m\"."
	mkdir -p "${WARDEN_ENV_PATH}/web/sites/default/private"
	cat > "${WARDEN_ENV_PATH}/web/sites/default/private/.htaccess" <<-EOT
		# Drupal SA-CORE-2013-003
		# This file attempts to provide defense in depth to Apache servers. See
		# https://www.drupal.org/forum/newsletters/security-advisories-for-drupal-core/2013-11-20/sa-core-2013-003-drupal-core

		# Turn off all options we don't need.
		Options None
		Options +FollowSymLinks

		# Set the catch-all handler to prevent scripts from being executed.
		SetHandler Drupal_Security_Do_Not_Remove_See_SA_2006_006
		<Files *>
		# Override the handler again if we're run later in the evaluation list.
		SetHandler Drupal_Security_Do_Not_Remove_See_SA_2013_003
		</Files>

		# If we know how to do it safely, disable the PHP engine entirely.
		<IfModule mod_php5.c>
		php_flag engine off
		</IfModule>

		Deny from all
	EOT
fi
