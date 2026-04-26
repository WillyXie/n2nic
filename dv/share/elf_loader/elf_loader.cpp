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

  for (int i = 0; i < elfHeader.e_phnum; i++) {
    file.seekg(elfHeader.e_phoff + i * sizeof(Elf32_Phdr));

    Elf32_Phdr programHeader;
    file.read(reinterpret_cast<char*>(&programHeader), sizeof(Elf32_Phdr));

    // Check if this is a loadable segment
    if (programHeader.p_type == PT_LOAD) {
        // Save flags, address, and size
        Elf32_Word  flags = programHeader.p_flags;
        Elf32_Addr  addr = programHeader.p_vaddr;
        Elf32_Xword size = programHeader.p_memsz;
        //std::cout << "Flags: 0x" << std::hex << flags << std::endl;
        //std::cout << "Addr: 0x" << std::hex << addr << std::endl;
        //std::cout << "Size: 0x" << std::hex << size << std::endl;

        // Seek to the segment's file offset
        file.seekg(programHeader.p_offset);

        // Read the segment data to memory
        data_s temp;
        temp.addr = addr;
        temp.size = size;
        uint32_t* dataTmp = new uint32_t[size];
        file.read(reinterpret_cast<char*>(dataTmp), size);
        temp.data = dataTmp;
        datas.push_back(temp);
        //file.read(reinterpret_cast<char*>(ALISS::memory + addr), size);
    }
  }

  file.close();

	return;
}

ELFLoader::~ELFLoader() {}

void ELFLoader::print_info() {
  std::cout << "PC: 0x" << std::hex << pc << std::endl;
  for(auto data : datas) {
    //std::cout << "Flags: 0x" << std::hex << flags << std::endl;
    std::cout << "Addr: 0x" << std::hex << data.addr << std::endl;
    std::cout << "Size: 0x" << std::hex << data.size << std::endl;
    //for (size_t i = 0; i*4 < data.size; i++) {
    //  std::cout << "0x" << std::hex << data.data[i] << std::endl;
    //}
  }
}
