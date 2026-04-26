
module ROM_Wrapper(
    //READ ADDRESS
	input [`AXI_IDS_BITS-1:0] ARID,
	input [`AXI_ADDR_BITS-1:0] ARADDR,
	input [`AXI_LEN_BITS-1:0] ARLEN,    //1
	input [`AXI_SIZE_BITS-1:0] ARSIZE,  //1
	input [1:0] ARBURST,                //0
	input ARVALID,
	output logic ARREADY,
    //READ DATA
	output logic[`AXI_IDS_BITS-1:0] RID,
	output logic[`AXI_DATA_BITS-1:0] RDATA,
	output logic[1:0] RRESP,
	output logic RLAST,
	output logic RVALID,
	input RREADY,

    output logic CS,
    output logic OE,
    output logic [`ROM_ADDR_BITS-1:0]A,
    input  [`AXI_DATA_BITS-1:0] DO,

    input clk,
    input rst
);

assign CS = 1'b1;
//Reg
logic [`AXI_IDS_BITS-1:0]   ARID_reg;
logic [`AXI_ADDR_BITS-1:0]  ARADDR_reg;

//state of SM
enum {
    INI,
    GETRA,
    SEND
}state,next_state;

//SM jump state------------------------------------
always_ff @(posedge clk) begin
    if(rst) state <= INI;
    else    state <= next_state;
end
always_comb begin
    next_state = state;
    unique case (state)
        INI     : if(ARVALID) next_state = GETRA;
        GETRA   : next_state = SEND;
        SEND    : if(RREADY) next_state = INI;
    endcase
end
//-------------------------------------------------

//SM behavior--------------------------------------
always_ff @(posedge clk) begin
    if(rst) begin
        ARID_reg    <= `AXI_IDS_BITS'd0;
        ARADDR_reg  <= `AXI_ADDR_BITS'd0;
    end
    unique case (state)
        INI: begin
            if(ARVALID) begin
                ARID_reg    <=  ARID;
                ARADDR_reg  <=  ARADDR;
            end
        end
        default : begin
            ARID_reg    <=  ARID_reg;
            ARADDR_reg  <=  ARADDR_reg;
        end
    endcase
end
always_comb begin
    //READ ADDRESS
    ARREADY = 1'b0;
    //READ DATA
    RID     = `AXI_IDS_BITS'b0;
    RDATA   = `AXI_DATA_BITS'b0;
    RRESP   = 2'b0;
    RLAST   = 1'b0;
    RVALID  = 1'b0;
    //OUTPUT TO SRAM
    OE      = 1'b0;
    A       = 11'b0;
    case (state)
        INI: begin
            //Do nothing
        end
        GETRA: begin
            //READ ADDRESS
            ARREADY = 1'b1;
            //OUTPUT TO SRAM
            A       = ARADDR_reg[`ROM_ADDR_BITS+1:2];
        end
        SEND: begin
            //READ DATA
            RID     = ARID_reg;
            RDATA   = DO;
            RRESP   = `AXI_RESP_OKAY;
            RLAST   = 1'b1;
            RVALID  = 1'b1;
            //OUTPUT TO SRAM
            OE      = 1'b1;
            A       = ARADDR_reg[`ROM_ADDR_BITS+1:2];
        end
    endcase
end
//--------------------------------------------

endmodule

