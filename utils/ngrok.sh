#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

function replaceDots() {
    local input_string="$1"
    local output_string="${input_string//./\\.}"
    echo "$output_string"
}

function displayNgrokUrls() {
    # Sample text input
    local text=$($WARDEN_DIR/bin/warden env logs ngrok | grep name=)

    # Extract name and url using grep and awk
    local names=$(echo "$text" | grep -o 'name=[^ ]*' | awk -F'=' '{print $2}')
    local urls=$(echo "$text" | grep -o 'url=[^ ]*' | awk -F'=https://' '{print $2}')

    local names=($(echo "${names[@]}" | tr '\n' ' '))
    local urls=($(echo "${urls[@]}" | tr '\n' ' '))

    # Check if the number of names and urls match
    if [[ ${#names[@]} -ne ${#urls[@]} ]]; then
        echo "Error: The number of names and URLs doesn't match!"
        exit 1
    fi

    # Return only unique urls, latest values in logs are replacing oldest values
    declare -A unique_urls
    for ((i = 0; i < ${#names[@]}; i++)); do
        unique_urls[${names[i]}]=${urls[i]}
    done

    for name in "${!unique_urls[@]}"; do
        echo "Use url: https://${name} for https://${unique_urls[$name]}"
    done
}

function generateCaddyConfigurationFile() {
    local target_file="$1"
    local target_service="$2"
    local target_port="$3"

    # Sample text input
    local text=$($WARDEN_DIR/bin/warden env logs ngrok | grep name=)

    # Extract name and url using grep and awk
    local names=$(echo "$text" | grep -o 'name=[^ ]*' | awk -F'=' '{print $2}')
    local urls=$(echo "$text" | grep -o 'url=[^ ]*' | awk -F'=https://' '{print $2}')

    local names=($(echo "${names[@]}" | tr '\n' ' '))
    local urls=($(echo "${urls[@]}" | tr '\n' ' '))

    # Check if the number of names and urls match
    if [[ ${#names[@]} -ne ${#urls[@]} ]]; then
        echo "Error: The number of names and URLs doesn't match!"
        exit 1
    fi

    # Return only unique urls, latest values in logs are replacing oldest values
     declare -A unique_urls
     for ((i = 0; i < ${#names[@]}; i++)); do
         unique_urls[${names[i]}]=${urls[i]}
     done

    echo "{
   order replace after encode
}
:2080 {
    @get {
        method GET
        path /*
    }
    handle @get {
        replace {" > $target_file;

    # Loop through the urls to get before and after replacement
    for name in "${!unique_urls[@]}"; do
      echo "            ${name} ${unique_urls[$name]}" >> $target_file;
    done

    echo "        }
    }

    reverse_proxy $target_service:$target_port {
        header_up Accept-Encoding identity
        header_up X-Forwarded-Proto https" >> $target_file;

    # Loop through the arrays and map the headers to be replaced
    for name in "${!unique_urls[@]}"; do
    echo "        header_up * $(replaceDots ${unique_urls[$name]})  ${name}
        header_down * $(replaceDots  ${name}) ${unique_urls[$name]}" >> $target_file;
    done

    echo "    }
}" >> $target_file;
}

function generateNgrokConfigurationFile() {
  local target_file="$1"
  local domains="${@:2}"
echo 'version: "2"
log: stdout
tunnels:'> $target_file;
for domain in $domains ; do
echo '    '${domain}':
       proto: "http"
       addr: "caddy-ngrok:2080"' >> $target_file;
done
}