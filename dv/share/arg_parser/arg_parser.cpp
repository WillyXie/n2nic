#include "arg_parser.hpp"

int arg_parse(int argc, char** argv, args_s& args) {
  CLI::App app{"Simulation Runner"};
  app.add_option("-d,--debug", args.debug, "Debug mode")
              ->default_val(0);

  app.add_option("-e,--elf_path", args.elf_path, "Path to test ELF")
              ->required();

  try {
    CLI11_PARSE(app, argc, argv);
  }
  catch (const CLI::ParseError &e) {
    return app.exit(e);
  }

  if (args.debug) {
    //std::cout << argv[0];
    for(int idx = 0; idx<argc; idx++) {
      std::cout << argv[idx] << " ";
    }
    std::cout << std::endl;
    std::cout << app.config_to_str(true, false);
  }

  return 0;
}

