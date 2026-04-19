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
#include "sram.hpp"

class tb {
public:
  tb();
  tb(tb &&) = default;
  tb(const tb &) = default;
  tb &operator=(tb &&) = default;
  tb &operator=(const tb &) = default;
  ~tb();

  void run();

  SramModel *iSram, *dSram;

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
  // CPU Interrupt
  v_ctx->ext_interrupt = 0;

  // CPU I SRAM
  iSram->rst = v_ctx->rst;
  iSram->addr = v_ctx->im_addr;
  iSram->eval();
  v_ctx->im_wait = iSram->wait;
  v_ctx->im_data = iSram->readData;

  dSram->rst = v_ctx->rst;
  dSram->addr = v_ctx->dm_addr;
  dSram->eval();
  v_ctx->dm_wait = dSram->wait;
  v_ctx->dm_rdata = dSram->readData;
  //v_ctx->dm_addr;
  //v_ctx->dm_wdata;
  //v_ctx->dm_web;
  //v_ctx->dm_oe;
}

void tb::tick(unsigned int cycle) {
  unsigned int cycAbort = cycCurrent + cycle;

  while (cycCurrent<cycAbort) {
    std::cout << "[" << std::dec << cycCurrent << "] Posedge" << std::endl;
    v_ctx->eval();
    trace->dump(cycCurrent++);

    v_ctx->clk = !v_ctx->clk; // Negedge
    std::cout << "[" << std::dec << cycCurrent << "] Negedge" << std::endl;
    eval_vip();
    v_ctx->eval();
    trace->dump(cycCurrent++);
    v_ctx->clk = !v_ctx->clk; // Posedge
  }
}

tb::tb() {
  // VIP SetUp
  iSram = new SramModel(4096);
  dSram = new SramModel(4096);

  // Trace setup
  Verilated::traceEverOn(true);
  v_ctx->trace(trace.get(), 99);
  trace->open("tb_core.vcd");
}

tb::~tb() {
}

void tb::run () {
  // Initialize
  v_ctx->clk = true;
  v_ctx->rst = true;

  // Reset sequence
  tick(cycReset);
  v_ctx->rst = false;

  // Run till timeout
  tick(cycTimeout);
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

  // TB
  tb* tb_ptr = new tb();
  for(auto data : el.datas) {
    //std::cout << "Addr: 0x" << std::hex << data.addr << std::endl;
    //std::cout << "Size: 0x" << std::hex << data.size << std::endl;
    //for (size_t i = 0; i < data.size; i++) {
    //  std::cout << "0x" << std::hex << data.data[i] << std::endl;
    //}
    tb_ptr->iSram->preload(data.addr, data.size, data.data);// Initilize memory
    tb_ptr->dSram->preload(data.addr, data.size, data.data);// Initilize memory
  }
  tb_ptr->run();

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

