// Standard Library
#include <stdint.h>
#include <stddef.h>
#include <string>

#include "CLI/CLI.hpp"

#ifndef __ARG_PARSER__

// Argument Parsing
struct args_s {
  bool debug;
  std::string elf_path;
};

int arg_parse(int argc, char** argv, args_s& args);

#endif // !__ARG_PARSER__

