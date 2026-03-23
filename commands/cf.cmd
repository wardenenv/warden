#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1

source "${WARDEN_DIR}/utils/install.sh"
assertDockerRunning

CLOUDFLARED_DIR="${WARDEN_HOME_DIR}/etc/cloudflared"

## load image repository from global config
if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
    eval "$(grep "^WARDEN_IMAGE_REPOSITORY" "${WARDEN_HOME_DIR}/.env")"
fi
CLOUDFLARED_IMAGE="${WARDEN_IMAGE_REPOSITORY:-docker.io/wardenenv}/cloudflared:latest"

if (( ${#WARDEN_PARAMS[@]} == 0 )) || [[ "${WARDEN_PARAMS[0]}" == "help" ]]; then
  $WARDEN_BIN cf --help || exit $? && exit $?
fi

## allow return codes from sub-process to bubble up normally
trap '' ERR

case "${WARDEN_PARAMS[0]}" in
    login)
        mkdir -p "${CLOUDFLARED_DIR}"
        echo "Opening browser for Cloudflare authentication..."
        docker run --rm -it \
            -v "${CLOUDFLARED_DIR}:/home/nonroot/.cloudflared" \
            "${CLOUDFLARED_IMAGE}" \
            tunnel login
        if [[ -f "${CLOUDFLARED_DIR}/cert.pem" ]]; then
            echo "Login successful. cert.pem saved to ${CLOUDFLARED_DIR}/"
            echo "Next step: run 'warden cf create' to create a tunnel."
        else
            error "Login failed. No cert.pem found."
            exit 1
        fi
        ;;
    create)
        if [[ ! -f "${CLOUDFLARED_DIR}/cert.pem" ]]; then
            fatal "Not authenticated. Run 'warden cf login' first."
        fi

        TUNNEL_NAME="${WARDEN_PARAMS[1]:-warden}"
        echo "Creating tunnel '${TUNNEL_NAME}'..."

        CREATE_OUTPUT=$(docker run --rm \
            -v "${CLOUDFLARED_DIR}:/home/nonroot/.cloudflared" \
            "${CLOUDFLARED_IMAGE}" \
            tunnel create "${TUNNEL_NAME}" 2>&1)

        echo "${CREATE_OUTPUT}"

        ## extract tunnel UUID from output (format: "Created tunnel <name> with id <uuid>")
        ## UUID is [0-9a-f-] only, which is safe for use in sed substitution below
        TUNNEL_ID=$(echo "${CREATE_OUTPUT}" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)

        if [[ -z "${TUNNEL_ID}" ]]; then
            fatal "Failed to extract tunnel ID from output."
        fi

        ## write tunnel ID to global config
        if [[ -f "${WARDEN_HOME_DIR}/.env" ]] && grep -q "^WARDEN_CLOUDFLARED_TUNNEL_ID" "${WARDEN_HOME_DIR}/.env"; then
            sed -i.bak "s/^WARDEN_CLOUDFLARED_TUNNEL_ID=.*/WARDEN_CLOUDFLARED_TUNNEL_ID=${TUNNEL_ID}/" "${WARDEN_HOME_DIR}/.env"
            rm -f "${WARDEN_HOME_DIR}/.env.bak"
        else
            echo "WARDEN_CLOUDFLARED_TUNNEL_ID=${TUNNEL_ID}" >> "${WARDEN_HOME_DIR}/.env"
        fi

        ## generate initial config (reads TUNNEL_ID from ~/.warden/.env written above)
        regenerateCloudflaredConfig

        echo ""
        echo "Tunnel '${TUNNEL_NAME}' created with ID: ${TUNNEL_ID}"
        echo "Run 'warden svc up' to start the tunnel."
        ;;
    delete)
        if [[ ! -f "${CLOUDFLARED_DIR}/cert.pem" ]]; then
            fatal "Not authenticated. Run 'warden cf login' first."
        fi

        if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
            eval "$(grep "^WARDEN_CLOUDFLARED_TUNNEL_ID" "${WARDEN_HOME_DIR}/.env" | tr -d '\r')"
        fi

        if [[ -z "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
            fatal "No tunnel configured. Nothing to delete."
        fi

        echo "Deleting tunnel ${WARDEN_CLOUDFLARED_TUNNEL_ID}..."

        ## stop cloudflared container first if running
        docker stop cloudflared 2>/dev/null || true

        docker run --rm \
            -v "${CLOUDFLARED_DIR}:/home/nonroot/.cloudflared" \
            "${CLOUDFLARED_IMAGE}" \
            tunnel delete "${WARDEN_CLOUDFLARED_TUNNEL_ID}" || true

        ## remove tunnel ID from global config
        if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
            sed -i.bak '/^WARDEN_CLOUDFLARED_TUNNEL_ID/d' "${WARDEN_HOME_DIR}/.env"
            rm -f "${WARDEN_HOME_DIR}/.env.bak"
        fi

        ## remove credentials (but keep cert.pem for future tunnel creation)
        rm -f "${CLOUDFLARED_DIR}/${WARDEN_CLOUDFLARED_TUNNEL_ID}.json"
        rm -f "${CLOUDFLARED_DIR}/credentials.json"
        rm -f "${CLOUDFLARED_DIR}/config.yml"

        echo "Tunnel deleted. cert.pem preserved for future use."
        ;;
    status)
        echo ""
        ## show tunnel ID
        if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
            eval "$(grep "^WARDEN_CLOUDFLARED_TUNNEL_ID" "${WARDEN_HOME_DIR}/.env" | tr -d '\r')"
        fi

        if [[ -n "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
            echo "Tunnel ID: ${WARDEN_CLOUDFLARED_TUNNEL_ID}"
        else
            echo "Tunnel ID: (not configured)"
        fi

        ## show container status
        CONTAINER_STATUS=$(docker inspect --format '{{.State.Status}}' cloudflared 2>/dev/null || echo "not running")
        echo "Container:  ${CONTAINER_STATUS}"

        ## show connected domains
        echo ""
        echo "Connected domains:"
        DOMAINS=$(docker ps --filter "label=dev.warden.cf.domain" --format '  {{.Label "dev.warden.cf.domain"}} ({{.Names}})' 2>/dev/null)
        if [[ -n "${DOMAINS}" ]]; then
            echo "${DOMAINS}"
        else
            echo "  (none)"
        fi
        echo ""
        ;;
    update)
        if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
            eval "$(grep "^WARDEN_CLOUDFLARED_TUNNEL_ID" "${WARDEN_HOME_DIR}/.env" | tr -d '\r')"
        fi

        if [[ -z "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
            fatal "No tunnel configured. Run 'warden cf create' first."
        fi

        regenerateCloudflaredConfig
        echo "Cloudflared configuration regenerated and container restarted."
        ;;
    logout)
        ## check if tunnel exists and warn user to delete it first
        if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
            eval "$(grep "^WARDEN_CLOUDFLARED_TUNNEL_ID" "${WARDEN_HOME_DIR}/.env" | tr -d '\r')"
        fi
        if [[ -n "${WARDEN_CLOUDFLARED_TUNNEL_ID:-}" ]]; then
            warning "A tunnel is still configured (ID: ${WARDEN_CLOUDFLARED_TUNNEL_ID})."
            warning "Run 'warden cf delete' first to remove it from Cloudflare,"
            warning "or the tunnel will become orphaned."
            echo ""
            read -p "Continue with logout anyway? [y/N] " confirm
            [[ "${confirm}" != [yY]* ]] && exit 0
        fi

        echo "Cleaning up cloudflared configuration..."

        ## stop container if running
        docker stop cloudflared 2>/dev/null || true

        ## remove tunnel ID from global config
        if [[ -f "${WARDEN_HOME_DIR}/.env" ]]; then
            sed -i.bak '/^WARDEN_CLOUDFLARED_TUNNEL_ID/d' "${WARDEN_HOME_DIR}/.env"
            rm -f "${WARDEN_HOME_DIR}/.env.bak"
        fi

        ## remove all cloudflared files
        rm -rf "${CLOUDFLARED_DIR}"

        echo "Cloudflared configuration removed."
        ;;
    quick)
        WARDEN_ENV_PATH="$(locateEnvPath 2>/dev/null)" || true

        if [[ -z "${WARDEN_ENV_PATH:-}" ]]; then
            fatal "Not in a Warden environment directory. Navigate to a project with WARDEN_QUICK_TUNNEL=1."
        fi

        source "${WARDEN_DIR}/utils/env.sh"
        loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

        if [[ ${WARDEN_QUICK_TUNNEL:-0} -ne 1 ]]; then
            fatal "WARDEN_QUICK_TUNNEL is not enabled for this project. Add WARDEN_QUICK_TUNNEL=1 to your .env file."
        fi

        ## extract the quick tunnel URL from container logs
        QUICK_URL=$(${DOCKER_COMPOSE_COMMAND} \
            --project-directory "${WARDEN_ENV_PATH}" -p "${WARDEN_ENV_NAME}" \
            logs quick-tunnel 2>/dev/null | grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' | tail -1)

        if [[ -n "${QUICK_URL}" ]]; then
            echo ""
            echo "Quick Tunnel URL: ${QUICK_URL}"
            echo ""
            echo "This URL is temporary and changes when the container restarts."
        else
            echo ""
            echo "Quick Tunnel URL not found yet."
            echo "The container may still be starting. Try:"
            echo "  warden env logs quick-tunnel"
        fi
        ;;
    *)
        fatal "Unknown subcommand '${WARDEN_PARAMS[0]}'. Run 'warden cf help' for usage."
        ;;
esac
