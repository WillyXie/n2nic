module cache_arbiter(
    input clk,
    input rst,
    //signals from coreA cache
    input A_cache_req,
    input A_cache_write,
    input [31:0]A_cache_addr,
    input [31:0]A_cache_data,
    input [2:0]A_cache_type,
    input [1:0]A_ESI_status,
    //signals feom coreB cache
    input B_cache_req,
    input B_cache_write,
    input [31:0]B_cache_addr,
    input [31:0]B_cache_data,
    input [2:0]B_cache_type,
    input [1:0]B_ESI_status,
    //output for snoop
    output logic A_do_snoop, 
    output logic [31:0]A_addr, //granted address
    output logic A_write, //tell coreB reading or writing
    output logic [1:0]A_B_ESI_status,
    output logic [1:0]grant, //00 indicates IDLE, 01 indicates coreA, 10 indicates coreB
    output logic B_do_snoop,
    output logic [31:0]B_addr,
    output logic B_write,
    output logic [1:0] B_A_ESI_status,
    //output for L2 cache
    output logic L2_cache_req,
    output logic L2_cache_write,
    output logic [31:0]L2_cache_addr,
    output logic [31:0]L2_cache_data,
    output logic [2:0]L2_cache_type,
    //input from L2 cache
    input L2_finish
);
//------------------------declare ports here----------------------------//
    logic [1:0]state;
    logic [1:0]nstate;
    logic [1:0]curr_grant;
/* because L1 cache can queue for me
    logic req_que;
    logic write_que;
    logic [31:0]addr_que;
    logic [31:0]data_que;
    logic [2:0]type_que;
    logic [1:0]grant_que;
    logic [1:0]core_que; //00 IDLE,01 indicates coreA, 10 indicates coreB

*/



//------------------------end of declare ports-------------------------//
//------------------------declare parameters here----------------------//
parameter IDLE = 2'd0;
parameter GRANTA = 2'd1;
parameter GRANTB = 2'd2;
parameter WAIT = 2'd3;
//------------------------end of declare parameters--------------------//


    always_ff @(posedge clk) begin
        if(rst)begin
            state <= IDLE;
        end
        else begin
            state <= nstate;
        end
    end
    always_comb begin
        case (state)
            IDLE    :begin
                if (curr_grant==2'b01)begin
                    if(B_cache_req) nstate = GRANTB;
                    else if (A_cache_req)nstate = GRANTA;
                    else nstate = IDLE; 
                end
                else if (curr_grant==2'b10)begin
                    if(A_cache_req) nstate = GRANTA;
                    else if (B_cache_req)nstate = GRANTB;
                    else nstate = IDLE; 
                end
                else begin
                    if(A_cache_req) nstate = GRANTA;
                    else if (B_cache_req)nstate = GRANTB;
                    else nstate = IDLE; 
                end
            end
            GRANTA  :   nstate = WAIT;
            GRANTB  :   nstate = WAIT;
            WAIT    :begin
                if (curr_grant==2'b01)begin
                    if (L2_finish&B_cache_req) nstate = GRANTB;
                    else if (L2_finish&A_cache_req) nstate = GRANTA;
                    else if (L2_finish) nstate = IDLE;
                    else nstate = WAIT; 
                end
                else if (curr_grant==2'b10)begin
                    if (L2_finish&A_cache_req) nstate = GRANTA;
                    else if (L2_finish&B_cache_req) nstate = GRANTB;
                    else if (L2_finish) nstate = IDLE;
                    else nstate = WAIT; 
                end
                else begin
                    if (L2_finish&A_cache_req) nstate = GRANTA;
                    else if (L2_finish&B_cache_req) nstate = GRANTB;
                    else if (L2_finish) nstate = IDLE;
                    else nstate = WAIT; 
                end
                
            end
            
        endcase
    end

    always_ff @(posedge clk) begin
        if(rst)begin
            curr_grant <= 2'b00;
        end
        else begin
            if (nstate==GRANTA)begin
                curr_grant <= 2'b01;
            end
            else if (nstate==GRANTB)begin
                curr_grant <= 2'b10;
            end
            else 
                curr_grant <= curr_grant;
        end
    end

    always_comb begin
        L2_cache_req = 1'b0;
        L2_cache_write = 1'b0;
        L2_cache_addr = 32'b0;
        L2_cache_data = 32'b0;
        L2_cache_type = 3'b0;
        A_do_snoop = 1'b0;
        A_addr = 32'b0;
        A_write = 1'b0;
        B_do_snoop = 1'b0;
        B_addr = 32'b0;
        B_write = 1'b0;
        grant = 2'b00;
        A_B_ESI_status = 2'b11;
        B_A_ESI_status = 2'b11;
        case (state)
            GRANTA  : begin
                grant = 2'b01;
                L2_cache_req = A_cache_req;
                L2_cache_write = A_cache_write;
                L2_cache_addr = A_cache_addr;
                L2_cache_data = A_cache_data;
                L2_cache_type = A_cache_type;
                B_do_snoop = 1'b1;
                B_A_ESI_status = A_ESI_status;
                B_addr = A_cache_addr;
                B_write = A_cache_write;
            end
            GRANTB  :begin
                grant = 2'b10;
                L2_cache_req = B_cache_req;
                L2_cache_write = B_cache_write;
                L2_cache_addr = B_cache_addr;
                L2_cache_data = B_cache_data;
                L2_cache_type = B_cache_type;
                A_do_snoop = 1'b1;
                A_B_ESI_status = B_ESI_status;
                A_addr = B_cache_addr;
                A_write = B_cache_write;
            end
            WAIT    :begin
                if(curr_grant==2'b01)begin
                    grant = 2'b01;
                    L2_cache_req = A_cache_req;
                    L2_cache_write = A_cache_write;
                    L2_cache_addr = A_cache_addr;
                    L2_cache_data = A_cache_data;
                    L2_cache_type = A_cache_type;
                    B_A_ESI_status = A_ESI_status;
                    B_addr = A_cache_addr;
                    B_write = A_cache_write;
                end
                else if (curr_grant==2'b10)begin
                    grant = 2'b10;
                    L2_cache_req = B_cache_req;
                    L2_cache_write = B_cache_write;
                    L2_cache_addr = B_cache_addr;
                    L2_cache_data = B_cache_data;
                    L2_cache_type = B_cache_type;
                    A_B_ESI_status = B_ESI_status;
                    A_addr = B_cache_addr;
                    A_write = B_cache_write;
                end
            end
        endcase
    end

endmodule

