// Standard Library
#include <cstring>
#include <iostream>
#include <fstream>

#include <elf.h>

#ifndef __ELF_LOADER__

class ELFLoader {
public:
  ELFLoader(const char*);
  ELFLoader(ELFLoader &&) = default;
  ELFLoader(const ELFLoader &) = default;
  ELFLoader &operator=(ELFLoader &&) = default;
  ELFLoader &operator=(const ELFLoader &) = default;
  ~ELFLoader();

  void print_info();

private:
  uint32_t pc;
};

#endif // !__ELF_LOADER__

