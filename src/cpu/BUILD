load("@rules_verilator//verilator:defs.bzl",  "verilator_cc_library")
load("@rules_verilog//verilog:defs.bzl",      "verilog_library")

package (
  default_visibility = ["//visibility:public"]
)

verilog_library(
    name = "cpu_wrapper",
    srcs = [
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
    deps = [
        "//src/cpu/cache:cache",
        "//src/cpu/core:core",
    ],
    hdrs = [],
    includes = ["core"],
    visibility = ["//visibility:public"],
)

verilator_cc_library(
    name = "cpu_top_vlib",
    module = ":cpu_wrapper",
    module_top = "CPU_wrapper",
    #systemc = True, # Generate SystemC output
    trace = True, # Waveform tracing
    vopts = ["-Wall"],
)

