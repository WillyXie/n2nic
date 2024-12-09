n2nic
===

End to end IC developement.

## Installation
```shell=
git clone -r https://github.com/WillyXie/n2nic.git
```

## Bring Up Docker Environment
- CLI commands
    ```shell=
    $ docker build -t n2nic .\ext\docker-ubuntu
    $ docker run -v ${PSScriptRoot}:/work -p 3389:3389 --name basic -td n2nic /bin/bash
    ```

- Pre-defined script for Windows
    ```shell=
    $ ./build.ps1
    $ ./start.ps1
    ```