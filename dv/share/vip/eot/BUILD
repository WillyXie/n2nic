load("@rules_verilator//verilator:defs.bzl",  "verilator_cc_library")
load("@rules_verilog//verilog:defs.bzl",      "verilog_library")

package (
  default_visibility = ["//visibility:public"]
)

verilog_library(
    name = "watchdog",
    srcs = [
        "watchdog.sv",
    ],
    visibility = ["//visibility:public"],
)

verilator_cc_library(
    name = "watchdog_vlib",
    module = ":watchdog",
    module_top = "watchdog",
    trace = True,
    vopts = ["-Wall"],
)

