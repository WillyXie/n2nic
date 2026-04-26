load("@rules_verilator//verilator:defs.bzl",  "verilator_cc_library")
load("@rules_verilog//verilog:defs.bzl",      "verilog_library")

package (
  default_visibility = ["//visibility:public"]
)

verilog_library(
    name = "cache",
    srcs = [
        "cache/comparator.sv",
        "cache/control.sv",
        "cache/control_inst.sv",
        "cache/data_mux.sv",
        "cache/data_array_wrapper.sv",
        "cache/tag_array_wrapper.sv",
        "cache/L1C_data.sv",
        "cache/L1C_inst.sv",
        #"cache/L1C_data_A.sv",
        #"cache/L1C_data_B.sv",
        #"cache/L1C_inst_A.sv",
        #"cache/L1C_inst_B.sv",
        #"cache/L2C_data.sv",
        #"cache/L2C_inst.sv",
    ],
    hdrs = [],
    visibility = ["//visibility:public"],
)

