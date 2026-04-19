// Count 64 bit
module counter(
  input  logic        clk,
  input  logic        rst,
  input  logic        incr,
  input  logic [31:0] load_data,
  input  logic        load_low,
  input  logic        load_high,
  output logic [31:0] count_low,
  output logic [31:0] count_high
);

logic incr_high;
assign incr_high = (count_low == '1)? 1'b1 : 1'b0;

always_ff @(posedge clk) begin
  if (rst) begin
    count_low  <= 32'd0;
    count_high <= 32'd0;
  end
  else begin

    if (load_low) count_low <= load_data;
    else if (load_high) count_high <= load_data;
    else begin
      if (incr) begin
        count_low <= count_low + 1'b1;
      end

      if (incr_high) count_high <= count_high + 1'b1;
    end
  end
end

endmodule

