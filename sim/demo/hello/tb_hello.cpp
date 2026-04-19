#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vhello.h"
#include "gtest/gtest.h"

// Required by Verilator on macOS
double sc_time_stamp() { return 0; }

namespace {

class HelloTest : public testing::Test {
  protected:
    void SetUp() override {}
};

TEST_F(HelloTest, hello) {
  std::unique_ptr<Vhello> v_hello = std::make_unique<Vhello>();

  vluint64_t time_counter = 0;
  vluint64_t max_cycle = 100;

  while (time_counter<max_cycle*2) {
    v_hello->eval();
    time_counter++;
  }
}

}  // namespace

