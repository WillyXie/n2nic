`define CACHE_TAG_BITS 22

module comparator(
    input [`CACHE_TAG_BITS-1:0] tag1,
    input [`CACHE_TAG_BITS-1:0] tag2,
    output match
);

assign match = (tag1==tag2)? 1'b1 : 1'b0;

endmodule

