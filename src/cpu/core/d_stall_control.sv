//d_stall control

module d_stall_control(
    input        clk,
    input        rst,
    input [3:0]  dm_web,
    input        dm_oe,
    input        dm_wait,
    output logic d_stall
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
            IDLE : nstate = ((dm_web != 4'd15) || dm_oe )? STALL : IDLE;
            STALL: nstate = (dm_wait)? STALL : DONE;
            DONE : nstate = IDLE;
            default: nstate = IDLE;
        endcase
    end

    always_comb begin
        case(state)
            IDLE:    d_stall = ((dm_web != 4'd15) || dm_oe )? 1'b1 : 1'b0;
            STALL:   d_stall = (dm_wait)?1'b1:1'b0;
            //STALL:   d_stall = 1'b1;
            DONE:    d_stall = 1'b0;
            default: d_stall = 1'b0;
        endcase
    end

endmodule

