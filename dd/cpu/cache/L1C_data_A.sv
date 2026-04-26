
module L1C_data_A(
  input clk,
  input rst,
  // Core to L1 cache
  input [`DATA_BITS-1:0] core_addr,
  input core_req,
  input core_write,
  input [`DATA_BITS-1:0] core_in,
  input [`CACHE_TYPE_BITS-1:0] core_type,

  // L1 cache to core
  output logic [`DATA_BITS-1:0] core_out,
  output core_wait,
  
  //arbitor to L1 cache
  //input ARB_wait,
  input ARB_do_snp,
  input ARB_write_I,
  input [1:0] ARB_grant,
  input [1:0] ARB_status_I,
  input [`DATA_BITS-1:0] ARB_addr_I,

  //L2 cache to L1 cache
  input Icache_wait,
  input [`CACHE_DATA_BITS-1:0] L2_DataIn, 
  
  // L1 cache to arbitor
  output logic ARB_req,
  output logic ARB_write_O,
  output logic [1:0] ARB_status_O,
  output logic [`DATA_BITS-1:0] ARB_out,
  output logic [`DATA_BITS-1:0] ARB_addr_O,
  output logic [`CACHE_TYPE_BITS-1:0] ARB_type,

  //from another L1 cache
  input snp_hit_I,
  input snp_hit_valid_I,
  
  //to another L1 cache
  output logic snp_hit_O,
  output logic snp_hit_valid_O

);

  logic [`CACHE_INDEX_BITS-1:0] index;
  logic [`CACHE_DATA_BITS-1:0]  DA_out;
  logic [`CACHE_DATA_BITS-1:0]  DA_in;
  logic [`CACHE_WRITE_BITS-1:0] DA_write;
  logic DA_read;
  logic [`CACHE_TAG_BITS-1:0] TA_out;
  logic [`CACHE_TAG_BITS-1:0] TA_in;
  logic TA_write;
  logic TA_read;
  logic [1:0] status_array [`CACHE_LINES-1:0];

  //--------------- complete this part by yourself -----------------//
  logic match;
  logic din_sel;
  logic dout_sel;
  logic [1:0] core_word;
  logic [`DATA_BITS-1:0] core_out_tmp;

  logic [`CACHE_DATA_BITS-1:0] Data_sel;
  logic [`DATA_BITS-1:0] DAout_word;
  logic [`DATA_BITS-1:0] DAout_word_tmp;
  logic [`DATA_BITS-1:0] L2_DataIn_word;
  logic [`CACHE_DATA_BITS-1:0] DataIn_sel;
  logic [`CACHE_DATA_BITS-1:0] L2_DataIn_tmp;
  /////
  logic [`DATA_BITS-1:0] L2C_cpu;

  //Snoop signal
  logic [`CACHE_INDEX_BITS-1:0] index_snp;
  logic [`CACHE_INDEX_BITS-1:0] index_core;
  logic [`CACHE_INDEX_BITS-1:0] index_snp_reg;
  logic [`CACHE_TAG_BITS-1:0]   TA_in_snp;
  logic snp_hit_I_reg;
  logic snp_hit_valid_I_reg;
  //logic pass_snp;
  logic index_arbitor;
  logic ARB_write_I_reg;
  logic grant;
  logic S_status_write;
  logic C_status_write;
  //Snoop FSM
  parameter snp_IDLE = 2'd0;
  parameter SNOOP    = 2'd1;
  parameter COMPLETE = 2'd2;
  logic [1:0] snp_state;
  logic [1:0] snp_nstate;

  // 
  logic [127:0] core_DataIn;
  integer i;

  //Signal buffer
  always_ff@(posedge clk) begin
    if(rst) begin
      L2_DataIn_tmp <= 128'd0;
      L2C_cpu <= 32'd0;
      DAout_word_tmp <= 32'd0;
      core_out <= 32'b0;
      index_snp_reg <= 6'd0;
      snp_hit_I_reg <= 1'b0;
      snp_hit_valid_I_reg <= 1'b0;
      ARB_write_I_reg <= 1'b0;
    end
    else begin
      L2_DataIn_tmp <= (Icache_wait)? L2_DataIn_tmp: L2_DataIn;
      L2C_cpu <= (~Icache_wait && (core_addr == ARB_addr_O))? L2_DataIn_word: L2C_cpu;
      DAout_word_tmp <= DAout_word;
      core_out <= core_out_tmp;
      //index_snp_reg <= (ARB_do_snp && ARB_grant==`CACHE_B) ? index_snp : index_snp_reg;
      //index_snp_reg <= (ARB_do_snp && ~grant) ? index_snp : index_snp_reg;
      index_snp_reg <= (ARB_do_snp) ? index_snp : index_snp_reg;
      snp_hit_I_reg <= (snp_hit_valid_I)? snp_hit_I : snp_hit_I_reg;
      snp_hit_valid_I_reg <= (snp_hit_valid_I)? 1'b1 : ((C_status_write) ? 1'b0 : snp_hit_valid_I_reg);
      ARB_write_I_reg <= (snp_hit_valid_I)? ARB_write_I: ARB_write_I_reg;
    end
  end

  assign index_core = core_addr[9:4];
  assign core_word = core_addr[3:2];

  //SNOOP-------------------------------------------------//
  assign index_snp = ARB_addr_I[9:4];
  assign TA_in_snp = ARB_addr_I[31:10];
  assign snoop = (snp_state!=snp_IDLE) || (ARB_do_snp);
  //assign index_arbitor = (ARB_do_snp && ARB_grant==`CACHE_B && ARB_status_I!=`status_E)? 1'b1: 1'b0;
  assign index_arbitor = (ARB_do_snp)? 1'b1: 1'b0;
  assign index = (index_arbitor)? index_snp : index_core;
  assign grant = (ARB_grant==`CACHE_A)? 1'b1 : 1'b0;// grant high means arbiter services this cache

  
  
  always_ff @(posedge clk or posedge rst) begin
    if(rst)
      snp_state <= snp_IDLE;
    else
      snp_state <= snp_nstate;
    end

  always_comb begin
    case(snp_state)
      //snp_IDLE  : snp_nstate = (ARB_do_snp && ARB_grant==`CACHE_B)? ((ARB_status_I==`status_E) ? COMPLETE: SNOOP) : snp_IDLE;
      snp_IDLE  : snp_nstate = (ARB_do_snp)? SNOOP : snp_IDLE;
      SNOOP     : snp_nstate = COMPLETE;
      COMPLETE  : snp_nstate = snp_IDLE;
      default   : snp_nstate = snp_IDLE;
    endcase
  end

  always_comb begin
    snp_hit_O       = 1'b0;
    snp_hit_valid_O = 1'b0;
    S_status_write  = 1'b0;

    case(snp_state)
      SNOOP : begin
        //pass_snp low means ARB_status_I is exclusive, and status doesn't need to change
        //or we need to check whether snp_hit happens and modify status if necessary
        snp_hit_valid_O = 1'b1;
        snp_hit_O       = ((TA_in_snp==TA_out) && (status_array[index_snp_reg]!=`status_I)) ? 1'b1 : 1'b0;
        S_status_write  = ((TA_in_snp==TA_out) && (status_array[index_snp_reg]!=`status_I)) ? 1'b1 : 1'b0;
      end
    endcase
  end

  //Check if snoop requests tag array
  /*always_ff @(posedge clk) begin
    if (rst) begin
      pass_snp <= 1'b0;
    end
    else begin
      if(snp_state==SNOOP) begin
        pass_snp <= 1'b1;
      end
      else if (snp_state==COMPLETE) begin
        pass_snp <= 1'b0;
      end
    end
  end
  */

  // To Tag Array
  assign TA_in    = core_addr[31:10];
  assign TA_read  = core_req || (snp_state==SNOOP);

  assign ARB_out     = core_in;
  assign core_DataIn = {core_in, core_in, core_in, core_in};
  assign ARB_type    = core_type;
  assign DAout_word  = (core_word==2'b11)? DA_out[127:96]:
                       (core_word==2'b10)? DA_out[95:64]:
                       (core_word==2'b01)? DA_out[63:32]: DA_out[31:0];
  
  assign L2_DataIn_word = (core_word==2'b11)? L2_DataIn[127:96]:
                          (core_word==2'b10)? L2_DataIn[95:64]:
                          (core_word==2'b01)? L2_DataIn[63:32]: L2_DataIn[31:0];
  

  //assign DA_in = {Data_sel, Data_sel, Data_sel, Data_sel};
  
  //--------------- ------------------------------ -----------------//
  //Status array
  
  always_ff@(posedge clk) begin
    if(rst)begin
      foreach(status_array[i]) begin
        status_array[i] <= `status_I;
      end
    end

    else begin
      //snoop has higher priority to write ESI status
      //core request can only write to a different index
      if(S_status_write)begin
        if(ARB_write_I) begin
          status_array[index_snp_reg] <= `status_I;//snoop write request and hit
        end
        else begin
          status_array[index_snp_reg] <= `status_S;//snoop read request and hit
        end
      end
      /*if(C_status_write && (index_snp_reg!=index_core)) begin
        if(core_write) begin
          status_array[index_core] = `status_E;//write request changes to exclusive status only
        end
        else begin
          status_array[index_core] = (snp_hit_I_reg)? `status_S : `status_E;
        end
      end*/
      if(C_status_write) begin
        if(~S_status_write || index_snp_reg!=index_core) begin
          if(core_write) begin
            status_array[index_core] <= `status_E;//write request changes to exclusive status only
          end
          else begin
            status_array[index_core] <= (snp_hit_I_reg)? `status_S : `status_E;
          end
        end
      end
    end

  end

  assign ValidOut = (status_array[index] != 2'd0);
  assign ARB_status_O = status_array[index_core];
  

  //--------------- ------------------------------ -----------------//
  comparator Compare(
    .tag1    (TA_in ),
    .tag2    (TA_out),
    .match   (match )
  );

  control_data Control(
    // input
    .clk        (clk       ),
    .rst        (rst       ),
    .core_word  (core_word ),
    .core_req   (core_req  ),
    .core_write (core_write),
    .core_addr  (core_addr ),
    .match      (match     ),
    .valid      (ValidOut  ),
    .D_wait     (Icache_wait),
    .core_type  (core_type ),
    // output
    .core_wait  (core_wait  ),
    .D_req      (ARB_req    ),
    .D_write    (ARB_write_O),
    .D_addr     (ARB_addr_O ),
    .din_sel    (din_sel    ),
    .dout_sel   (dout_sel   ),
    .DA_web     (DA_write   ),
    .DA_oe      (DA_read    ),
    .TA_write   (TA_write   ),
    .status_write(C_status_write),

    //snoop signals
    .snoop        (snoop),
    //.do_snoop     (ARB_do_snp),
    .snp_hit_valid(snp_hit_valid_I_reg),
    .grant        (grant),
    .index_arbitor(index_arbitor)
  );

  assign Data_sel = (din_sel)? L2_DataIn_tmp : core_DataIn;
  /*data_mux DinMux(
    .sel      (din_sel      ),   // 1 from memory, 0 from core
    .Data1    (L2_DataIn_tmp),   // from L2 cache
    .Data2    (core_DataIn  ),   // from core
    .Data_sel (Data_sel     )
  );
  */

  data_mux DoutMux(
    .sel      (dout_sel      ),   // 1 from memory, 0 from cache
    .Data1    (L2C_cpu       ),   // from L2 cache
    .Data2    (DAout_word_tmp),   // from L1 cache
    .Data_sel (core_out_tmp      )
  );  

  //--------------- ------------------------------ -----------------//
  data_array_wrapper DA(
    .A(index),
    .DO(DA_out),
    .DI(Data_sel),
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

