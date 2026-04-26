load("@riscv_none_elf//toolchain:toolchain.bzl", "riscv_none_elf_toolchain")

riscv_none_elf_toolchain(
    #name = "riscv32_imac",
    name = "riscv32_i",
    copts = [
        #"-march=rv32imac",
        "-march=rv32i",
        "-mabi=ilp32",
        "-mcmodel=medlow",
        "-c",
        "-Wall",
        "-Wextra",
        "-fmessage-length=0",
    ],
    linkopts = [
        #"-march=rv32imac",
        "-march=rv32i",
        "-mabi=ilp32",
        "-mcmodel=medlow",
        "-nostdlib",
        "-nostartfiles",
    ],
    target_compatible_with = [
        "@platforms//cpu:riscv32",
        "@platforms//os:none",
        #"//tests/baremetal/constraints/march:imac",
        "//tests/baremetal/constraints/march:i",
    ],
)
