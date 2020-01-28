## Warden Usage

### Common Commands

Drop into a shell within the project environment (this command opens a bash shell in the `php-fpm` container)

    warden shell

Stopping a running environment (on linux, drop the `sync` command, it's not used on Linux)

    warden env stop && warden sync stop

Starting a stopped environment (on linux, drop the `sync` command, it's not used on Linux)

    warden env start && warden sync start

Watch the database processlist:

    watch -n 3 "warden db connect -A -e 'show processlist'"

Tail environment access logs:

    warden env logs --tail 0 -f nginx php-fpm php-debug

Tail the varnish activity log:

    warden env exec -T varnish varnishlog

### Further Information

Run `warden help` and `warden env -h` for more details and useful command information.
