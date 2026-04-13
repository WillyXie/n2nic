// ID stage

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

module ID(
  input  logic          clk,
  input  logic          rst,

  input  logic          stall,
  input  logic          ID_flush,

  // IF->ID
  input  logic  [31:0]  pc_i,
  input  logic  [31:0]  instr,
  input  logic          im_valid,

  // WB->RF
  input  logic  [31:0]  wr_data,
  input  logic          wr_en,
  input  logic  [4:0]   wr_rd,

  // ID->EX
  output logic          instr_valid,
  output logic  [4:0]   rs1_o,
  output logic  [4:0]   rs2_o,
  output logic  [4:0]   rd_o,
  output logic  [31:0]  pc_o,
  output logic  [31:0]  imm_o,
  output logic  [3:0]   aluop_o,
  output logic  [31:0]  reg_rs1,
  output logic  [31:0]  reg_rs2,
  // control (write back)
  output logic          csr_valid,
  output logic          reg_write,
  output logic          mem_to_reg,
  // control (memory)
  output logic          mem_write,
  output logic          mem_read,
  output logic  [1:0]   sel_alu,
  // control (execute)
  output logic          op1src_o,
  output logic          op2src_o,
  output logic  [2:0]   funct3_o,
  output logic          branch_o,
  output logic          jump_o,

  // hazard
  output logic          load_stall
);

logic [6:0] opcode;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic [2:0] funct3;
logic [6:0] funct7;

logic [31:0] imm_i;
logic [31:0] imm_s;
logic [31:0] imm_b;
logic [31:0] imm_j;
logic [31:0] imm_u;

logic [3:0]  aluop;
logic        op1src;  // 1 for pc,  0 for rs1
logic        op2src;  // 1 for imm, 0 for rs2
logic [31:0] imm;

logic [1:0]  rd_src;  // rd result from alu (2'b01) or PC+4 (2'b00), or imm (2'b10)
logic        reg_wr;  // reg write
logic        load;
logic        store;
logic        branch;
logic        jump;

logic        flush;

logic        wreg_en; // if stall then don't save rd
assign wreg_en = (stall)? 1'b0 : wr_en;

assign flush = ID_flush || load_stall;
// ============================================================

//debug added wired
logic csr_instr;


// Decode
assign opcode = instr[6:0];
assign rs1    = instr[19:15];
assign rs2    = instr[24:20];
assign rd     = instr[11:7];
assign funct3 = instr[14:12];
assign funct7 = instr[31:25];

// Imm_Type
assign imm_i = {{(20){instr[31]}}, instr[31:20]};
assign imm_s = {{(20){instr[31]}}, instr[31:25], instr[11:7]};
assign imm_b = {{(20){instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
assign imm_j = {{(12){instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
assign imm_u = {instr[31:12], 12'd0};

always_comb begin
  aluop  = 4'd0;  // ADD
  op1src = 1'd0;
  op2src = 1'd1;
  imm    = 32'd0;
  rd_src = 2'b01;
  reg_wr = 1'd1;
  load   = 1'd0;
  store  = 1'd0;
  branch = 1'd0;
  jump   = 1'd0;
  csr_instr = 1'b0;

  case (opcode)
    `OpcodeOp: begin
      aluop = {funct7[5], funct3};
      op2src = 1'b0;
    end
    `OpcodeOpImm: begin
      aluop = (funct3 == 3'b001 || funct3 == 3'b101)?{funct7[5], funct3}:{1'b0, funct3};
      imm = imm_i;
    end
    `OpcodeLoad: begin
      imm = imm_i;
      load = 1'b1;
    end
    `OpcodeJalr: begin
      imm = imm_i;
      rd_src = 2'b00;
      jump = 1'b1;
    end
    `OpcodeStore: begin
      imm = imm_s;
      reg_wr = 1'b0;
      store = 1'b1;
    end
    `OpcodeBranch: begin
      op1src = 1'b1;
      imm = imm_b; 
      reg_wr = 1'b0;
      branch = 1'b1;
    end
    `OpcodeJal: begin
      op1src = 1'b1;
      imm = imm_j;
      rd_src = 2'b00;
      jump = 1'b1;
    end
    `OpcodeLui: begin
      imm = imm_u;  
      rd_src = 2'b10;
    end
    `OpcodeAuipc: begin
      op1src = 1'b1;
      imm = imm_u;
    end
    `OpcodeCsr: begin
      csr_instr = 1'b1;
      imm = imm_i;
    end
  endcase
end

// ID/EXE
always_ff @(posedge clk) begin
  if(flush || rst) begin
    rs1_o       <= 5'd0;
    rs2_o       <= 5'd0;
    rd_o        <= 5'd0;
    pc_o        <= 32'd0;
    imm_o       <= 32'd0;
    aluop_o     <= 4'd0;
    op1src_o    <= 1'b0;
    op2src_o    <= 1'b0;
    csr_valid   <= 1'b0;
    reg_write   <= 1'b0;
    mem_to_reg  <= 1'b0;
    mem_write   <= 1'b0;
    mem_read    <= 1'b0;
    sel_alu     <= 2'd0;
    funct3_o    <= 3'd0;
    branch_o    <= 1'b0;
    jump_o      <= 1'b0;
    instr_valid <= 1'b0;      
  end
  else if(stall) begin
    rs1_o       <= rs1_o;
    rs2_o       <= rs2_o;
    rd_o        <= rd_o;
    pc_o        <= pc_o;
    imm_o       <= imm_o;
    aluop_o     <= aluop_o;
    op1src_o    <= op1src_o;
    op2src_o    <= op2src_o;
    csr_valid   <= csr_valid;
    reg_write   <= reg_write;
    mem_to_reg  <= mem_to_reg;
    mem_write   <= mem_write;
    mem_read    <= mem_read;
    sel_alu     <= sel_alu;
    funct3_o    <= funct3_o;
    branch_o    <= branch_o;
    jump_o      <= jump_o;
    instr_valid <= instr_valid;   
  end
  else begin
    rs1_o       <= rs1;
    rs2_o       <= rs2;
    rd_o        <= rd;
    pc_o        <= pc_i;
    imm_o       <= imm;
    aluop_o     <= aluop;
    op1src_o    <= op1src;
    op2src_o    <= op2src;
    csr_valid   <= csr_instr;
    reg_write   <= reg_wr;
    mem_to_reg  <= load;
    mem_write   <= store;
    mem_read    <= load;
    sel_alu     <= rd_src;
    funct3_o    <= funct3;
    branch_o    <= branch;
    jump_o      <= jump;
    instr_valid <= im_valid;    
  end
end
// ============================================================
// RF
RF reg00 (
  .clk      (clk      ),
  .rst      (rst      ),
  .rs1      (rs1      ),
  .rs2      (rs2      ),
  .reg_rs1  (reg_rs1  ),
  .reg_rs2  (reg_rs2  ),
  .wr_rd    (wr_rd    ),
  .wr_data  (wr_data  ),
  .wr_en    (wreg_en  )
);
// Hazard Detect Unit
Hazard hdu (
  .rs1_id         (rs1          ),
  .rs2_id         (rs2          ),
  .rd_ex          (rd_o         ),
  .mem_read_ex    (mem_read     ),
  .load_stall     (load_stall   )
);

endmodule

