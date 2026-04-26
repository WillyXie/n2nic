`define CACHE_BLOCK_BITS 2
`define CACHE_INDEX_BITS 6
`define CACHE_TAG_BITS 22
`define CACHE_DATA_BITS 128
`define CACHE_LINES 2**(`CACHE_INDEX_BITS)
`define CACHE_WRITE_BITS 16
`define CACHE_TYPE_BITS 3
`define CACHE_BYTE `CACHE_TYPE_BITS'b000
`define CACHE_HWORD `CACHE_TYPE_BITS'b001
`define CACHE_WORD `CACHE_TYPE_BITS'b010
`define CACHE_BYTE_U `CACHE_TYPE_BITS'b100
`define CACHE_HWORD_U `CACHE_TYPE_BITS'b101
`define DATA_BITS 32

module L1C_inst(
  input clk,
  input rst,
  // Core to CPU wrapper
  input [`DATA_BITS-1:0] core_addr,
  input core_req,
  input core_write,
  input [`DATA_BITS-1:0] core_in,
  input [`CACHE_TYPE_BITS-1:0] core_type,
  // Mem to CPU wrapper
  input [`DATA_BITS-1:0] I_out,
  input I_wait,
  // CPU wrapper to core
  output logic [`DATA_BITS-1:0] core_out,
  output core_wait,
  // CPU wrapper to Mem
  output logic I_req,
  output logic [`DATA_BITS-1:0] I_addr,
  output I_write,
  output [`DATA_BITS-1:0] I_in,
  output [`CACHE_TYPE_BITS-1:0] I_type
);

  logic [`CACHE_INDEX_BITS-1:0] index;
  logic [`CACHE_DATA_BITS-1:0] DA_out;
  logic [`CACHE_DATA_BITS-1:0] DA_in;
  logic [`CACHE_WRITE_BITS-1:0] DA_write;
  logic DA_read;
  logic [`CACHE_TAG_BITS-1:0] TA_out;
  logic [`CACHE_TAG_BITS-1:0] TA_in;
  logic TA_write;
  logic TA_read;
  logic [`CACHE_LINES-1:0] valid;

  //--------------- complete this part by yourself -----------------//
  logic match;
  logic din_sel;
  logic dout_sel;
  logic ValidOut;
  logic [1:0] core_word;

  logic [`DATA_BITS-1:0] Data_sel; 
  logic [`DATA_BITS-1:0] DAout_word;
  logic [`DATA_BITS-1:0] DAout_word_tmp;
  logic [`DATA_BITS-1:0] Iout_tmp;
  logic [`DATA_BITS-1:0] Iout_cpu;

  integer i;

  always_ff@(posedge clk) begin
    if(rst) begin
      Iout_tmp <= 32'd0;
      Iout_cpu <= 32'd0;
      DAout_word_tmp <= 32'd0;
    end
    else begin
      Iout_tmp <= (I_wait)? Iout_tmp: I_out;
      Iout_cpu <= (~I_wait && (core_addr == I_addr))? I_out: Iout_cpu;
      DAout_word_tmp <= DAout_word;
    end
  end

  assign index = core_addr[9:4];
  assign core_word = core_addr[3:2];

  // To Tag Array
  assign TA_in    = core_addr[31:10];
  assign TA_read  = core_req;

  assign I_in   = core_in;

  assign I_type = core_type;
  assign DAout_word = (core_word==2'b11)? DA_out[127:96]:
                      (core_word==2'b10)? DA_out[95:64]:
                      (core_word==2'b01)? DA_out[63:32]: DA_out[31:0];

  assign DA_in = {Data_sel, Data_sel, Data_sel, Data_sel};
  
  //--------------- ------------------------------ -----------------//

  logic Valid_write;
  // valid array
  always_ff@(posedge clk) begin
    if(Valid_write && !rst)begin
      valid[index] = 1'b1;
    end
    else if(rst)begin
      //foreach(valid[i]) begin
      //  valid[i] = 1'b0;
      //end
      valid = 'b0;
    end
  end

  assign ValidOut = valid[index];

  //--------------- ------------------------------ -----------------//
  comparator Compare(
    .tag1    (TA_in ),
    .tag2    (TA_out),
    .match   (match )
  );

  control_inst Control(
    // input
    .clk        (clk       ),
    .rst        (rst       ),
    .core_word  (core_word ),
    .core_req   (core_req  ),
    .core_write (core_write),
    .core_addr  (core_addr ),
    .match      (match     ),
    .valid      (ValidOut  ),
    .D_wait     (I_wait    ),
    // output
    .core_wait  (core_wait ),
    .D_req      (I_req     ),
    .D_write    (I_write   ),
    .D_addr     (I_addr    ),
    .din_sel    (din_sel   ),
    .dout_sel   (dout_sel  ),
    .DA_web     (DA_write  ),
    .DA_oe      (DA_read   ),
    .TA_write   (TA_write  )
    //.Valid_write(Valid_write)
  );

  data_mux DinMux(
    .sel      (din_sel ),   // 1 from memory, 0 from core
    .Data1    (Iout_tmp),   // from memory
    .Data2    (core_in ),   // from core
    .Data_sel (Data_sel)
  );

  data_mux DoutMux(
    .sel      (dout_sel),   // 1 from memory, 0 from cache
    .Data1    (Iout_cpu),   // from memory
    .Data2    (DAout_word_tmp), // from cache
    .Data_sel (core_out)
  );  

  //--------------- ------------------------------ -----------------//
  data_array_wrapper DA(
    .A(index),
    .DO(DA_out),
    .DI(DA_in),
    .CK(clk),
    .WEB(DA_write),
    .OE(DA_read),
    .CS(1'b1)
  );
   
  tag_array_wrapper  TA(
    .A(index),
    .DO(TA_out),
    .DI(TA_in),
    .CK(clk),
    .WEB(TA_write),
    .OE(TA_read),
    .CS(1'b1)
  );

endmodule

