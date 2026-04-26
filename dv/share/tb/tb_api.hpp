#ifndef __TB_API__
#define __TB_API__

// Standard Library
#include <iostream>
#include <stdint.h>
#include <stddef.h>
#include <string>

extern "C" {

struct SimReport {
  int errCode;
  std::string errMessage;
};

static SimReport  s_report;
static bool       s_terminate = false;

bool check_abort ();
void sim_terminate (int err);

}

#endif // !__TB_API__

