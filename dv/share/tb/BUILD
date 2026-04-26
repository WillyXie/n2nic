load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_verilator//verilator:defs.bzl", "verilator_cc_library")
load("@rules_verilog//verilog:defs.bzl", "verilog_library")

package (
  default_visibility = ["//visibility:public"]
)

# TB API Library
cc_library(
    name = "tb_api_c",
    srcs = ["tb_api.cpp"],
    hdrs = ["tb_api.hpp"],
    includes = ["."],
    deps = [],
)

# Base TB
verilog_library(
    name = "tb_base",
    srcs = [
        "tb_base.sv",
    ],
    deps = [
        "//dv/share/vip/watchdog:watchdog",
    ],
    hdrs = [],
    visibility = ["//visibility:public"],
)

verilator_cc_library(
    name = "tb_base_vlib",
    module = ":tb_base",
    module_top = "tb_base",
    trace = True,
    vopts = ["-Wall"],
)

cc_library(
    name = "tb_base_c",
    srcs = ["tb_base.cpp"],
    hdrs = ["tb_base.hpp"],
    includes = ["."],
    deps = [
        ":tb_api_c",
        ":tb_base_vlib",
    ],
)

# Core only TB
verilog_library(
    name = "tb_core",
    srcs = [
        "tb_core.sv",
    ],
    deps = [
        "//dd/cpu/core:core",
        "//dv/share/vip/watchdog:watchdog",
    ],
    hdrs = [],
    visibility = ["//visibility:public"],
)

verilator_cc_library(
    name = "tb_core_vlib",
    module = ":tb_core",
    module_top = "tb_core",
    trace = True,
    vopts = ["-Wall"],
)

cc_library(
    name = "tb_core_c",
    srcs = ["tb_core.cpp"],
    hdrs = ["tb_core.hpp"],
    copts = [
        "-Wall",
    ],
    deps = [
        ":tb_api_c",
        ":tb_base_c",
        ":tb_core_vlib",
        "//dv/share/vip/sram_c:sram_c",
    ],
    includes = ["."],
    visibility = ["//visibility:public"],
)

