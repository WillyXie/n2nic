// Standard Library
#include <stdint.h>
#include <stddef.h>
#include <string>

#include "gtest/gtest.h"

// Verilator & Verilated Design
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VCPU.h"

#include "arg_parser.hpp"
#include "elf_loader.hpp"

class tb {
public:
  tb();
  tb(tb &&) = default;
  tb(const tb &) = default;
  tb &operator=(tb &&) = default;
  tb &operator=(const tb &) = default;
  ~tb();

private:
  std::unique_ptr<VCPU> v_ctx = std::make_unique<VCPU>();
  std::unique_ptr<VerilatedVcdC> trace = std::make_unique<VerilatedVcdC>();

  vluint64_t cycCurrent = 0;
  vluint64_t cycReset   = 20;
  vluint64_t cycTimeout = 100;

  void tick(unsigned int cycle);
  void eval_vip();
};

void tb::eval_vip() {
  v_ctx->ext_interrupt = 0;
  v_ctx->im_data = uint32_t(0);
  v_ctx->im_wait = 1;
  //v_ctx->im_addr;

  v_ctx->dm_rdata = uint32_t(0);
  v_ctx->dm_wait = 1;
  //v_ctx->dm_addr;
  //v_ctx->dm_wdata;
  //v_ctx->dm_web;
  //v_ctx->dm_oe;
}

void tb::tick(unsigned int cycle) {
  unsigned int cycAbort = cycCurrent + cycle;

  while (cycCurrent<cycAbort) {
    v_ctx->eval();
    trace->dump(cycCurrent++);

    v_ctx->clk = !v_ctx->clk; // Negedge
    eval_vip();
    v_ctx->eval();
    trace->dump(cycCurrent++);
    v_ctx->clk = !v_ctx->clk; // Posedge
  }
}

tb::tb() {
  // Trace setup
  Verilated::traceEverOn(true);
  v_ctx->trace(trace.get(), 99);
  trace->open("tb_core.vcd");

  // Initialize
  v_ctx->clk = 1;
  v_ctx->rst = 1;

  // Reset sequence
  tick(cycReset);
  v_ctx->rst = 0;

  tick(cycTimeout);
}

tb::~tb() {
}

// Required by Verilator on macOS
double sc_time_stamp() { return 0; }

// Main Entry
int main(int argc, char** argv) {
  int ret;

  // Initialize and Pass gTest arguments
  testing::InitGoogleTest(&argc, argv);

  // Parsing arguments
  args_s args;
  ret = arg_parse(argc, argv, args);
  if (ret) {
    std::cout << "Error occurs during argument parsing" << std::endl;
    return ret;
  }

  // Load ELFs
  ELFLoader el(args.elf_path.c_str());
  el.print_info();

  // Initilize memory

  // TB
  tb tb_ptr();

  return RUN_ALL_TESTS();
}

// Testbench
namespace {

class SimpleTest : public testing::Test {
  protected:
    void SetUp() override {
      Verilated::traceEverOn(true);
    }
};

TEST_F(SimpleTest, simple) {
}

}  // namespace

