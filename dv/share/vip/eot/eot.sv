`ifndef __EOT__
`define __EOT__

module eot #() (
  input logic clk,
  input logic rstn,

  output logic eot
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

endmodule // eot

`endif // __EOT__

