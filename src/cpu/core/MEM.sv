// MEM stage

module MEM(
  input  logic          clk,
  input  logic          rst,

  input  logic          stall,
  // EX->MEM
  input  logic  [2:0]   funct3,
  input  logic  [4:0]   rd_i,
  input  logic  [31:0]  sel_result_i,
  input  logic  [31:0]  dm_rdata,

  // control (write back)
  input  logic          reg_write_i,
  input  logic          mem_to_reg_i,

  // CSR
  input  logic          csr_valid,
  input  logic  [31:0]  csr_data,
  input  logic          regwr_csr,

  output logic          csr_valid_o,
  output logic  [31:0]  csr_data_o,
  output logic          regwr_csr_o,

  // MEM->WB
  output logic          reg_write_o,
  output logic          mem_to_reg_o,
  output logic  [31:0]  sel_result_o,
  output logic  [31:0]  dm_rdata_o,

  output logic  [4:0]   rd_o
);

logic [2:0] funct3_q;

always_comb begin
  case(funct3_q)
    3'b000: begin    // LB
      case(sel_result_o[1:0])
        2'b00 : dm_rdata_o = {{(24){dm_rdata[7]}}, dm_rdata[7:0]};
        2'b01 : dm_rdata_o = {{(24){dm_rdata[15]}}, dm_rdata[15:8]};
        2'b10 : dm_rdata_o = {{(24){dm_rdata[23]}}, dm_rdata[23:16]};
        2'b11 : dm_rdata_o = {{(24){dm_rdata[31]}}, dm_rdata[31:24]};
      endcase
    end
    3'b001: begin    // LH         
      case(sel_result_o[1])                              
        1'b1: dm_rdata_o = {{(16){dm_rdata[31]}}, dm_rdata[31:16]};
        1'b0: dm_rdata_o = {{(16){dm_rdata[15]}}, dm_rdata[15:0]};
      endcase
    end
    3'b010: dm_rdata_o = dm_rdata;  // LW
    3'b100: begin    // LBU
      case(sel_result_o[1:0])
        2'b00 : dm_rdata_o = {24'd0, dm_rdata[7:0]};
        2'b01 : dm_rdata_o = {24'd0, dm_rdata[15:8]};
        2'b10 : dm_rdata_o = {24'd0, dm_rdata[23:16]};
        2'b11 : dm_rdata_o = {24'd0, dm_rdata[31:24]};
      endcase
     end
    3'b101: begin    // LHU
      case(sel_result_o[1])
        1'b1: dm_rdata_o = {16'd0, dm_rdata[31:16]};
        1'b0: dm_rdata_o = {16'd0, dm_rdata[15:0]};
      endcase
    end
    default: dm_rdata_o = 32'd0;
  endcase
end

// MEM/WB
always_ff @(posedge clk) begin
  if(rst) begin
    funct3_q      <= 3'd0;
    reg_write_o   <= 1'b0;
    mem_to_reg_o  <= 1'b0;
    rd_o          <= 5'd0;
    sel_result_o  <= 32'd0;
    csr_valid_o   <= 1'b0;
    csr_data_o    <= 32'd0;
    regwr_csr_o   <= 1'b0;
  end
  else if(stall) begin
    funct3_q      <= funct3_q;
    reg_write_o   <= reg_write_o;
    mem_to_reg_o  <= mem_to_reg_o;
    rd_o          <= rd_o;
    sel_result_o  <= sel_result_o;
    csr_valid_o   <= csr_valid_o;
    csr_data_o    <= csr_data_o;
    regwr_csr_o   <= regwr_csr_o;
  end
  else begin
    funct3_q      <= funct3;
    reg_write_o   <= reg_write_i;
    mem_to_reg_o  <= mem_to_reg_i;
    rd_o          <= rd_i;
    sel_result_o  <= sel_result_i;
    csr_valid_o   <= csr_valid;
    csr_data_o    <= csr_data;
    regwr_csr_o   <= regwr_csr;
  end
end

endmodule

