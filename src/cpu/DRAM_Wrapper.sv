
module DRAM_Wrapper(
    //WRITE ADDRESS
	input [`AXI_IDS_BITS-1:0] AWID,
	input [`AXI_ADDR_BITS-1:0] AWADDR,
	input [`AXI_LEN_BITS-1:0] AWLEN,    //1
	input [`AXI_SIZE_BITS-1:0] AWSIZE,  //1
	input [1:0] AWBURST,                //0
	input AWVALID,
	output logic AWREADY,
    //WRITE DATA
	input [`AXI_DATA_BITS-1:0] WDATA,
	input [`AXI_STRB_BITS-1:0] WSTRB,
	input WLAST,
	input WVALID,
	output logic WREADY,
    //WRITE RESPONSE
	output logic [`AXI_IDS_BITS-1:0] BID,
	output logic [1:0] BRESP,
	output logic BVALID,
	input BREADY,
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

    output logic CSn,
    output logic [`AXI_STRB_BITS-1:0] WEn,
    output logic RASn,
    output logic CASn,
    output logic [`DRAM_ADDR_BITS-1:0] A,
    output logic [`AXI_DATA_BITS-1:0] D,
    input  [`AXI_DATA_BITS-1:0] Q,
    input  VALID,

    input clk,
    input rst
);

assign  CSn = 1'b0;
//REG
logic   [`AXI_IDS_BITS-1:0] AWID_reg, ARID_reg;
logic   [`AXI_ADDR_BITS-1:0]AWADDR_reg, ARADDR_reg;
logic   [2:0]RCD_count;
logic   [2:0]PRE_count;
logic   [2:0]CL_count;

enum {
    INI,
    RCD_R,
    RCD_W,
    RCD_END_R,
    RCD_END_W,
    CL_R,
    CL_W,
    CL_END_R,
    CL_END_W,
    PRE_START_R,
    PRE_START_W,
    PRE_R,
    PRE_W
}state,next_state;
always_ff @(posedge clk) begin//
    if(rst)begin
        PRE_count <= 3'b0;
    end
    else if (state==PRE_R)begin
        PRE_count <= PRE_count + 1'b1;
    end
    else if (state==PRE_W)begin
        PRE_count <= PRE_count + 1'b1;
    end
    else begin 
        PRE_count <= 3'b0;
    end
end

always_ff @(posedge clk) begin//
    if(rst)begin
        RCD_count <= 3'b0;
    end
    else if (state==RCD_R)begin
        RCD_count <= RCD_count + 1'b1;
    end
    else if (state==RCD_W)begin
        RCD_count <= RCD_count + 1'b1;
    end
    else begin 
        RCD_count <= 3'b0;
    end
end
always_ff @(posedge clk) begin//
    if(rst)begin
        CL_count <= 3'b0;
    end
    else if (state==CL_R)begin
        CL_count <= CL_count + 1'b1;
    end
    else if (state==CL_W)begin
        CL_count <= CL_count + 1'b1;
    end
    else begin 
        CL_count <= 3'b0;
    end
end

//SM jump state
always_ff @(posedge clk) begin
    if(rst) state   <=  INI;
    else    state   <=  next_state;
end
always_comb begin
    next_state = state;
    unique case (state)
        INI: begin
            if(ARVALID) next_state = RCD_R;
            else if(AWVALID) next_state = RCD_W;   
        end
        RCD_R: next_state = (RCD_count==3'b101)?RCD_END_R:RCD_R;
        RCD_W: next_state = (RCD_count==3'b101)?RCD_END_W:RCD_W;
        RCD_END_R: next_state = CL_R;
        RCD_END_W: next_state = (WVALID)?CL_W:RCD_END_W;
        CL_R: begin if(RREADY && VALID)next_state=PRE_START_R;
            else next_state=CL_R; end
        CL_W: next_state = (CL_count==3'b101)?CL_END_W:CL_W;
        CL_END_R: next_state = PRE_START_R; //just wait
        CL_END_W: if(BREADY) next_state = PRE_START_W;
        PRE_START_R: next_state = PRE_R;
        PRE_START_W: next_state = PRE_W;
        PRE_R: next_state = (PRE_count==3'b101)?INI:PRE_R;
        PRE_W: next_state = (PRE_count==3'b101)?INI:PRE_W;
        // GETRA:  next_state = GETRAIT;
        // GETRAIT: next_state = (count==4'b0101)?SEND:GETRAIT;
        // SEND:   next_state = RWAIT;
        // RWAIT:  if(RREADY && VALID) next_state = INI;
        // GETWA:  if(WVALID) next_state = GETWAIT;
        // GETWAIT: next_state = (count==4'b0101)?GETW:GETWAIT;
        // GETW:   next_state = (count==4'b1010)?WRITE:GETW;
        // WRITE:  if(BREADY) next_state = INI;
    endcase
end
//SM behavior
always_ff @(posedge clk) begin
    if (rst) begin
        ARID_reg    <= `AXI_IDS_BITS'b0;
        AWID_reg    <= `AXI_IDS_BITS'b0;
        ARADDR_reg  <= `AXI_ADDR_BITS'b0;
        AWADDR_reg  <= `AXI_ADDR_BITS'b0;
    end
    else begin
        case (state)
            INI: begin
                if(ARVALID) begin
                    ARID_reg    <= ARID;
                    AWID_reg    <= AWID_reg;
                    ARADDR_reg  <= ARADDR;
                    AWADDR_reg  <= AWADDR_reg;
                end
                else if(AWVALID) begin
                    ARID_reg    <= ARID_reg;
                    AWID_reg    <= AWID;
                    ARADDR_reg  <= ARADDR_reg;
                    AWADDR_reg  <= AWADDR;
                end
            end
            default: begin  //need assign every reg?
                ARID_reg    <= ARID_reg;
                AWID_reg    <= AWID_reg;
                ARADDR_reg  <= ARADDR_reg;
                AWADDR_reg  <= AWADDR_reg;
            end 
        endcase
    end
end
always_comb begin
    //WRITE ADDRESS
    AWREADY = 1'b0;
    //WRITE DATA
    WREADY  = 1'b0;
    //WRITE RESPONSE
    BID     = `AXI_IDS_BITS'b0;
    BRESP   = 2'b0;
    BVALID  = 1'b0;
    //READ ADDRESS
    ARREADY = 1'b0;
    //READ DATA
    RID     = `AXI_IDS_BITS'b0;
    RDATA   = `AXI_DATA_BITS'b0;
    RRESP   = 2'b0;
    RLAST   = 1'b0;
    RVALID  = 1'b0;
    //OUTPUT TO DRAM
    WEn     = 4'b1111;
    RASn    = 1'b1;
    CASn    = 1'b1;
    A       = `DRAM_ADDR_BITS'd0;
    D       = `AXI_DATA_BITS'd0;
    unique case (state)
        INI: begin
            if(ARVALID) begin //write row
                RASn    = 1'b0;
                A       = ARADDR[22:12];
            end
            else if (AWVALID) begin //write row
                RASn    = 1'b0;
                A       = AWADDR[22:12];
            end
        end
        
        RCD_R: begin // row address to column address delay
            A = ARADDR_reg[22:12];
            ARREADY = 1'b1;
        end
        RCD_W: begin // row address to column address delay
            A = AWADDR_reg[22:12];
            AWREADY = 1'b1;
        end
        RCD_END_R: begin //write column
            CASn = 1'b0;
            WEn = 4'b1111;
            A = {1'b0,ARADDR_reg[11:2]};
        end
        RCD_END_W: begin //write column
            CASn = 1'b0;
            WEn = WSTRB;
            A = {1'b0,AWADDR_reg[11:2]};
            D = WDATA;
        end
        CL_R: begin //CAS latency
            WEn = 4'b1111;
            A = {1'b0,ARADDR_reg[11:2]};
            RID     = ARID_reg;
            RDATA   = Q;
            RRESP   = `AXI_RESP_OKAY;
            RLAST   = 1'b1;
            RVALID  = VALID;
        end
        CL_W: begin //CAS latency
            WREADY  = 1'b1;
            WEn     = WSTRB;
            A       = {1'b0,AWADDR_reg[11:2]};
            D       = WDATA;
            
        end
        CL_END_R: begin //precharge
            RID     = ARID_reg;
            RDATA   = Q;
            RRESP   = `AXI_RESP_OKAY;
            RLAST   = 1'b1;
            RVALID  = VALID;
        end
        CL_END_W: begin //precharge
            BID     = AWID_reg;
            BRESP   = `AXI_RESP_OKAY;
            BVALID  = 1'b1; 
        end
        PRE_START_R: begin
            RASn    = 1'b0;
            A       = ARADDR_reg[22:12];
            WEn     = 4'b0;
        end
        PRE_START_W: begin
            RASn    = 1'b0;
            A       = AWADDR_reg[22:12];
            WEn     = 4'b0;
        end
        PRE_R: begin //precharge latency
            A       = ARADDR_reg[22:12];
        end
        PRE_W: begin //precharge latency
            A       = AWADDR_reg[22:12];
        end
        // GETRA: begin    // read column address (row have been read in INI state when VALID high)
        //     //READ ADDRESS
        //     ARREADY = 1'b1;
        //     //OUTPUT TO DRAM
        //     RASn    = 1'b0;
        //     CASn    = 1'b1;
        //     A       = {1'b0,ARADDR_reg[11:2]};
        // end
        // GETRAIT: begin
        //     ARREADY = 1'b1;
        //     RASn    = 1'b1;
        //     CASn    = 1'b1;
        //     A       = {1'b0,ARADDR_reg[11:2]};
        // end
        // SEND: begin
        //     //OUTPUT TO DRAM
        //     RASn    = 1'b1;
        //     CASn    = 1'b0;
        //     A       = {1'b0,ARADDR_reg[11:2]};
        // end
        // RWAIT: begin
        //     //READ DATA
        //     RID     = ARID_reg;
        //     RDATA   = Q;
        //     RRESP   = `AXI_RESP_OKAY;
        //     RLAST   = 1'b1;
        //     RVALID  = VALID;
        // end
        // GETWA: begin
        //     //WRITE ADDRESS
        //     AWREADY = 1'b1;
        //     //OUTPUT TO DRAM
        //     WEn     = 4'b1111;
        //     RASn    = 1'b0;
        //     CASn    = 1'b1;
        //     A       = ARADDR_reg[22:12];
        //     //A       = {1'b0,ARADDR_reg[11:2]};
        // end
        // GETWAIT: begin
        //     AWREADY = 1'b1;
        //     WEn     = 4'b1111;
        //     RASn    = 1'b1;
        //     CASn    = 1'b1;
        //     //A       = {1'b0,ARADDR_reg[11:2]};
        //     A       = ARADDR_reg[22:12];
        // end
        // GETW: begin
        //     //WRITE ADDRESS
        //     AWREADY = 1'b1;
        //     //WRITE DATA
        //     WREADY  = 1'b1;
        //     //OUTPUT TO DRAM
        //     WEn     = WSTRB;
        //     RASn    = 1'b1;
        //     CASn    = 1'b0;
        //     A       = {1'b0,ARADDR_reg[11:2]};
        //     D       = WDATA;
        // end
        // WRITE: begin
        //     //WRITE RESPONSE
        //     BID     = AWID_reg;
        //     BRESP   = `AXI_RESP_OKAY;
        //     BVALID  = 1'b1;
        // end 
    endcase
end

endmodule

