// Registers File
module RF(
  input  logic          clk,
  input  logic          rst,

  // Read
  input  logic  [4:0]   rs1,
  input  logic  [4:0]   rs2,
  output logic  [31:0]  reg_rs1,
  output logic  [31:0]  reg_rs2,
  // Write
  input  logic  [4:0]   wr_rd,
  input  logic  [31:0]  wr_data,
  input  logic          wr_en

);

logic [31:0] REGF [32];

// Read
always_ff @(posedge clk) begin
  if(rst) begin
    // initialize
    //foreach(REG[i]) begin
    //  REG[i] <= 32'd0;
    //end
    for (int i = 0; i < $size(REGF); i++) begin
      REGF[i] <= 'd0;
    end
  end
  else begin
    // rs1
    if (rs1 == 5'd0) reg_rs1 <= 32'd0;
    else if ((rs1 == wr_rd) && wr_en) reg_rs1 <= wr_data;
    else reg_rs1 <= REGF[rs1];

    // rs2
    if (rs2 == 5'd0) reg_rs2 <= 32'd0;
    else if ((rs2 == wr_rd) && wr_en) reg_rs2 <= wr_data;
    else reg_rs2 <= REGF[rs2];

    // write
    if(wr_en) REGF[wr_rd] <= wr_data;
  end
end

endmodule

