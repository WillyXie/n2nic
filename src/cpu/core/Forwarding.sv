// Forwarding Unit

module Forwarding(
  // from EX
  input  logic  [4:0]  rs1_ex,
  input  logic  [4:0]  rs2_ex,
  // from MEM
  input  logic  [4:0]  rd_mem,
  input  logic         rd_write_mem,
  // from WB
  input  logic  [4:0]  rd_wb,
  input  logic         rd_write_wb,
  // control
  output logic  [1:0]  forwardA,
  output logic  [1:0]  forwardB
);

// ============================================================
always_comb begin
    if((rs1_ex == rd_mem) && (rd_mem != 5'd0) && rd_write_mem) 
        forwardA = 2'b10;
    else if(rs1_ex == rd_wb && (rd_wb != 5'd0) && rd_write_wb) 
        forwardA = 2'b01;
    else forwardA = 2'b00;

    if((rs2_ex == rd_mem) && (rd_mem != 5'd0) && rd_write_mem) 
        forwardB = 2'b10;
    else if(rs2_ex == rd_wb && (rd_wb != 5'd0) && rd_write_wb) 
        forwardB = 2'b01;
    else forwardB = 2'b00;
end

endmodule

