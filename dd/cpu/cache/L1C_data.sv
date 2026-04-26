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

module L1C_data(
  input clk,
  input rst,
  // Core to CPU wrapper
  input [`DATA_BITS-1:0] core_addr,
  input core_req,
  input core_write,
  input [`DATA_BITS-1:0] core_in,
  input [`CACHE_TYPE_BITS-1:0] core_type,
  // Mem to CPU wrapper
  input [`DATA_BITS-1:0] D_out,
  input D_wait,
  // CPU wrapper to core
  output logic [`DATA_BITS-1:0] core_out,
  output core_wait,
  // CPU wrapper to Mem
  output logic D_req,
  output logic [`DATA_BITS-1:0] D_addr,
  output D_write,
  output [`DATA_BITS-1:0] D_in,
  output [`CACHE_TYPE_BITS-1:0] D_type
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
  logic [`DATA_BITS-1:0] Data_sel; 

  //--------------- complete this part by yourself -----------------//
  
  logic match;
  logic din_sel;
  logic dout_sel;
  logic ValidOut;
  logic [1:0] core_word;
  logic [`DATA_BITS-1:0] core_out_tmp;

  logic [`DATA_BITS-1:0] DAout_word;
  logic [`DATA_BITS-1:0] DAout_word_tmp;
  logic [`DATA_BITS-1:0] Dout_tmp;
  logic [`DATA_BITS-1:0] Dout_cpu;

  integer i;

  always_ff@(posedge clk) begin
    if(rst) begin
      Dout_tmp <= 32'd0;
      Dout_cpu <= 32'd0;
      DAout_word_tmp <= 32'd0;
      core_out <= 32'd0;
    end
    else begin
      Dout_tmp <= (D_wait)? D_out: Dout_tmp;
      Dout_cpu <= (D_wait && (core_addr == D_addr))? D_out: Dout_cpu;
      DAout_word_tmp <= DAout_word;
      core_out <= core_out_tmp;
    end
  end

  assign index = core_addr[9:4];
  assign core_word = core_addr[3:2];

  // To Tag Array
  assign TA_in    = core_addr[31:10];
  assign TA_read  = core_req;

  assign D_in   = core_in;

  assign D_type = core_type;
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

  control Control(
    // input
    .clk        (clk       ),
    .rst        (rst       ),
    .core_word  (core_word ),
    .core_req   (core_req  ),
    .core_write (core_write),
    .core_addr  (core_addr ),
    .match      (match     ),
    .valid      (ValidOut  ),
    .D_wait     (D_wait    ),
    // output
    .core_wait  (core_wait ),
    .D_req      (D_req     ),
    .D_write    (D_write   ),
    .D_addr     (D_addr    ),
    .din_sel    (din_sel   ),
    .dout_sel   (dout_sel  ),
    .DA_web     (DA_write  ),
    .DA_oe      (DA_read   ),
    .TA_write   (TA_write  ),
    .Valid_write(Valid_write),  
    .core_type  (core_type)
  );

  data_mux DinMux(
    .sel      (din_sel ),   // 1 from memory, 0 from core
    .Data1    (Dout_tmp),   // from memory
    .Data2    (core_in ),   // from core
    .Data_sel (Data_sel)
  );

  data_mux DoutMux(
    .sel      (dout_sel),   // 1 from memory, 0 from cache
    .Data1    (Dout_cpu),   // from memory
    .Data2    (DAout_word_tmp), // from cache
    .Data_sel (core_out_tmp)
  );

  //--------------- ------------------------------ -----------------//
  data_array_wrapper DA(
    .A  (index),
    .DO (DA_out),
    .DI (DA_in),
    .CK (clk),
    .WEB(DA_write),
    .OE (DA_read),
    .CS (1'b1)
  );
   
  tag_array_wrapper  TA(
    .A  (index),
    .DO (TA_out),
    .DI (TA_in),
    .CK (clk),
    .WEB(TA_write),
    .OE (TA_read),
    .CS (1'b1)
  );

endmodule

