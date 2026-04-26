`ifndef __TB_CORE__
`define __TB_CORE__

module tb_core (
  input logic clk,
  input logic rstn,

  input logic [63:0]  cyc_timeout,
  input logic [31:0]  eot_addr,

  input  logic          ext_interrupt,

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
  output logic          dm_oe
);

CPU core (
  .clk(clk),
  .rst(!rstn),

  .ext_interrupt  (ext_interrupt),

  .im_data        (im_data      ),
  .im_wait        (im_wait      ),
  .im_addr        (im_addr      ),

  .dm_rdata       (dm_rdata     ),
  .dm_wait        (dm_wait      ),
  .dm_wdata       (dm_wdata     ),
  .dm_addr        (dm_addr      ),
  .dm_web         (dm_web       ),
  .dm_oe          (dm_oe        )
);

watchdog wd (
  .clk          (clk),
  .rstn         (rstn),
  .cyc_timeout  (cyc_timeout)
);

import "DPI-C" function void sim_terminate (input int errCode);

always_ff @(posedge clk) begin : check_eot
  if (    rstn
      &&  dm_web==4'he
      &&  dm_addr==eot_addr) begin
    $display($sformatf("Detected EOT sequence, write to address: 0x%h", eot_addr));
    sim_terminate(0);
  end
end

endmodule // tb_core

`endif // __TB_CORE__

