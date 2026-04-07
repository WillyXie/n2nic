#include <verilated.h>
#include <verilated_vcd_c.h>

#include "VCPU_wrapper.h"
#include "gtest/gtest.h"

// Required by Verilator on macOS
double sc_time_stamp() { return 0; }

namespace {

class SimpleTest : public testing::Test {
  protected:
    void SetUp() override {
      Verilated::traceEverOn(true);
    }
};

TEST_F(SimpleTest, simple) {
  std::unique_ptr<VCPU_wrapper> v_cpu = std::make_unique<VCPU_wrapper>();

  // Open trace file
  auto trace = std::make_unique<VerilatedVcdC>();
  v_cpu->trace(trace.get(), 99);
  trace->open("tb_top.vcd");

  vluint64_t time_counter = 0;
  vluint64_t max_cycle = 100;

  v_cpu->CK = 0;
  while (time_counter<max_cycle*2) {
    v_cpu->CK = !v_cpu->CK;
    v_cpu->eval();
    trace->dump(time_counter++);
  }
}

}  // namespace

