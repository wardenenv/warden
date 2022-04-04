ARG MYSQL_VERSION
FROM mysql:${MYSQL_VERSION}-oracle

# MySQL 8.0 require skip-bin-log to avoid workarounds:
# See: https://github.com/davidalger/warden/pull/403
COPY etc/mysql/conf.d/skip-bin-log.cnf /etc/mysql/conf.d/
