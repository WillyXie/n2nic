#include "sram.hpp"


SramModel::SramModel(uint32_t size_) {
  size = size_;
  data = new uint32_t[size];
}

SramModel::~SramModel() {
}

void SramModel::eval() {
  if (rst) {
    wait = true;
    readData = 0x0;
    std::cout << m_dbg_name << "SRAM during reset" << std::endl;
  } else {
    if (addr>size) {
      std::cerr << "Request address is out of memory size" << std::endl;
    } else {
      wait = false;
      readData = data[addr];
      std::cout << m_dbg_name
                << "Read addr: 0x" << addr
                << ", data: 0x" << readData
                << std::endl;
    }
    //v_ctx->dm_wdata;
    //v_ctx->dm_web;
    //v_ctx->dm_oe;
  }
}

void SramModel::preload (
    uint32_t  addr_,
    uint32_t  size_,
    uint32_t* data_) {
  if ((addr_+size_)>size) {
    std::cerr << m_dbg_name
              << "Preload address range is out of memory size: "
              << "addr: 0x"   << std::hex << addr_
              << ", size: 0x" << std::hex << size_
              << std::endl;
  } else {
    for (size_t offset = 0; offset < size_; offset++) {
      data[addr_+offset] = data_[offset];
      std::cout << m_dbg_name
                << "Preload addr: 0x" << std::hex << (addr_+offset)
                << ", data: 0x"       << std::hex << data_[offset]
                << std::endl;
    }
  }
}

