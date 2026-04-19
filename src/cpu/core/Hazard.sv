// Hazard Detection

module Hazard(
  // from ID
  input  logic  [4:0]  rs1_id,
  input  logic  [4:0]  rs2_id,
  // from EX
  input  logic  [4:0]  rd_ex,
  input  logic         mem_read_ex,

  // stall
  output logic         load_stall
);

// ============================================================
// Load-Use Hazard
always_comb begin
    if (mem_read_ex && ((rd_ex == rs1_id)||(rd_ex == rs2_id)) ) begin
        load_stall = 1'b1;
    end
    else begin
        load_stall = 1'b0;
    end
end

endmodule

