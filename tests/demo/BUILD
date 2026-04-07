load("@rules_verilator//verilator:defs.bzl",  "verilator_cc_library")
load("@rules_verilog//verilog:defs.bzl",      "verilog_library")

verilog_library(
    name = "hello",
    srcs = ["hello.sv"],
    #deps = [":counter"], # Dependency tracking
    visibility = ["//visibility:public"],
)

verilator_cc_library(
    name = "hello_vlib",
    module = ":hello",
    module_top = "HELLO",
    #systemc = True, # Generate SystemC output
    trace = True, # Waveform tracing
    vopts = ["-Wall"],
)

cc_binary(
    name = "tb_hello",
    srcs = ["tb_hello.cpp"],
    deps = [
      ":hello_vlib",
      "@googletest//:gtest_main",
    ],
)

