n2nic
===

End to end IC developement.

## Pull Project & Setup Environment
- Download Project
  ```shell=
  $ git clone --recursive https://github.com/WillyXie/n2nic.git
  ```
- Build Icarus & Run Hello World Test
  ```
  $ make hello
  ```
- Include Path to Installed Tools
  ```shell=
  $ source source.sh
  ```
- Setup Python virtual environment
  ```shell=
  $ python3 -m venv .venv
  $ source .venv/bin/activate
  $ python3 -m pip install ./requirements.txt
  ```

## Run simple Smoke tests
```
$ bazel run //:smoke
```

```
```
## Build & Run Verilator Demo
```
$ pyrun --directory=$PRJROOT/test --testsuite=$PRJROOT/testsuites/basic.yaml --testname=tb_hello
$ pyrun --directory=$PRJROOT/test --testsuite=$PRJROOT/testsuites/basic.yaml --testname=tb_core
```

## Open Waveform
```
$ gtkwave tb_top.vcd misc/signal.gtkw
```

## Build Docker Environment
```
$ docker_build.sh
$ docker_start.sh
$ docker_connect.sh
```

- Stop and remove docker container
```
$ sudo docker container stop n2nic
$ sudo docker container remove n2nic
```

