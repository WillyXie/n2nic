load("@rules_cc//cc:defs.bzl",  "cc_binary")
load("@bazel_skylib//rules:run_binary.bzl", "run_binary")

cc_binary(
    name = "tb_core",
    srcs = ["tb_core.cpp"],
    data = [],
    deps = [
        "@googletest//:gtest_main",
        "//sim/share/arg_parser:arg_parser",
        "//sim/share/elf_loader:elf_loader",
        "//sim/share/vip/sram:sram_c",
        "//src/cpu/core:core_vlib",
    ],
    copts = [
      "-w",
    ],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "sh_tb",
    srcs = [":tb_core"],
    data = [
        ":tb_core",
        "//tests/simple:elf",
        "//tests/simple:dis", # To generate disassemble
    ],
    args = [
      "-e $(location //tests/simple:elf)"
    ],
    visibility = ["//visibility:public"],
)

#run_binary(
#    name = "run_tb",
#    srcs = [
#        ":hex",
#        ":tb_top"
#    ],
#    outs = ["log"],
#    args = [
#        "$(location :tb_top)",
#        "$(location log)",
#    ],
#    #env,
#    tool = "//tests:run_and_log.sh",
#)

