load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

cc_library(
    name = "arg_parser",
    srcs = ["arg_parser.cpp"],
    hdrs = ["arg_parser.hpp"],
    deps = ["@cli11//:cli11",],
    includes = ["."],
    visibility = ["//visibility:public"],
)

