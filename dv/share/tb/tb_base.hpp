#ifndef __TB_BASE__
#define __TB_BASE__

// Standard Library
#include <iostream>
#include <stdint.h>
#include <stddef.h>
#include <string>

// Verilated design
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtb_base.h"

template <class T>
class TBBase {
public:
  TBBase() {
    // Trace setup
    Verilated::traceEverOn(true);
    vCtx->trace(trace.get(), 99);
    trace->open("tb_base.vcd");
  }
  ~TBBase(){}

  TBBase(TBBase &&) = default;
  TBBase(const TBBase &) = default;
  TBBase &operator=(TBBase &&) = default;
  TBBase &operator=(const TBBase &) = default;

  void run();

  std::unique_ptr<T> vCtx = std::make_unique<T>();
  std::unique_ptr<VerilatedVcdC> trace = std::make_unique<VerilatedVcdC>();

protected:

private:
  vluint64_t cycCurrent = 0;
  vluint64_t cycReset   = 20;
  vluint64_t cycTimeout = 100;

  void tick(unsigned int cycle);
  void eval_vip();
};

//template <class T>
//TBBase<T>::TBBase() {
//  // Trace setup
//  Verilated::traceEverOn(true);
//  vCtx->trace(trace.get(), 99);
//  trace->open("tb_base.vcd");
//}
//
//template <class T>
//TBBase<T>::~TBBase() {
//}

#endif // !__TB_BASE__

