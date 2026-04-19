// IF stage
module IF(
  input                 clk,
  input                 rst,
  // Branch & jump
  input         [31:0]  branch_result,
  input                 branch,
  // trap 
  input                 trap_jump,
  input         [31:0]  trap_addr,

  // Stall
  input                 load_stall,
  input                 cpu_stall,
  // IF->ID stage
  output logic  [31:0]  pc,
  // Instr mem
  input                 im_valid,
  output logic  [31:0]  npc
);

// ============================================================
// Program Counter (PC) Generation
logic reset;
always_ff@(posedge clk) begin
  if(rst)
    reset <= 1'b1;
  else
    reset <= 1'b0;
end

logic stall;
assign stall = load_stall || (!im_valid);

assign npc = reset ? 32'd0 : (
             trap_jump ? trap_addr : (
             branch ? branch_result : (
             stall ? pc : (pc+32'd4)
             )));

always_ff@(posedge clk) begin
    if(rst) pc <= 32'd0;
    else if(cpu_stall) pc <= pc;
    else pc <= npc;
end

// ============================================================

endmodule

