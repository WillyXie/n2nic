`define DATA_BITS 32

module data_mux(
    input sel,
    input [`DATA_BITS-1:0] Data1,
    input [`DATA_BITS-1:0] Data2,
    output [`DATA_BITS-1:0] Data_sel 
);

    assign Data_sel = (sel)? Data1: Data2;

endmodule

