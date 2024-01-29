# Docker-Compose-Install
Docker Compose Installation Script


Example of the output

```
./docker-compose-install.sh
Current Docker-Compose version: 2.24.2
Installed at: /volume1/@appstore/ContainerManager/usr/bin/docker-compose
Retrieving last 5 Docker Compose Releases...
1. v2.24.3 2024-01-24 18:01:55ZZ
2. v2.24.2 2024-01-22 16:33:37ZZ
3. v2.24.1 2024-01-18 10:02:11ZZ
4. v2.24.0 2024-01-11 13:23:00ZZ
5. v2.24.0-birthday.10 2023-12-11 14:29:25ZZ
Enter the number of the Docker-Compose version to install: 1
Version changing from 2.24.2 to version v2.24.3
Downloading Docker-Compose v2.24.3...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 58.1M  100 58.1M    0     0  32.2M      0  0:00:01  0:00:01 --:--:-- 46.6M
Installation completed successfully!
Current Docker-Compose version: 2.24.3
Installed at: /volume1/@appstore/ContainerManager/usr/bin/docker-compose
```

Uses realpath to find the location of your docker-compose
