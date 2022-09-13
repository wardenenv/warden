## Database Connections

### Common Settings

| Name                           | Value/Description                                                |
| ------------------------------ |----------------------------------------------------------------- |
| MySQL Host                     | Name of your Docker Container, can be found with `warden env ps` |
| MySQL Port                     | `3306`                                                           |
| MySQL User                     | `magento`                                                        |
| MySQL Password                 | `magento`                                                        |
| MySQL Database                 | `magento`                                                        |
| SSH Host, Proxy Host, Server   | `tunnel.warden.test`                                             |
| SSH Host Port                  | `2222`                                                           |
| SSH User                       | `user`                                                           |
| SSH private key file           | `~/.warden/tunnel/ssh_key`                                       |

### TablePlus
![TablePlus Connection Info](screenshots/tableplus-connection.png)

### Sequel Pro / Sequel Ace
![Sequel Pro Connection Info](screenshots/sequel-pro-connection.png)

### PhpStorm
![PHPStorm Connection Config](screenshots/66998481-a0062100-f0d4-11e9-8cc0-a5691fee59c5.png)
![PHPStorm Tunnel Config](screenshots/66998483-a09eb780-f0d4-11e9-9643-8fe63dd62aad.png)
![PHPStorm Tunnel Config - Windows WSL2](screenshots/123906068-2ed7d180-d97c-11eb-9e52-ec48f6753ee7.png)

### Navicat for MySQL
![Navicat Connection Config](screenshots/navicat-connection-config.png)
![Navicat Tunnel Config](screenshots/navicat-ssh-tunnel-config.png)

### MySQL Workbench
![MySQL Workbench](screenshots/mysql-workbench-connection.png)

### DBeaver
![DBeaver Connection Config](screenshots/dbeaver-connection.png)
![DBeaver SSH Config](screenshots/dbeaver-ssh.png)