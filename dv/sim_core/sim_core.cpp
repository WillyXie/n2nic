// Standard Library
#include <stdint.h>
#include <stddef.h>
#include <string>

#include "gtest/gtest.h"

#include "arg_parser.hpp"
#include "elf_loader.hpp"
#include "tb_core.hpp"

args_s args;

// Main Entry
int main(int argc, char** argv) {
  int ret;

  // Initialize and Pass gTest arguments
  testing::InitGoogleTest(&argc, argv);

  // Parsing arguments
  ret = arg_parse(argc, argv, args);
  if (ret) {
    std::cout << "Error occurs during argument parsing" << std::endl;
    return ret;
  }

  return RUN_ALL_TESTS();
}

// Define tests
namespace {

class SimpleTestSuite : public testing::Test {
protected:
  ELFLoader *el;
  TBCore *tb_ptr = new TBCore();
  TBCore &tb_r = *tb_ptr;

  void SetUp() override {
    Verilated::traceEverOn(true);

    // Load ELFs
    el = new ELFLoader(args.elf_path.c_str());
    el->print_info();

    // Setup TB inputs
    tb_ptr->vCtx->cyc_timeout = 200;
    tb_ptr->vCtx->eot_addr = 0xf000;

    // Initialize memory data in TB
    for(auto data : el->datas) {
      tb_ptr->iSram->preload(data.addr, data.size, data.data);
      tb_ptr->dSram->preload(data.addr, data.size, data.data);
    }
  }
};

TEST_F(SimpleTestSuite, simple) {
  std::cout << "Start running simulation" << std::endl;
  tb_ptr->run();
  tb_ptr->print_summary();
}

}  // namespace

