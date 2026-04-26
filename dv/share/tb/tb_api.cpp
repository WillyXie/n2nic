#include "tb_api.hpp"

bool check_abort () {
  return s_terminate;
}

void sim_terminate (int err) {
  s_terminate = true;
  s_report.errCode = err;
  std::cout << "Terminate simulation is called" << std::endl;
}

