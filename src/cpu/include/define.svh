`ifndef DEF_SVH
`define DEF_SVH

// CPU
`define DATA_BITS 32

// Cache
`define CACHE_BLOCK_BITS 2
`define CACHE_INDEX_BITS 6
`define CACHE_TAG_BITS 22
`define CACHE_DATA_BITS 128
`define CACHE_LINES 2**(`CACHE_INDEX_BITS)
`define CACHE_WRITE_BITS 16
`define CACHE_TYPE_BITS 3
`define CACHE_BYTE `CACHE_TYPE_BITS'b000
`define CACHE_HWORD `CACHE_TYPE_BITS'b001
`define CACHE_WORD `CACHE_TYPE_BITS'b010
`define CACHE_BYTE_U `CACHE_TYPE_BITS'b100
`define CACHE_HWORD_U `CACHE_TYPE_BITS'b101

// ESI status
`define status_E 2'b10
`define status_I 2'b00
`define status_S 2'b01

// Arbitor
`define ARB_IDLE 2'b00
`define CACHE_A  2'b01
`define CACHE_B  2'b10

//Read Write data length
`define WRITE_LEN_BITS 2
`define BYTE `WRITE_LEN_BITS'b00
`define HWORD `WRITE_LEN_BITS'b01
`define WORD `WRITE_LEN_BITS'b10

// Opcode
`define OpcodeOp     7'b0110011
`define OpcodeOpImm  7'b0010011
`define OpcodeLoad   7'b0000011
`define OpcodeStore  7'b0100011
`define OpcodeJal    7'b1101111
`define OpcodeJalr   7'b1100111
`define OpcodeBranch 7'b1100011
`define OpcodeLui    7'b0110111
`define OpcodeAuipc  7'b0010111
`define OpcodeCsr    7'b1110011

// Aluop
`define AluopAdd     4'b0000
`define AluopSub     4'b1000
`define AluopSll     4'b0001
`define AluopSlt     4'b0010
`define AluopSltu    4'b0011
`define AluopXor     4'b0100
`define AluopSrl     4'b0101
`define AluopSra     4'b1101
`define AluopOr      4'b0110
`define AluopAnd     4'b0111

`endif

