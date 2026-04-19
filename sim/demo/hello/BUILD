load("@rules_verilator//verilator:defs.bzl",  "verilator_cc_library")
load("@rules_verilog//verilog:defs.bzl",      "verilog_library")

verilog_library(
    name = "hello",
    srcs = ["hello.sv"],
)

verilator_cc_library(
    name = "hello_vlib",
    module = ":hello",
    module_top = "hello",
)

cc_binary(
    name = "tb_hello",
    srcs = ["tb_hello.cpp"],
    copts = [],
    deps = [
      ":hello_vlib",
      "@googletest//:gtest_main",
    ],
    visibility = ["//visibility:public"],
)

