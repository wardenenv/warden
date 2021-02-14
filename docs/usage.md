## Warden Usage

### Common Commands

Launch a shell session within the project environment's `php-fpm` container:

    warden shell

Stopping a running environment:

    warden env stop

Starting a stopped environment:

    warden env start

Import a database (if you don't have `pv` installed, use `cat` instead):

    pv /path/to/dump.sql.gz | gunzip -c | warden db import

Monitor database processlist:

    watch -n 3 "warden db connect -A -e 'show processlist'"

Tail environment nginx and php logs:

    warden env logs --tail 0 -f nginx php-fpm php-debug

Tail the varnish activity log:

    warden env exec -T varnish varnishlog

Flush varnish:

     warden env exec -T varnish varnishadm 'ban req.url ~ .' 

Connect to redis:

    warden env exec redis redis-cli

Flush redis completely:

    warden env exec -T redis redis-cli flushall

Remove volumes completely:

    warden env down -v

### Further Information

Run `warden help` and `warden env -h` for more details and useful command information.
