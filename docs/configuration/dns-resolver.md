## Automatic DNS resolution

In order to allow automatic DNS resolution using the provided dnsmasq service we will need to make sure DNS request are routed through our local network.
This requires some configuration.

### Configuration per network
#### Mac

Open up your connection (WiFi/LAN) settings, and go to the DNS tab. In here press the "+" button to add a new DNS record with the following IP address: `127.0.0.1`
```text
127.0.0.1
```

#### Ubuntu

Open up your connection (WiFi/LAN) settings, and go to the IPv4 tab. Turn off the automatic DNS setting, and enter the following IP addresses

```text
127.0.0.1, 8.8.8.8, 8.8.4.4
```

### Persistent global configuration

To avoid having to set the DNS servers for each network you connect you, you can also choose update the global DNS configuration.

#### Ubuntu
Use the `resolvconf` service to add a permanent entry in your `/etc/resolv.conf` file.

Install resolvconf
```bash
$ sudo apt update && sudo apt install resolvconf
```
Edit the `/etc/resolvconf/resolv.conf.d/base` file as follows:

```text
search home net
nameserver 127.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
```

Restart network-manager
```bash
$ sudo service network-manager restart
```

> **_NOTE:_**  
> In the above examples you can replace `8.8.8.8` and `8.8.4.4` with the IP of your own preferred DNS resolution service*
