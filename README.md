n2nic
===

End to end IC developement.

## Installation
```shell=
git clone --recursive https://github.com/WillyXie/n2nic.git
```

## Bring Up Docker Environment
I use docker to build an Ubuntu 24.04 environment for development, and the docker engine is running on Windows OS.<br />
You can follow these steps to bring it up, or just change corresponding commands to match your own machine if it's not Windows.

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

The docker system has XRDP support, so you can connect to the localhost:3389 for GUI desktop. But you'll need to connect into it and start the XRDP service first.
```shell=
$ docker exec -it basic /bin/bash
$ service xrdp start
```