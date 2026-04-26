`ifndef __WATCHDOG__
`define __WATCHDOG__

module watchdog #() (
  input logic clk,
  input logic rstn,

  input   logic [63:0]  cyc_timeout,
  output  logic [63:0]  cyc_ref
);

always_ff @(posedge clk) begin : count_cyc_ref
  if (!rstn) begin
    cyc_ref <= 64'b0;
  end
  else begin
    cyc_ref <= cyc_ref + 64'b1;
  end
end

property a_timeout;
  @(posedge clk) (rstn && (cyc_ref>=cyc_timeout));
endproperty
assert property (a_timeout) begin
  $display($sformatf("Current cycle: %d", cyc_ref));
  $display($sformatf("Timeout cycle: %d", cyc_timeout));
  $fatal(2, "Simulation has reached timeout limit");
end

endmodule // watchdog

`endif // __WATCHDOG__

