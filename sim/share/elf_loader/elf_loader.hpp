// Standard Library
#include <cstring>
#include <fstream>
#include <iostream>
#include <vector>

#include <elf.h>

#ifndef __ELF_LOADER__

typedef struct {
  uint32_t addr;
  uint32_t size;
  uint32_t* data;
} data_s;

class ELFLoader {
public:
  ELFLoader(const char*);
  ELFLoader(ELFLoader &&) = default;
  ELFLoader(const ELFLoader &) = default;
  ELFLoader &operator=(ELFLoader &&) = default;
  ELFLoader &operator=(const ELFLoader &) = default;
  ~ELFLoader();

  void print_info();

  std::vector<data_s> datas;

private:
  uint32_t pc;

  //uint32_t get_mem_w (unsigned long long  int addr) {
  //  return *(uint32_t*)(ALISS::memory + addr);
  //}
};

#endif // !__ELF_LOADER__

