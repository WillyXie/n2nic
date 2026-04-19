module L2C_inst(
    input clk,
    input rst,
    //input from Arbitor
    input cache_arb_req,
    input cache_arb_write,
    input [31:0]cache_arb_addr,
    input [31:0]cache_arb_data,
    input [2:0]cache_arb_type,
    input [1:0] cache_arb_grant,
    //input from AXI
    input L2_Icache_wait,
    input [31:0]AXI_data,
    //output to AXI
    output logic L2_Icache_req,
    output logic L2_Icache_write,
    output logic [31:0]L2_Icache_addr,
    output logic [31:0]L2_Icache_data,
    output logic [2:0] L2_Icache_type,
    //output to L1 cache
    output logic A_Icache_wait,
    output logic B_Icache_wait,
    output logic [127:0]A_Icache_data, 
    output logic [127:0]B_Icache_data 


);
//------------------------declare ports here----------------------------//
//tag array
logic [`CACHE_TAG_BITS-1:0] TA1_out;
// logic [`CACHE_TAG_BITS-1:0] TA1_in;
logic TA1_write;
logic TA1_read;
logic [`CACHE_TAG_BITS-1:0] TA2_out;
// logic [`CACHE_TAG_BITS-1:0] TA2_in;
logic TA2_write;
logic TA2_read;
logic [`CACHE_TAG_BITS-1:0] TA3_out;
// logic [`CACHE_TAG_BITS-1:0] TA3_in;
logic TA3_write;
logic TA3_read;
logic [`CACHE_TAG_BITS-1:0] TA4_out;
// logic [`CACHE_TAG_BITS-1:0] TA4_in;
logic TA4_write;
logic TA4_read;
//data array
logic [`CACHE_DATA_BITS-1:0] DA1_out;
logic [`CACHE_DATA_BITS-1:0] DA1_in;
logic [`CACHE_WRITE_BITS-1:0] DA1_write;
logic DA1_read;
logic [`CACHE_DATA_BITS-1:0] DA2_out;
logic [`CACHE_DATA_BITS-1:0] DA2_in;
logic [`CACHE_WRITE_BITS-1:0] DA2_write;
logic DA2_read;
logic [`CACHE_DATA_BITS-1:0] DA3_out;
logic [`CACHE_DATA_BITS-1:0] DA3_in;
logic [`CACHE_WRITE_BITS-1:0] DA3_write;
logic DA3_read;
logic [`CACHE_DATA_BITS-1:0] DA4_out;
logic [`CACHE_DATA_BITS-1:0] DA4_in;
logic [`CACHE_WRITE_BITS-1:0] DA4_write;
logic DA4_read;
// Flag RF
logic [63:0] valid_array[3:0];
logic [63:0] dirty_array[3:0];
logic [63:0] reference_array[3:0];
// reg

logic [2:0] state;
logic [2:0] nstate;
logic [1:0] count;

//-------------------------- Parameter ----------------------------------//
parameter WAY1 = 2'b00;
parameter WAY2 = 2'b01;
parameter WAY3 = 2'b10;
parameter WAY4 = 2'b11;
//FSM State
parameter IDLE   = 3'd0;
parameter READ   = 3'd1;
parameter R_MISS = 3'd2;
parameter R_SYS  = 3'd3;
parameter R_DATA = 3'd4;
parameter R_WAIT = 3'd5;
parameter WAIT   = 3'd6;


//-------------------------- Internal wire -------------------------------//
// Mux select signal
logic din_sel;  //  0: AXI_data, 1: cache_arb_data
logic core_sel; //  0: core_A, 1: core_B
// Control signal
logic Valid_write;
logic Dirty_write;
logic Ref_write;
logic hit;
logic [1:0] write_cache_way; // choose whitch way to write
logic [1:0] Dout_sel_way; // Choose Dout from which way (4-way)
// Others
logic [`CACHE_TAG_BITS-1:0]     TA_in;
logic [`DATA_BITS-1:0]          Din;
logic [`CACHE_WRITE_BITS-1:0]   DA_web;
logic DA_oe;
logic TA_write;
logic [`CACHE_INDEX_BITS-1:0] index;
logic [127:0] Dout_tmp;
logic [127:0] AXI_in_tmp; 
//---------------------- End of declare ports --------------------------//
assign L2_Icache_data = cache_arb_data;
assign L2_Icache_type = cache_arb_type;
assign core_sel = (cache_arb_grant == 2'b01) ? 1'b0
                    : (cache_arb_grant == 2'b10) ? 1'b1
                    : 1'b0;
assign index = cache_arb_addr[9:4];
assign TA_in = cache_arb_addr[31:10];

//----------------------- Comparator -----------------------------------//
logic match_tag1; //= (TA_in == TA1_out) ? 1'b1 : 1'b0;
logic match_tag2; //= (TA_in == TA2_out) ? 1'b1 : 1'b0;
logic match_tag3; //= (TA_in == TA3_out) ? 1'b1 : 1'b0;
logic match_tag4; //= (TA_in == TA4_out) ? 1'b1 : 1'b0;
logic valid1 ;//= valid_array[0][index];
logic valid2;//= valid_array[1][index];
logic valid3;//= valid_array[2][index];
logic valid4;//= valid_array[3][index];

logic [1:0] match_way;

assign valid1 = valid_array[0][index];
assign valid2 = valid_array[1][index];
assign valid3 = valid_array[2][index];
assign valid4 = valid_array[3][index];

assign match_tag1 = (TA_in == TA1_out) ? 1'b1 : 1'b0;
assign match_tag2 = (TA_in == TA2_out) ? 1'b1 : 1'b0;
assign match_tag3 = (TA_in == TA3_out) ? 1'b1 : 1'b0;
assign match_tag4 = (TA_in == TA4_out) ? 1'b1 : 1'b0;

assign  match_way = (match_tag1 & valid1) ? WAY1
                            : (match_tag2 & valid2) ? WAY2
                            : (match_tag3 & valid3) ? WAY3
                            : (match_tag4 & valid4) ? WAY4
                            : 2'b00;
assign hit = (match_tag1 & valid1) | (match_tag2 & valid2) 
                | (match_tag3 & valid3) | (match_tag4 & valid4);

//------------------------ DA_OE -----------------------------------------//
assign DA1_read = match_tag1 & DA_oe;
assign DA2_read = match_tag2 & DA_oe;
assign DA3_read = match_tag3 & DA_oe;
assign DA4_read = match_tag4 & DA_oe;

//------------------------ write_cache_way -------------------------------//
logic [1:0] lru_way;
always_comb begin
    if(~reference_array[0][index])
        lru_way = WAY1;
    else if(~reference_array[1][index])
        lru_way = WAY2;
    else if(~reference_array[2][index])
        lru_way = WAY3;
    else if(~reference_array[3][index])
        lru_way = WAY4;
    else 
        lru_way = WAY1;
end
always_comb begin
    if(~valid_array[0][index])
        write_cache_way = WAY1;
    else if(~valid_array[1][index])
        write_cache_way = WAY2;
    else if(~valid_array[2][index])
        write_cache_way = WAY3;
    else if(~valid_array[3][index])
        write_cache_way = WAY4;
    else
        write_cache_way = lru_way;
end

//------------------------ DA_Web ----------------------------------------//
assign DA1_write = (write_cache_way == WAY1) ? DA_web : 16'hffff; 
assign DA2_write = (write_cache_way == WAY2) ? DA_web : 16'hffff; 
assign DA3_write = (write_cache_way == WAY3) ? DA_web : 16'hffff; 
assign DA4_write = (write_cache_way == WAY4) ? DA_web : 16'hffff; 

//------------------------ Dout ------------------------------------------//
assign Dout_sel_way = (hit) ? match_way : write_cache_way;
always_comb begin
    case(Dout_sel_way)
        WAY1: Dout_tmp = DA1_out;
        WAY2: Dout_tmp = DA2_out;
        WAY3: Dout_tmp = DA3_out;
        WAY4: Dout_tmp = DA4_out;
        default: Dout_tmp = 128'b0;
    endcase
end
assign A_Icache_data = (~core_sel) ? Dout_tmp : 128'b0;
assign B_Icache_data = (core_sel) ? Dout_tmp : 128'b0;

//------------------------ TA_write ----------------------------------------//
always_comb begin
    TA1_write = 1'b1;
    TA2_write = 1'b1;
    TA3_write = 1'b1;
    TA4_write = 1'b1;
    case(write_cache_way)
        WAY1: TA1_write = TA_write;
        WAY2: TA2_write = TA_write;
        WAY3: TA3_write = TA_write;
        WAY4: TA4_write = TA_write;
    endcase
end

//------------------------ Mux ---------------------------------------------//
// Din Mux

assign Din = din_sel ? cache_arb_data : AXI_in_tmp; // No use in

//------------------------ Assign Din ---------------------------------------//
assign DA1_in = AXI_in_tmp;//Din; // Controled by write flag 
assign DA2_in = AXI_in_tmp; //Din;
assign DA3_in = AXI_in_tmp; //Din;
assign DA4_in = AXI_in_tmp; //Din;
//------------------------ Counter -----------------------------------------//

always_ff @(posedge clk) begin
    if(rst) count <= 2'd0;
    else begin
        case(state)
            IDLE:   count <= 2'd0;
            READ:   count <= 2'd0; // Not use (?
            R_DATA: count <= count + 2'd1;
            default: count <= count;
        endcase
    end
end

//------------------------ Flag array ------------------------------------//
always_ff @(posedge clk) begin
    // valid array
    if(rst) begin
        foreach(valid_array[0][i]) begin
            valid_array[0][i] = 1'b0;
            valid_array[1][i] = 1'b0;
            valid_array[2][i] = 1'b0;
            valid_array[3][i] = 1'b0;
        end
    end
    else if(Valid_write) begin
        valid_array[write_cache_way][index] = 1'b1;
    end
    // dirty array (always 0)
    if(rst) begin
        foreach ( dirty_array[0][i] ) begin
            dirty_array[0][i] = 1'b0;
            dirty_array[1][i] = 1'b0;
            dirty_array[2][i] = 1'b0;
            dirty_array[3][i] = 1'b0;
        end
    end
    // ref array
    if(rst) begin
        foreach ( reference_array[0][i] ) begin
            reference_array[0][i] = 1'b0;
            reference_array[1][i] = 1'b0;
            reference_array[2][i] = 1'b0;
            reference_array[3][i] = 1'b0;
        end
    end
    else if(Ref_write) begin
        if(hit) begin
            reference_array[match_way][index] = 1'b1;
        end
        else begin
            reference_array[0][index] = 1'b0;
            reference_array[1][index] = 1'b0;
            reference_array[2][index] = 1'b0;
            reference_array[3][index] = 1'b0;
        end
    end
    
end

//------------------------ FSM State -------------------------------------//
always_ff @(posedge clk) begin
    if(rst)
        state <= IDLE;
    else
        state <= nstate;
end

always_comb begin
    case(state)
        IDLE    : nstate = (cache_arb_req) ? READ : IDLE;
        READ    : nstate = (hit) ? IDLE : R_MISS;
        R_MISS  : nstate = R_SYS;
        R_SYS   : nstate = (L2_Icache_wait) ? R_SYS : R_DATA;
        R_DATA  : nstate = (count == 2'd3) ? R_WAIT : R_MISS;
        R_WAIT  : nstate = IDLE;
        default : nstate = IDLE;
    endcase
end

always_comb begin
    A_Icache_wait   = 1'b1;
    B_Icache_wait   = 1'b1;
    L2_Icache_req   = 1'b0;
    din_sel         = 1'b1;
    DA_web          = 16'hFFFF;    // Must de-mux (4-way)
    DA_oe           = 1'b0;     // Must de-mux (4-weay)
    TA_write        = 1'b1;     // To modified
    L2_Icache_write = 1'b0;     // Never write (1 write?)
    L2_Icache_addr  = cache_arb_addr;
    Valid_write     = 1'b0;
    Dirty_write     = 1'b0;
    Ref_write       = 1'b0;
    AXI_in_tmp      = 128'b0;

    case(state)
        READ    : begin
            A_Icache_wait = (~core_sel & hit) ? 1'b0 : 1'b1;
            B_Icache_wait = (core_sel & hit) ? 1'b0 : 1'b1;
            DA_oe         = (hit) ? 1'b1 : 1'b0;
            Ref_write     = (hit) ? 1'b1 : 1'b0;
        end
        R_MISS  : begin
            L2_Icache_req   = 1'b1;
            L2_Icache_addr  = {cache_arb_addr[31:4], count, cache_arb_addr[1:0]};
        end
        R_SYS   : begin
            // L2_Icache_req = 1'b0, which write in default
            L2_Icache_addr  = {cache_arb_addr[31:4], count, cache_arb_addr[1:0]};
        end
        R_DATA  : begin
            din_sel = 1'b0; // sel from memory
            DA_web = (count==2'd3)?{4'd0,{(12){1'b1}}}:
                            (count==2'd2)?{{(4){1'b1}}, 4'd0, {(8){1'b1}}}:
                            (count==2'd1)?{{(8){1'b1}}, 4'd0, {(4){1'b1}}}:
                            (count==2'd0)?{{(12){1'b1}},4'd0}:16'd0;
            AXI_in_tmp = (count == 2'd0) ? {96'b0, AXI_data}
                            : (count == 2'd1) ? {64'b0, AXI_data, 32'b0}
                            : (count == 2'd2) ? {32'b0, AXI_data, 64'b0}
                            : (count == 2'd3) ? {AXI_data, 96'b0}
                            : 128'b0;
            L2_Icache_addr  = {cache_arb_addr[31:4], count, cache_arb_addr[1:0]};
            TA_write = 1'b0; // 0 write
        end
        R_WAIT  : begin
            DA_oe = 1'b1;       // L2 Cache out to L1
            Valid_write = 1'b1; // 1 write
            Ref_write = 1'b1;   // 1 write
            A_Icache_wait = (~core_sel) ? 1'b0 : 1'b1;
            B_Icache_wait = (core_sel) ? 1'b0 : 1'b1;
        end
    endcase
end

//------------------------Tag Array and Data Array----------------------//
tag_array_wrapper TA1(
    .A(index),
    .DO(TA1_out),
    .DI(TA_in),
    .CK(clk),
    .WEB(TA1_write),
    .OE(1'b1),
    .CS(1'b1)
);
data_array_wrapper DA1(
    .A(index),
    .DO(DA1_out),
    .DI(DA1_in),
    .CK(clk),
    .WEB(DA1_write),
    .OE(DA1_read),
    .CS(1'b1)
);
tag_array_wrapper TA2(
    .A(index),
    .DO(TA2_out),
    .DI(TA_in),
    .CK(clk),
    .WEB(TA2_write),
    .OE(1'b1),
    .CS(1'b1)
);
data_array_wrapper DA2(
    .A(index),
    .DO(DA2_out),
    .DI(DA2_in),
    .CK(clk),
    .WEB(DA2_write),
    .OE(DA2_read),
    .CS(1'b1)
);
tag_array_wrapper TA3(
    .A(index),
    .DO(TA3_out),
    .DI(TA_in),
    .CK(clk),
    .WEB(TA3_write),
    .OE(1'b1),
    .CS(1'b1)
);
data_array_wrapper DA3(
    .A(index),
    .DO(DA3_out),
    .DI(DA3_in),
    .CK(clk),
    .WEB(DA3_write),
    .OE(DA3_read),
    .CS(1'b1)
);
tag_array_wrapper TA4(
    .A(index),
    .DO(TA4_out),
    .DI(TA_in),
    .CK(clk),
    .WEB(TA4_write),
    .OE(1'b1),
    .CS(1'b1)
);
data_array_wrapper DA4(
    .A(index),
    .DO(DA4_out),
    .DI(DA4_in),
    .CK(clk),
    .WEB(DA4_write),
    .OE(DA4_read),
    .CS(1'b1)
);

endmodule

