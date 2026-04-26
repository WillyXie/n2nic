// Standard Library
#include <iostream>
#include <string>
#include <stdint.h>
#include <stddef.h>

#ifndef __SRAM_C__
#define __SRAM_C__

class SramModel {
public:
  SramModel(uint32_t size_) {
    size = size_;
    data = new uint32_t[size>>2];
  }

  ~SramModel(){}

  SramModel(SramModel &&) = default;
  SramModel(const SramModel &) = default;
  SramModel &operator=(SramModel &&) = default;
  SramModel &operator=(const SramModel &) = default;

  void eval();
  void preload(uint32_t, uint32_t, uint32_t*);

  std::string m_dbg_name = "[SRAMMODEL] ";

private:
  uint32_t    size;
  uint32_t*   data;

public:
  // Signals
  bool rst;
  bool wait;

  uint32_t  addr;
  uint32_t  readData;

  bool      oe;
  uint8_t   writeEnable;  // Take last 4 bit only
  uint32_t  writeData;
};


#endif // !__SRAM_C__

