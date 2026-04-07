// WB stage

module WB(
  input  logic          clk,
  input  logic          rst,

  // MEM->WB
  input  logic          reg_write_i,
  input  logic          mem_to_reg,
  input  logic  [31:0]  r_data,
  input  logic  [31:0]  sel_result,
  input  logic  [4:0]   rd_i,
  // CSR
  input  logic          csr_valid,
  input  logic  [31:0]  csr_data,
  input  logic          regwr_csr,

  // WB ->RF
  output logic          reg_write_o,
  output logic  [31:0]  wreg_data,
  output logic  [4:0]   rd_o
);

// ============================================================
assign reg_write_o = (csr_valid)? regwr_csr : reg_write_i;
assign rd_o = rd_i;
assign wreg_data = (csr_valid)? csr_data :
                   (mem_to_reg)? r_data : sel_result ;

endmodule

