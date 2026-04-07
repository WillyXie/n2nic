load("@rules_verilator//verilator:defs.bzl", "verilator_cc_library")

#verilator_cc_library(
#    name = "cpu_top_vlib",
#    module = "//src/cpu:cpu_top",
#    module_top = "CPU",
#    #systemc = True, # Generate SystemC output
#    trace = True, # Waveform tracing
#    vopts = ["-Wall"],
#)

cc_binary(
    name = "tb_top",
    srcs = ["tb_top.cpp"],
    deps = [
      #":cpu_top_vlib",
      "//src/cpu:cpu_top_vlib",
      "@googletest//:gtest_main",
    ],
)

