#include "sram.hpp"

void SramModel::eval() {
  uint32_t index = addr/4;
  uint32_t dataUpdate = 0;

  if (rst) {
    wait = true;
    readData = 0x0;
  } else {
    wait = false;
    if (addr>size
        && (  oe
          ||  (writeEnable<<4)>>4!=0xf)) {
      std::cerr << m_dbg_name
                << "Addr: 0x" << addr
                << " is out of memory size"
                << std::endl;
    } else {
      if (oe) {
        readData = data[index];
        std::cout << m_dbg_name
                  << "Read addr: 0x" << addr
                  << " index: 0x" << index
                  << ", data: 0x" << readData
                  << std::endl;
      }
      else if ((writeEnable<<4)>>4!=0xf) {
        dataUpdate = data[index];

        if ((writeEnable & 0x1) == 0) {
          dataUpdate = dataUpdate & 0xffffff00;
          dataUpdate = dataUpdate | (writeData & 0x000000ff);
        }

        if ((writeEnable & 0x2) == 0) {
          dataUpdate = dataUpdate & 0xffff00ff;
          dataUpdate = dataUpdate | (writeData & 0x0000ff00);
        }

        if ((writeEnable & 0x4) == 0) {
          dataUpdate = dataUpdate & 0xff00ffff;
          dataUpdate = dataUpdate | (writeData & 0x00ff0000);
        }

        if ((writeEnable & 0x8) == 0) {
          dataUpdate = dataUpdate & 0x00ffffff;
          dataUpdate = dataUpdate | (writeData & 0xff000000);
        }

        std::cout << m_dbg_name
                  << "Write addr: 0x" << addr
                  << " index: 0x" << index
                  << ", enable: 0x" << (writeEnable & 0xf)
                  << ", originalData: 0x" << data[index]
                  << ", writeData: 0x" << writeData
                  << ", updateData: 0x" << dataUpdate
                  << std::endl;

        data[index] = dataUpdate;
      }
    }
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
    uint32_t index = 0;
    for (size_t offset = 0; offset*4 < size_; offset++) {
      index = addr_/4 + offset;
      data[index] = data_[offset];
      //std::cout << m_dbg_name
      //          << "Preload addr: 0x" << std::hex << (addr_+offset*4)
      //          << " index: 0x"       << std::hex << index
      //          << ", data: 0x"       << std::hex << data[index]
      //          << std::endl;
    }
  }
}

