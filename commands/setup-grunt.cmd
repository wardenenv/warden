#!/bin/bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?
assertDockerRunning

## allow return codes from sub-process to bubble up normally
trap '' ERR

if [[ "${WARDEN_ENV_TYPE}" != "magento2" ]]; then
		error "This command is only working for Magento 2 projects" && exit 1
fi

echo "Confirming n98-magerun2 is installed..."
"${WARDEN_DIR}/bin/warden" magerun > /dev/null 2>&1

echo "Setup grunt files..."
DEFAULT_THEME_ID="select value from core_config_data where path = 'design/theme/theme_id'"
THEME_PATH="select theme_path from theme where theme_id in ($DEFAULT_THEME_ID);"
VENDOR_THEME=$("${WARDEN_DIR}/bin/warden" magerun db:query "$THEME_PATH" | sed -n 2p | cut -d$'\r' -f1)
THEME=$(echo "$VENDOR_THEME" | cut -d'/' -f2)
LOCALE_CODE=$("${WARDEN_DIR}/bin/warden" magento config:show general/locale/code | cut -d$'\r' -f1 | sed 's/ *$//g')
# Generate local-theme.js for custom theme
! read -r -d '' GEN_THEME_JS << EOM
var fs = require('fs');
var util = require('util');
var theme = require('./dev/tools/grunt/configs/themes');
theme['$THEME'] = {
    area: 'frontend',
    name: '$VENDOR_THEME',
    locale: '$LOCALE_CODE',
    files: [
        'css/styles-m',
        'css/styles-l'
    ],
    dsl: 'less'
};
fs.writeFileSync('./dev/tools/grunt/configs/local-themes.js', '"use strict"; module.exports = ' + util.inspect(theme), 'utf-8');
EOM

if [ -z "$VENDOR_THEME" ] || [ -z "$THEME" ]; then
    echo "Using Magento/luma theme for grunt config"
    THEME=luma
    "${WARDEN_DIR}/bin/warden" clinotty cp ./dev/tools/grunt/configs/themes.js ./dev/tools/grunt/configs/local-themes.js
else
    echo "Using $VENDOR_THEME theme for grunt config"
    "${WARDEN_DIR}/bin/warden" node -e "$GEN_THEME_JS"
fi

# Create files from sample files if they do not yet exist
test -f package.json || cp package.json.sample package.json
test -f Gruntfile.js || cp Gruntfile.js.sample Gruntfile.js
test -f grunt-config.json || cp grunt-config.json.sample grunt-config.json

# Disable grunt-contrib-jasmine on ARM processors (incompatible)
if [ "$(uname -m)" == "arm64" ]; then
    sed -i '' 's/"grunt-contrib-jasmine": "[~.0-9]*",//' package.json
fi

"${WARDEN_DIR}/bin/warden" npm install ajv@^5.0.0 --save
"${WARDEN_DIR}/bin/warden" npm install
"${WARDEN_DIR}/bin/warden" cache
"${WARDEN_DIR}/bin/warden" grunt clean
"${WARDEN_DIR}/bin/warden" grunt exec:$THEME
"${WARDEN_DIR}/bin/warden" grunt less:$THEME
