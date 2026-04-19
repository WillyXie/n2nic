load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@aspect_bazel_lib//lib:transitions.bzl", "platform_transition_filegroup")

cc_binary(
    name = "baremetal",
    srcs = ["main.c"],
    deps = ["//tests/baremetal/startup"],
)

platform_transition_filegroup(
    name = "elf",
    srcs = [":baremetal"],
    target_platform = "//tests/baremetal/platforms:riscv32_imac",
    visibility = ["//visibility:public"],
)

genrule(
    name = "hex",
    srcs = [":elf"],
    outs = ["elf.hex"],
    cmd = "$(execpath @riscv_none_elf//:objcopy) -O ihex $< $@",
    tools = ["@riscv_none_elf//:objcopy"],
    visibility = ["//visibility:public"],
)

genrule(
    name = "dis",
    srcs = [":elf"],
    outs = ["elf.dis"],
    cmd = "$(execpath @riscv_none_elf//:objdump) -D $< > $@",
    tools = ["@riscv_none_elf//:objdump"],
    visibility = ["//visibility:public"],
)

