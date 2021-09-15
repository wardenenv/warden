# Warden

![Docker Image Architures](https://img.shields.io/badge/architecture-arm64%20%7C%20amd64-success)
![PHP Version](https://img.shields.io/badge/php-7.4-blue)
![Magento Version](https://img.shields.io/badge/magento-2.4-orange)
![License](https://img.shields.io/github/license/drpayyne/docker-php)

> This repository is forked from https://github.com/davidalger/warden to make Warden multi-arch. Please refer to the source repository for the original README.

## Installing Warden

```bash
# Make the installation directory
sudo mkdir /opt/warden

# Set ownership for the installation directory
sudo chown $(whoami) /opt/warden

# Clone multi-arch fork of Warden (this repository) into the installation directory
git clone https://github.com/drpayyne/warden-multi-arch.git /opt/warden

# Export Warden to PATH. (use your appropriate shell resource file; zshrc here.)
echo 'export PATH="/opt/warden/bin:$PATH"' >> ~/.zshrc

# Export Warden to current shell's PATH
PATH="/opt/warden/bin:$PATH"

# Create and start Warden services
warden svc up

# Install Warden configuration
warden install
```

## Available Packages

Add the registry & user prefix of `ghcr.io/drpayyne/` to all the below packages for usage. All the below packages are available for both `linux/arm64` and `linux/amd64` architectures.

| Service | Package & Tag |
|---|---|
| PHP 7.4 | <ul><li>`warden-php` (latest)</li><li>`warden-php:7.4`</li></ul> |
| PHP 7.4 for M2 | <ul><li>`warden-php-m2` (latest)</li><li>`warden-php-m2:7.4`</li></ul> |
| PHP 7.4 for M2 with xDebug3 | <ul><li>`warden-php-m2-xdebug3` (latest)</li><li>`warden-php-m2-xdebug3:7.4`</li></ul> |
| Magepack | <ul><li>`warden-magepack` (latest)</li><li>`warden-magepack:2.3`</li></ul> |
| MailHog | <ul><li>`warden-mailhog` (latest)</li><li>`warden-mailhog:1.0`</li></ul> |
| Nginx | <ul><li>`warden-nginx` (latest)</li><li>`warden-nginx:1.16`</li></ul> |
| Elasticsearch | <ul><li>`warden-elasticsearch` (latest)</li><li>`warden-elasticsearch:7.9`</li></ul> |
| Varnish | <ul><li>`warden-varnish` (latest)</li><li>`warden-varnish:6.5`</li><li>`warden-varnish:6.4`</li><li>`warden-varnish:6.0`</li></ul> |
