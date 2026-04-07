#include <verilated.h>
#include <verilated_vcd_c.h>

#include "VHELLO.h"
#include "gtest/gtest.h"

// Required by Verilator on macOS
double sc_time_stamp() { return 0; }

namespace {

class HelloTest : public testing::Test {
  protected:
    void SetUp() override {
      Verilated::traceEverOn(true);
    }
};

TEST_F(HelloTest, hello) {
  std::unique_ptr<VHELLO> v_hello = std::make_unique<VHELLO>();

  // Open trace file
  auto trace = std::make_unique<VerilatedVcdC>();
  v_hello->trace(trace.get(), 99);
  trace->open("tb_hello.vcd");

  vluint64_t time_counter = 0;
  vluint64_t max_cycle = 100;

  //v_our->clk = 0;
  while (time_counter<max_cycle*2) {
    //v_cpu->clk = !v_cpu->clk;
    v_hello->eval();
    trace->dump(time_counter++);
  }
}

}  // namespace

