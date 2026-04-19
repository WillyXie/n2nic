`define DATA_BITS 32
`define CACHE_TYPE_BITS 3
`define CACHE_BYTE `CACHE_TYPE_BITS'b000
`define CACHE_HWORD `CACHE_TYPE_BITS'b001
`define CACHE_WORD `CACHE_TYPE_BITS'b010
`define CACHE_BYTE_U `CACHE_TYPE_BITS'b100
`define CACHE_HWORD_U `CACHE_TYPE_BITS'b101
`define CACHE_WRITE_BITS 16

module control(
    input                          clk,
    input                          rst,
    input [1:0]                    core_word,
    input                          core_req,
    input                          core_write,
    input [`DATA_BITS-1:0]         core_addr,
    input                          match,
    input                          valid,
    input                          D_wait,
    input [2:0]                    core_type,

    output logic                        core_wait,
    output logic                        D_req,
    output logic                        D_write,
    output logic [`DATA_BITS-1:0]       D_addr,
    output logic                        din_sel,
    output logic                        dout_sel,
    output logic [`CACHE_WRITE_BITS-1:0] DA_web,
    output logic                        DA_oe,
    output logic                        TA_write,
    output logic                        Valid_write
);

    parameter IDLE   = 4'd0;
    parameter READ   = 4'd1;
    parameter R_MISS = 4'd2;
    parameter R_SYS  = 4'd3;
    parameter R_DATA = 4'd4;
    parameter R_WAIT = 4'd10;
    parameter WRITE  = 4'd5;
    parameter W_HIT  = 4'd6;
    parameter W_MISS = 4'd7;
    parameter W_SYS  = 4'd8;
    parameter WAIT = 4'd9;

    logic [1:0] count;

    logic [3:0] state;
    logic [3:0] nstate;

    logic cacheable;
    always_comb cacheable = (core_addr[31:16] != 16'h1000);

    always_ff @(posedge clk) begin
        if(rst)
            state <= IDLE;
        else
            state <= nstate; 
    end

    always_comb begin
        case(state)
            IDLE  : nstate = (core_req)? ((core_write)? WRITE : READ) : IDLE;
            READ  : nstate = (match && valid)? WAIT : R_MISS;
            R_MISS: nstate = R_SYS;
            R_SYS : nstate = (D_wait)? R_SYS : ((cacheable)? R_DATA : R_WAIT);
            R_DATA: nstate = (count==2'd3)? R_WAIT : R_MISS;
            R_WAIT: nstate = IDLE;
            WRITE : nstate = (match && valid)? W_HIT : W_MISS;
            W_HIT : nstate = W_SYS;
            W_MISS: nstate = W_SYS;
            W_SYS : nstate = (D_wait)? W_SYS : WAIT;
            WAIT  : nstate = IDLE;
            default:nstate = IDLE;
        endcase
    end

    always_comb begin
        core_wait = 1'b0;
        D_req     = 1'b0;
        din_sel   = 1'b0;
        dout_sel  = 1'b0;
        DA_web    = {(16){1'b1}};
        DA_oe     = 1'b0;
        TA_write  = (valid)?1'b1:1'b0;
        D_write   = core_write && core_req;
        D_addr    = core_addr;
        Valid_write = 1'b0;
        case(state) 
            READ: begin
                core_wait = 1'b1; 
                DA_oe     = (match && valid)? 1'b1: 1'b0;
            end
            R_MISS: begin
                core_wait = 1'b1;
                D_req     = 1'b1;
                D_write   = 1'b0;
                D_addr[3:2] = (cacheable)? count : core_addr[3:2];
                //D_addr    = {core_addr[31:4], count, core_addr[1:0]};
            end
            R_SYS: begin
                core_wait = 1'b1;
                D_write   = 1'b0;
                D_addr[3:2] = (cacheable)? count : core_addr[3:2];
                //D_addr    = {core_addr[31:4], count, core_addr[1:0]};
            end
            R_DATA: begin
                core_wait = 1'b1;
                din_sel   = 1'b1;     // 1 from memory
                dout_sel  = 1'b1;     // 1 from memory
                TA_write  = 1'b0; 
                D_write = 1'b0;
                D_addr = {core_addr[31:4], count, core_addr[1:0]};
                Valid_write = 1'b1;

                DA_web    = (count==2'd3)?{4'd0,{(12){1'b1}}}:
                            (count==2'd2)?{{(4){1'b1}}, 4'd0, {(8){1'b1}}}:
                            (count==2'd1)?{{(8){1'b1}}, 4'd0, {(4){1'b1}}}:
                            (count==2'd0)?{{(12){1'b1}},4'd0}:16'd0;
            end
            R_WAIT: begin
                dout_sel = 1'b1;
            end
            WRITE: begin
                core_wait = 1'b1;
            end
            W_HIT: begin
                core_wait = 1'b1;
                D_req     = 1'b1;
                
                case(core_type)
                    `CACHE_WORD: begin
                        DA_web = (core_word==2'b11)?{4'd0,{(12){1'b1}}}:
                                (core_word==2'b10)?{{(4){1'b1}}, 4'd0,{(8){1'b1}}}:
                                (core_word==2'b01)?{{(8){1'b1}}, 4'd0,{(4){1'b1}}}: {{(12){1'b1}}, 4'd0};
                    end
                    `CACHE_HWORD: begin
                        if(core_word == 2'b11) begin
                            DA_web = (core_addr[1] == 0)? {2'd3, 2'd0,{(12){1'b1}}} : {2'd0, 2'd3, {(12){1'b1}}};
                        end
                        else if (core_word == 2'b10) begin
                            DA_web = (core_addr[1] == 0)? {{(4){1'b1}}, 2'd3, 2'd0,{(8){1'b1}}} : {{(4){1'b1}}, 2'd0, 2'd3,{(8){1'b1}}};
                        end
                        else if (core_word == 2'b01) begin
                            DA_web = (core_addr[1] == 0)? {{(8){1'b1}}, 2'd3, 2'd0,{(4){1'b1}}} : {{(8){1'b1}}, 2'd0, 2'd3,{(4){1'b1}}};
                        end
                        else begin
                            DA_web = (core_addr[1] == 0)? {{(12){1'b1}}, 2'd3, 2'd0} : {{(12){1'b1}}, 2'd0, 2'd3};
                        end
                    end
                    `CACHE_BYTE: begin
                        if(core_word == 2'b11) begin
                            DA_web = (core_addr[1:0]==2'b00) ? {3'b111,1'b0,{(12){1'b1}}}:
                                    (core_addr[1:0]==2'b01) ? {2'b11, 1'b0, 1'b1,{(12){1'b1}}}:
                                    (core_addr[1:0]==2'b10) ? {1'b1, 1'b0, 2'b11,{(12){1'b1}}}: 
                                    {1'b0, 3'b111,{(12){1'b1}}};
                        end
                        else if (core_word == 2'b10) begin
                            DA_web = (core_addr[1:0]==2'b00) ? {{(4){1'b1}}, 3'b111,1'b0,{(8){1'b1}}}:
                                    (core_addr[1:0]==2'b01) ? {{(4){1'b1}}, 2'b11, 1'b0, 1'b1,{(8){1'b1}}}:
                                    (core_addr[1:0]==2'b10) ? {{(4){1'b1}}, 1'b1, 1'b0, 2'b11,{(8){1'b1}}}: 
                                    {{(4){1'b1}}, 1'b0, 3'b111,{(8){1'b1}}};
                        end
                        else if (core_word == 2'b01) begin
                            DA_web = (core_addr[1:0]==2'b00) ? {{(8){1'b1}}, 3'b111,1'b0,{(4){1'b1}}}:
                                    (core_addr[1:0]==2'b01) ? {{(8){1'b1}}, 2'b11, 1'b0, 1'b1,{(4){1'b1}}}:
                                    (core_addr[1:0]==2'b10) ? {{(8){1'b1}}, 1'b1, 1'b0, 2'b11,{(4){1'b1}}}: 
                                    {{(8){1'b1}}, 1'b0, 3'b111,{(4){1'b1}}};
                        end
                        else begin
                            DA_web = (core_addr[1:0]==2'b00) ? {{(12){1'b1}}, 3'b111,1'b0}:
                                    (core_addr[1:0]==2'b01) ? {{(12){1'b1}}, 2'b11, 1'b0, 1'b1}:
                                    (core_addr[1:0]==2'b10) ? {{(12){1'b1}}, 1'b1, 1'b0, 2'b11}: 
                                    {{(12){1'b1}}, 1'b0, 3'b111};
                        end
                    end
                    endcase
            end
            W_MISS: begin
                core_wait = 1'b1;
                D_req     = 1'b1;
            end
            W_SYS: begin
                core_wait = 1'b1;
            end
        endcase
    end 

    always_ff @(posedge clk) begin
        if(rst) 
            count <= 2'd0;
        else begin
            case(state)
                IDLE:  count <= 2'd0;
                READ:  count <= 2'd0;
                R_DATA: count <= count + 2'd1;
            endcase
        end
    end

endmodule

