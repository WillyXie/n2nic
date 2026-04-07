`define DATA_BITS 32
`define CACHE_WRITE_BITS 16

module control_inst(
    input                                clk,
    input                                rst,
    input [1:0]                          core_word,
    input                                core_req,
    input                                core_write,
    input [`DATA_BITS-1:0]               core_addr,
    input                                match,
    input                                valid,
    input                                D_wait,

    output logic                         core_wait,
    output logic                         D_req,
    output logic                         D_write,
    output logic [`DATA_BITS-1:0]        D_addr,
    output logic                         din_sel,
    output logic                         dout_sel,
    output logic [`CACHE_WRITE_BITS-1:0] DA_web,
    output logic                         DA_oe,
    output logic                         TA_write,

    output logic                         status_write,

    //snoop signals
    input                                snoop,
    //input                                do_snoop,
    //input                                snp_hit,
    input                                snp_hit_valid,
    input                                grant,
    //input [1:0]                          status_from_B,
    input                                index_arbitor
);

    parameter IDLE   = 4'd0;
    parameter READ   = 4'd1;
    parameter R_MISS = 4'd2;
    parameter R_SYS  = 4'd3;
    parameter R_DATA = 4'd4;
    parameter R_WAIT = 4'd5;
    parameter WAIT   = 4'd6;
    parameter R_WAIT2= 4'd7;
    parameter REQ_SNP= 4'd8;

    logic [3:0] state;
    logic [3:0] nstate;
    logic L2C_finish_reg;
    //logic snoop;

    //Buffer finish signal from L2 cache
    always_ff @(posedge clk) begin
        if(rst)
            L2C_finish_reg <= 1'b0;
        else begin
            if (state==IDLE) begin
                L2C_finish_reg <= 1'b0;
            end
            else begin
                if (~D_wait) begin
                    L2C_finish_reg <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if(rst)
            state <= IDLE;
        else
            state <= nstate; 
    end

    always_comb begin
        case(state)
            IDLE   : nstate = (core_req)? ((index_arbitor)? REQ_SNP : READ) : IDLE;
            REQ_SNP: nstate = READ;
            READ   : nstate = (match && valid)? WAIT : R_MISS;
            //R_MISS : nstate = (grant=='CACHE_A) ? R_SYS : R_MISS;
            R_MISS : nstate = (grant) ? R_SYS : R_MISS;
            R_SYS  : nstate = (~L2C_finish_reg)? R_SYS : R_DATA;
            R_DATA : nstate = R_WAIT;
            R_WAIT : nstate = (snp_hit_valid)? R_WAIT2: R_WAIT;
            R_WAIT2: nstate = IDLE;
            WAIT   : nstate = IDLE;
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
        status_write = 1'b0;

        case(state) 
            IDLE: begin
                //core_wait = (core_req && index_arbitor)? 1'b1: 1'b0;
            end
            REQ_SNP: begin
                core_wait = 1'b1;
            end
            READ: begin
                core_wait = 1'b1;
                //core_wait = (match && valid)? 1'b0: 1'b1;    
                DA_oe     = (match && valid)? 1'b1: 1'b0;
            end
            R_MISS: begin
                core_wait = 1'b1;
                D_req     = (snoop) ? 1'b0 :1'b1;
                D_write   = 1'b0;
                //D_addr    = {core_addr[31:4], count, core_addr[1:0]};
            end
            R_SYS: begin
                core_wait = 1'b1;
                D_write   = 1'b0;
                //D_addr    = {core_addr[31:4], count, core_addr[1:0]};
            end
            R_DATA: begin
                core_wait = 1'b1;
                din_sel   = 1'b1;     // 1 from memory
                dout_sel  = 1'b1;     // 1 from memory
                DA_web    = 16'd0;
                D_write = 1'b0;
                TA_write  = 1'b0;
                //D_addr = {core_addr[31:4], count, core_addr[1:0]};
                //Valid_write = 1'b1;
            end            
            R_WAIT: begin
                core_wait = 1'b1;
                dout_sel = 1'b1;
                status_write = (snp_hit_valid)? 1'b1 : 1'b0;
            end
            R_WAIT2: begin
                dout_sel = 1'b1;
            end
            
        endcase
    end 

endmodule

