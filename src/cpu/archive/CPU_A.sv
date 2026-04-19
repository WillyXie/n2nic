// CPU top

module CPU_A(
  input  logic          clk,
  input  logic          rst,
  input  logic          ext_interrupt,
  input  logic          int_interrupt_I,
  // Instr Mem
  input  logic  [31:0]  im_data,
  input  logic          im_wait,
  output logic  [31:0]  im_addr,

  // Data Mem
  input  logic  [31:0]  dm_rdata,
  input  logic          dm_wait,
  output logic  [31:0]  dm_wdata,
  output logic  [31:0]  dm_addr,
  output logic  [3:0]   dm_web,
  output logic          dm_oe,
  output logic          int_interrupt_O
);

// IF -> ID
logic [31:0] pc_if_id;
logic [31:0] npc;
logic [31:0] instr;

// ID -> EX
logic [4:0]  rs1;
logic [4:0]  rs2;
logic [4:0]  rd_id_ex;
logic [31:0] pc_id_ex;
logic [31:0] imm;
logic [3:0]  aluop;
logic [31:0] reg_rs1;
logic [31:0] reg_rs2;
logic        reg_write_ie;
logic        mem_to_reg;
logic        mem_write;
logic        mem_read;
logic [1:0]  sel_alu;
logic        op1src;
logic        op2src;
logic [2:0]  funct3;
logic        branch;
logic        jump;
logic        instr_valid;

// EX -> MEM
logic [2:0]  funct3_em;
logic [4:0]  rd_ex_mem;
logic [31:0] sel_result_em;
logic        reg_write_em;
logic        mem_to_reg_em;

// MEM -> WB
logic [31:0] sel_result_mw;
logic [31:0] r_data;
logic [4:0]  rd_mem_wb;
logic        reg_write_mw;
logic        mem_to_reg_mw;

// WB -> RF
logic        reg_write;
logic [31:0] wr_data;
logic [4:0]  wr_rd;

// Forwarding
logic [1:0]  forwardA;
logic [1:0]  forwardB;

// CSR
logic [31:0] csr_data;
logic        regwr_csr;
logic        csr_valid;
logic        csr_valid_o;
logic [31:0] csr_data_mw;
logic        regwr_csr_mw;
logic        csr_valid_mw;

logic        wfi_stall;
logic        trap_jump;
logic [31:0] trap_addr;
// Branch taken
logic        flush;
logic [31:0] branch_result;
// Stall
logic        d_stall;
logic        cpu_stall;
logic        load_stall;

assign cpu_stall = d_stall || wfi_stall;

assign im_addr = npc[31:0];
assign dm_addr = sel_result_em[31:0];

//assign d_stall = (((dm_web != 4'd15) && dm_wait ) || ( dm_oe && dm_wait ))? 1'b1 : 1'b0;
d_stall_control d_stall0(
  .clk      (clk        ),
  .rst      (rst        ),
  .dm_web   (dm_web     ),
  .dm_oe    (dm_oe      ),
  .dm_wait  (dm_wait    ),
  .d_stall  (d_stall    )
);

logic im_valid;
assign instr = (im_valid)? im_data : 32'd19; // 32'd19 -> NOP

im_valid_control im_valid0(
  .clk      (clk        ),
  .rst      (rst        ),
  .im_wait  (im_wait    ),
  .im_valid (im_valid   )
);

IF if_stage (
  .clk            (clk          ),
  .rst            (rst          ),
  .branch_result  (branch_result),
  .branch         (flush        ),
  .trap_jump      (trap_jump    ),
  .trap_addr      (trap_addr    ),
  .load_stall     (load_stall   ),
  .cpu_stall      (cpu_stall    ),
  .pc             (pc_if_id     ),
  .im_valid       (im_valid     ),
  .npc            (npc          )
);

ID id_stage (
  .clk            (clk          ),
  .rst            (rst          ),
  .stall          (cpu_stall    ),
  .ID_flush       (flush||trap_jump),
  // input from IF
  .pc_i           (pc_if_id     ),
  .instr          (instr        ),
  .im_valid       (im_valid     ),
  // input from WB
  .wr_data        (wr_data      ),
  .wr_en          (reg_write    ),
  .wr_rd          (wr_rd        ),
  // output to EX
  .instr_valid    (instr_valid  ),
  .rs1_o          (rs1          ),
  .rs2_o          (rs2          ),
  .rd_o           (rd_id_ex     ),
  .pc_o           (pc_id_ex     ),
  .imm_o          (imm          ),
  .aluop_o        (aluop        ),
  .reg_rs1        (reg_rs1      ),
  .reg_rs2        (reg_rs2      ),
  // output control
  .csr_valid      (csr_valid    ),
  .reg_write      (reg_write_ie ),
  .mem_to_reg     (mem_to_reg   ),
  .mem_write      (mem_write    ),
  .mem_read       (mem_read     ),
  .sel_alu        (sel_alu      ),
  .op1src_o       (op1src       ),
  .op2src_o       (op2src       ),
  .funct3_o       (funct3       ),
  .branch_o       (branch       ),
  .jump_o         (jump         ),
  .load_stall     (load_stall   )
);

EX ex_stage (
  .clk            (clk          ),
  .rst            (rst          ),
  .stall          (cpu_stall    ),
  .pc             (pc_id_ex     ),
  .imm            (imm          ),
  .aluop          (aluop        ),
  .rd_i           (rd_id_ex     ),
  .rs1_i          (reg_rs1      ),
  .rs2_i          (reg_rs2      ),
  .forwardA       (forwardA     ),
  .forwardB       (forwardB     ),
  .rd_mem         (sel_result_em),
  .rd_wb          (wr_data      ),
  .reg_write_i    (reg_write_ie ),
  .mem_to_reg_i   (mem_to_reg   ),
  .mem_write_i    (mem_write    ),
  .mem_read_i     (mem_read     ),
  .sel_alu        (sel_alu      ),  
  .op1src         (op1src       ),
  .op2src         (op2src       ),
  .funct3         (funct3       ),  
  .branch         (branch       ),
  .jump           (jump         ),
  .flush          (flush        ),
  .reg_write_o    (reg_write_em ),
  .mem_to_reg_o   (mem_to_reg_em),
  .mem_read_o     (dm_oe        ),
  .funct3_o       (funct3_em    ),    
  .dm_web         (dm_web       ),
  .rd_o           (rd_ex_mem    ),
  .rs2_o          (dm_wdata     ),
  .sel_result     (sel_result_em),
  .branch_result  (branch_result)
);

MEM mem_stage (
  .clk            (clk          ),
  .rst            (rst          ),
  .stall          (cpu_stall    ),
  .funct3         (funct3_em    ),
  .rd_i           (rd_ex_mem    ),
  .sel_result_i   (sel_result_em),
  .dm_rdata       (dm_rdata     ),
  .reg_write_i    (reg_write_em ),
  .mem_to_reg_i   (mem_to_reg_em),
  // output
  .reg_write_o    (reg_write_mw ),
  .mem_to_reg_o   (mem_to_reg_mw),
  .sel_result_o   (sel_result_mw),
  .dm_rdata_o     (r_data       ),
  .rd_o           (rd_mem_wb    ),
  // csr 
  .csr_valid      (csr_valid_o  ),
  .csr_data       (csr_data     ),
  .regwr_csr      (regwr_csr    ),
  .csr_valid_o    (csr_valid_mw ),
  .csr_data_o     (csr_data_mw  ),
  .regwr_csr_o    (regwr_csr_mw )
);

WB wb_stage (
  .clk            (clk          ),
  .rst            (rst          ),
  // input
  .reg_write_i    (reg_write_mw ),
  .mem_to_reg     (mem_to_reg_mw),
  .r_data         (r_data       ),
  .sel_result     (sel_result_mw),
  .rd_i           (rd_mem_wb    ),
  // csr 
  .csr_valid      (csr_valid_mw ),
  .csr_data       (csr_data_mw  ),
  .regwr_csr      (regwr_csr_mw ),
  // output
  .reg_write_o    (reg_write    ),
  .wreg_data      (wr_data      ),
  .rd_o           (wr_rd        )
);

Forwarding fwu (
  .rs1_ex         (rs1          ),
  .rs2_ex         (rs2          ),
  .rd_mem         (rd_ex_mem    ),
  .rd_write_mem   (reg_write_em ),
  .rd_wb          (rd_mem_wb    ),
  .rd_write_wb    (reg_write_mw ),
  .forwardA       (forwardA     ),
  .forwardB       (forwardB     )
);

CSR_A csr (
  .clk            (clk            ),
  .rst            (rst            ),
  .ext_interrupt  (ext_interrupt  ),
  .int_interrupt_I(int_interrupt_I),
  .stall          (d_stall        ),
  // input from ID/EXE stage
  .funct3         (funct3         ),
  .rd             (rd_id_ex       ),
  .uimm           (rs1            ),
  .addr           (imm[11:0]      ), // use imm_i type
  .pc             (pc_id_ex       ),
  .reg_rs1        (reg_rs1        ),
  .csr_valid      (csr_valid      ),
  .instr_valid    (instr_valid    ),
  // output to MEM/WB
  .csr_data       (csr_data       ),
  .regwr_csr      (regwr_csr      ),
  .csr_valid_o    (csr_valid_o    ),
  // interrupt
  .trap_jump      (trap_jump      ),
  .trap_addr      (trap_addr      ),
  .wfi_stall      (wfi_stall      ),
  .int_interrupt_O(int_interrupt_O)
);

endmodule

