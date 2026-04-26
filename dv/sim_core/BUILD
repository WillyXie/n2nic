load("@rules_cc//cc:defs.bzl",  "cc_binary")
load("@bazel_skylib//rules:run_binary.bzl", "run_binary")

cc_binary(
    name = "sim_core",
    srcs = ["sim_core.cpp"],
    data = [],
    deps = [
        "@googletest//:gtest_main",
        "//dv/share/arg_parser:arg_parser",
        "//dv/share/elf_loader:elf_loader",
        "//dv/share/tb:tb_core_c",
    ],
    copts = [
        "-w",
    ],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "sh_tb",
    srcs = ["//tools/py_scripts:run_and_log.sh"],
    data = [
        ":sim_core",
        "//tests/simple:elf",
        "//tests/simple:dis", # To generate disassemble
    ],
    args = [
        "$(location :sim_core)",
        "-e $(location //tests/simple:elf)"
    ],
    visibility = ["//visibility:public"],
)

