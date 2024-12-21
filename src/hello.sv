module HELLO (
  input wire clk,
  output wire out
);
  assign out = ~clk;
endmodule

`timescale 1ns/100ps
`define CLK 10

module tb;
  logic clk;
  wire out;
  integer idx;

  HELLO hello(clk, out);

  initial
  begin
    $display("Hello world");

    clk = 1'b0;
    for(idx=0; idx<10; idx=idx+1) begin
      # `CLK
      clk = ~clk;
    end
    $finish;
  end

  initial
  begin
    $dumpfile("hello.vcd");
    $dumpvars(0, hello);
  end
endmodule

