load("@rules_verilator//verilator:defs.bzl",  "verilator_cc_library")
#load("@rules_verilog//verilog:defs.bzl",      "verilog_library")
load("@rules_hdl//verilog:defs.bzl", "verilog_library")

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

verilog_library(
    name = "cpu_top",
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
        "CPU_wrapper.sv",
        #"top.sv",

        #"control_data.sv",
        #"DRAM_Wrapper.sv",
        #"ROM_Wrapper.sv",
        #"SRAM_wrapper.sv",
        #"CORE_A_wrapper.sv",
        #"CORE_B_wrapper.sv",
        #"CSR_A.sv",
        #"CSR_B.sv",
        #"CPU_A.sv",
        #"CPU_B.sv",
        #"cache_arbiter.sv",
        #"DUALCORE_wrapper.sv",
    ],
    deps = [":cache"], # Dependency tracking
    hdrs = [],
    visibility = ["//visibility:public"],
)

verilator_cc_library(
    name = "cpu_top_vlib",
    module = ":cpu_top",
    module_top = "CPU_wrapper",
    #systemc = True, # Generate SystemC output
    trace = True, # Waveform tracing
    vopts = ["-Wall"],
)

