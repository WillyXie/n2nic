#include "tb_core.hpp"

void TBCore::eval_vip() {
  // CPU Interrupt
  vCtx->ext_interrupt = 0;

  // CPU I SRAM
  iSram->rst = !vCtx->rstn;
  iSram->addr = vCtx->im_addr;
  iSram->oe           = true;
  iSram->writeEnable  = 0xf;
  iSram->writeData    = 0x0;
  iSram->eval();
  vCtx->im_wait = iSram->wait;
  vCtx->im_data = iSram->readData;

  // CPU D SRAM
  dSram->rst          = !vCtx->rstn;
  dSram->addr         = vCtx->dm_addr;
  dSram->oe           = vCtx->dm_oe;
  dSram->writeEnable  = vCtx->dm_web;
  dSram->writeData    = vCtx->dm_wdata;
  dSram->eval();
  vCtx->dm_wait = dSram->wait;
  vCtx->dm_rdata = dSram->readData;
}

void TBCore::tick() {
  while (!check_abort()) {
    //std::cout << "[" << std::dec << cycCurrent << "] Posedge" << std::endl;
    vCtx->eval();
    trace->dump(cycCurrent++);

    vCtx->clk = !vCtx->clk; // Negedge
    //std::cout << "[" << std::dec << cycCurrent << "] Negedge" << std::endl;
    eval_vip();
    vCtx->eval();
    trace->dump(cycCurrent++);
    vCtx->clk = !vCtx->clk; // Posedge
  }
}

void TBCore::tick(unsigned int cycle) {
  unsigned int cycAbort = cycCurrent + cycle;

  while (!check_abort() && cycCurrent<cycAbort) {
    //std::cout << "[" << std::dec << cycCurrent << "] Posedge" << std::endl;
    vCtx->eval();
    //v_watchdog->eval();
    trace->dump(cycCurrent++);

    vCtx->clk = !vCtx->clk; // Negedge
    //std::cout << "[" << std::dec << cycCurrent << "] Negedge" << std::endl;
    eval_vip();
    vCtx->eval();
    trace->dump(cycCurrent++);
    vCtx->clk = !vCtx->clk; // Posedge
  }
}

void TBCore::print_summary() {
  std::cout << "Cycle count: 0x" << std::hex << cycCurrent << std::endl;
}

void TBCore::run () {
  // Initialize
  vCtx->clk = true;
  vCtx->rstn = false;

  // Reset sequence
  tick(cycReset);
  vCtx->rstn = true;

  // Run till timeout
  tick();
}

