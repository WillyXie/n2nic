`ifndef __TB_BASE__
`define __TB_BASE__

module tb_base (
  input logic clk,
  input logic rstn,

  input logic [63:0] cyc_timeout
);

watchdog wd (
  .clk          (clk),
  .rstn         (rstn),
  .cyc_timeout  (cyc_timeout)
);

endmodule // tb_base

`endif // __TB_BASE__

