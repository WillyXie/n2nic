#include "elf_loader.hpp"

ELFLoader::ELFLoader(const char* filename) {
  // ELF loader function
  std::ifstream file;
  file.open(filename, std::ios::binary);
  if (!file) {
    std::cerr << "Failed to open file: " << filename << std::endl;
    return;
  }

  // Read the ELF header
  Elf32_Ehdr elfHeader;
  file.read(reinterpret_cast<char*>(&elfHeader), sizeof(Elf32_Ehdr));

  // Check ELF magic number
  if (memcmp(elfHeader.e_ident, ELFMAG, SELFMAG) != 0) {
    std::cerr << "Not a valid ELF file: " << filename << std::endl;
    return;
  }

  // Check ELF class (32-bit or 64-bit)
  if (elfHeader.e_ident[EI_CLASS] != ELFCLASS32) {
    std::cerr << "Only 32-bit ELF files are supported: " << filename << std::endl;
    return;
  }

  // Check ELF data encoding (little-endian or big-endian)
  if (elfHeader.e_ident[EI_DATA] != ELFDATA2LSB) {
    std::cerr << "Only little-endian ELF files are supported: " << filename << std::endl;
    return;
  }

  // Get the entry point address
  Elf32_Addr entryPoint = elfHeader.e_entry;
  pc = entryPoint;

  // Add more code here to load and work with program segments, sections, etc.
  file.close();

	return;
}

ELFLoader::~ELFLoader() {}

void ELFLoader::print_info() {
  std::cout << "PC: 0x" << std::hex << pc << std::endl;
}
