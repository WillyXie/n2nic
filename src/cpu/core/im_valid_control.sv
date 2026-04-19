//im_valid control

module im_valid_control(
    input        clk,
    input        rst,
    input        im_wait,
    output logic im_valid
);

    parameter IDLE  = 2'd0;
    parameter STALL = 2'd1;
    parameter DONE  = 2'd2;

    logic [1:0] state;
    logic [1:0] nstate;

    always_ff @(posedge clk) begin
        if(rst)
            state <= IDLE;
        else
            state <= nstate; 
    end

    always_comb begin
        case(state)
            IDLE : nstate = STALL;
            STALL: nstate = (im_wait)? STALL : DONE;
            DONE : nstate = IDLE;
            default: nstate = IDLE;
        endcase
    end

    always_comb begin
        case(state)
            IDLE:    im_valid = 1'b0;
            STALL:   im_valid = (im_wait)? 1'b0 : 1'b1;
            DONE:    im_valid = 1'b0;
            default: im_valid = 1'b0;
        endcase
    end

endmodule

