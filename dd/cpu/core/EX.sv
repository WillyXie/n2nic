// EX stage

module EX(
  input  logic          clk,
  input  logic          rst,

  input  logic          stall,
  // ID->EX
  input  logic  [31:0]  pc,
  input  logic  [31:0]  imm,
  input  logic  [2:0]   funct3,
  input  logic  [3:0]   aluop,
  input  logic  [4:0]   rd_i,
  input  logic  [31:0]  rs1_i,
  input  logic  [31:0]  rs2_i,
  // forwarding
  input  logic  [1:0]   forwardA,
  input  logic  [1:0]   forwardB,
  input  logic  [31:0]  rd_mem,
  input  logic  [31:0]  rd_wb,
  // control (write back)
  input  logic          reg_write_i,
  input  logic          mem_to_reg_i,
  // control (memory)
  input  logic          mem_write_i,
  input  logic          mem_read_i,
  input  logic  [1:0]   sel_alu,
  // control (execute)
  input  logic          op1src,
  input  logic          op2src,
  // branch control
  input  logic          branch,
  input  logic          jump,
  output logic          flush,
  
  // EX->MEM
  output logic          reg_write_o,
  output logic          mem_to_reg_o,
  output logic          mem_read_o,
  output logic  [2:0]   funct3_o,
  output logic  [3:0]   dm_web,
  output logic  [4:0]   rd_o,
  output logic  [31:0]  rs2_o,
  output logic  [31:0]  sel_result,
  output logic  [31:0]  branch_result
);

logic [31:0] op1;
logic [31:0] op2;

logic [31:0] alu_result;
logic [31:0] add_result;

// forwarding
logic [31:0] rs1_sel;
logic [31:0] rs2_sel;
assign rs1_sel = (forwardA[1]) ? rd_mem :
                 (forwardA[0]) ? rd_wb : rs1_i;
assign rs2_sel = (forwardB[1]) ? rd_mem :
                 (forwardB[0]) ? rd_wb : rs2_i;        

assign op1 = (op1src) ? pc  : rs1_sel ;
assign op2 = (op2src) ? imm : rs2_sel ;

// result mux
assign add_result = pc + 32'd4;   // AddSum
assign branch_result = (flush)? alu_result : add_result;

// SW or SB or SH
always_ff @(posedge clk) begin
  if (rst) begin
    dm_web <= 4'b1111;
  end
  else if(stall) begin
    dm_web <= dm_web;
  end
  else if(mem_write_i) begin
    if(funct3[1]) dm_web <= 4'b0000;
    else if(funct3[0]) begin
      dm_web <= (alu_result[1])? 4'b0011 : 4'b1100;
    end
    else begin
      case (alu_result[1:0])
        2'b00: dm_web <= 4'b1110;
        2'b01: dm_web <= 4'b1101;
        2'b10: dm_web <= 4'b1011;
        2'b11: dm_web <= 4'b0111;
      endcase
    end
  end
  else begin
    dm_web <= 4'b1111;
  end  
end

// EX/MEM
always_ff @(posedge clk) begin
  if (rst) begin
    reg_write_o   <= 1'b0;
    mem_to_reg_o  <= 1'b0;
    mem_read_o    <= 1'b0;
    rd_o          <= 5'd0;
    rs2_o         <= 32'd0;
    funct3_o      <= 3'd0;
    sel_result    <= 32'd0;
  end
  else if(stall) begin
    reg_write_o   <= reg_write_o;
    mem_to_reg_o  <= mem_to_reg_o;
    mem_read_o    <= mem_read_o;
    rd_o          <= rd_o;
    rs2_o         <= rs2_o;
    funct3_o      <= funct3_o;
    sel_result    <= sel_result;
  end
  else begin
    reg_write_o   <= reg_write_i;
    mem_to_reg_o  <= mem_to_reg_i;
    mem_read_o    <= mem_read_i;
    rd_o          <= rd_i;
    rs2_o         <= (funct3[1]) ? rs2_sel : ((funct3[0])?{(2){rs2_sel[15:0]}}:{(4){rs2_sel[7:0]}}); // SB or SH or SW
    funct3_o      <= funct3;
    sel_result    <= (sel_alu[1])? imm : ((sel_alu[0])? alu_result : add_result);
  end
end

// ============================================================
// ALU
ALU alu (
  .op1    (op1        ),
  .op2    (op2        ),
  .aluop  (aluop      ),
  .result (alu_result )
);
// Branch Control Unit
Branch bcu (
  .rs1      (rs1_sel    ),
  .rs2      (rs2_sel    ),
  .funct3   (funct3     ),
  .branch   (branch     ),
  .jump     (jump       ),
  .flush    (flush      )
);

endmodule

