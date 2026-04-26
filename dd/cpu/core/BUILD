load("@rules_verilator//verilator:defs.bzl",  "verilator_cc_library")
load("@rules_verilog//verilog:defs.bzl",      "verilog_library")

package (
  default_visibility = ["//visibility:public"]
)

verilog_library(
    name = "core",
    srcs = [
        "IF.sv",
        "RF.sv",
        "Hazard.sv",
        "ID.sv",
        "ALU.sv",
        "Branch.sv",
        "EX.sv",
        "MEM.sv",
        "WB.sv",
        "d_stall_control.sv",
        "im_valid_control.sv",
        "Forwarding.sv",
        "counter.sv",
        "CSR.sv",
        "CPU.sv",
    ],
    deps = [],
    hdrs = [],
    visibility = ["//visibility:public"],
)

verilator_cc_library(
    name = "core_vlib",
    module = ":core",
    module_top = "CPU",
    trace = True,
    #vopts = ["-Wall"],
)

