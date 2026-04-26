#ifndef __TB_CORE__
#define __TB_CORE__

// Standard Library
#include <stdint.h>
#include <stddef.h>
#include <string>

#include "tb_api.hpp"
#include "tb_base.hpp"

// Verilated design
#include "Vtb_core.h"

// VIP for verification requiement
#include "sram.hpp"

class TBCore : public TBBase <Vtb_core> {
public:
  TBCore() {
    TBBase<Vtb_core>();

    // VIP SetUp
    iSram = new SramModel(1024*64);
    iSram->m_dbg_name = "[SRAMMODEL_ISRAM] ";
    dSram = new SramModel(1024*64);
    dSram->m_dbg_name = "[SRAMMODEL_DSRAM] ";
  }

  ~TBCore(){};

  TBCore(TBCore &&) = default;
  TBCore(const TBCore &) = default;
  TBCore &operator=(TBCore &&) = default;
  TBCore &operator=(const TBCore &) = default;

  void print_summary();
  void run();

  SramModel *iSram, *dSram;

protected:

private:
  vluint64_t cycCurrent = 0;
  vluint64_t cycReset   = 20;
  vluint64_t cycTimeout = 100;

  void tick(unsigned int cycle);
  void tick();
  void eval_vip();
};

#endif // !__TB_CORE__

