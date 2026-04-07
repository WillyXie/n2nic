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


## Build Docker Environment
```
$ docker_build.sh
$ docker_start.sh
$ docker_connect.sh
```

Stop and remove docker container
```
$ sudo docker container stop n2nic
$ sudo docker container remove n2nic
```

## Build & Run Verilator
```
$ bazel build //sim:my_test
$ ./bazel-bin/sim/my_test --trace-params
```

## Open Waveform
```
$ gtkwave tb_top.vcd misc/signal.gtkw
```
```

```
