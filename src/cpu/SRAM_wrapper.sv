
module SRAM_wrapper(
  input logic CK,
	input logic RSTn,

// AXI 
  //WRITE ADDRESS
	input  [`AXI_IDS_BITS-1:0] AWID,
	input  [`AXI_ADDR_BITS-1:0] AWADDR,
	input  [`AXI_LEN_BITS-1:0] AWLEN,
	input  [`AXI_SIZE_BITS-1:0] AWSIZE,
	input  [1:0] AWBURST,
	input  AWVALID,
	output logic AWREADY,
	//WRITE DATA
	input  [`AXI_DATA_BITS-1:0] WDATA,
	input  [`AXI_STRB_BITS-1:0] WSTRB,
	input  WLAST,
	input  WVALID,
	output logic WREADY,
	//WRITE RESPONSE
	output logic [`AXI_IDS_BITS-1:0] BID,
	output logic [1:0] BRESP,
	output logic BVALID,
	input  BREADY,

  //READ ADDRESS
	input  [`AXI_IDS_BITS-1:0] ARID,
	input  [`AXI_ADDR_BITS-1:0] ARADDR,
	input  [`AXI_LEN_BITS-1:0] ARLEN,
	input  [`AXI_SIZE_BITS-1:0] ARSIZE,
	input  [1:0] ARBURST,
	input  ARVALID,
	output logic ARREADY,
	//READ DATA
	output logic [`AXI_IDS_BITS-1:0] RID,
	output logic [`AXI_DATA_BITS-1:0] RDATA,
	output logic [1:0] RRESP,
	output logic RLAST,
	output logic RVALID,
	input  RREADY
);

  logic rst;
  assign rst = ~RSTn;

  // SRAM input/output
  logic CS;
  logic OE;
  logic [3:0] WEB;
  logic [13:0] A;
  logic [31:0] DI;
  logic [31:0] DO;

// Write ----------------------------------------------------//
  logic [2:0] state_w;
  logic [2:0] nstate_w;

  parameter IDLE      = 3'd0;
  parameter AREADY_   = 3'd1;
  parameter WAIT      = 3'd2;
  parameter WREADY_   = 3'd3;
  parameter BVALID_   = 3'd4;

  always_ff @(posedge CK) begin
    if(rst)
        state_w <= IDLE;
    else
        state_w <= nstate_w;
  end


  always_comb begin
     case(state_w) 
	       IDLE:    nstate_w = (AWVALID) ? AREADY_ : IDLE;
         AREADY_: nstate_w = WAIT;
         WAIT   : nstate_w = (WVALID) ? WREADY_:WAIT;
	       WREADY_: nstate_w = BVALID_;
	       BVALID_: nstate_w = (BREADY)? IDLE : BVALID_;
       default:   nstate_w = IDLE;
     endcase	
  end

  always_comb begin
    AWREADY = 1'd0;
    WREADY  = 1'd0;
    BRESP   = 2'd0;
    BVALID  = 1'd0;
    case(state_w)
      AREADY_: begin
	      AWREADY = 1'd1;
      end
      WREADY_: begin
	      WREADY  = 1'd1;
      end
      BVALID_: begin
	      BVALID  = 1'd1;
      end
    endcase
  end

  always_ff @(posedge CK) begin
    case(state_w)
      IDLE: begin
        WEB <= 4'b1111;
        DI  <= 32'd0;
	BID <= 8'd0;
      end
      AREADY_: begin
	BID <= AWID;
      end
      WAIT: begin
        WEB <= (WVALID)? WSTRB : 4'b1111;
        DI  <= (WVALID)? WDATA : 32'd0;
      end
      WREADY_: begin
        WEB <= 4'b1111;
      end
    endcase
  end

// Read ----------------------------------------------------//
  logic [2:0] state_r;
  logic [2:0] nstate_r;

  //parameter   IDLE     = 3'd0;
  parameter   AREADY   = 3'd1;
  parameter   DATA     = 3'd2;
  parameter   RRREADY  = 3'd3;

  always_ff @(posedge CK) begin
    if(rst)
        state_r <= IDLE;
    else
        state_r <= nstate_r;
  end

  always_comb begin
    case(state_r)
      IDLE:    nstate_r = (ARVALID)? AREADY : IDLE;
      AREADY:  nstate_r = DATA;
      DATA:    nstate_r = RRREADY;
      RRREADY: nstate_r = (RREADY)? IDLE : RRREADY;
      default: nstate_r = IDLE;
    endcase
  end

  always_comb begin
    RRESP  = 2'd0;
    ARREADY  = 1'd0;
    RVALID   = 1'd0;
    RLAST    = 1'd0;
    case(state_r)
      AREADY : begin
          ARREADY = 1'b1;
      end
      RRREADY : begin
          RVALID = 1'd1;
          RLAST  = 1'd1;
      end
    endcase
  end

  always_ff @(posedge CK) begin
    case(state_r)
      IDLE:   begin
        OE    <= 1'b0;
        RDATA <= 32'd0;
	      RID   <= 4'd0;
      end
      AREADY: begin
        OE <= 1'b1;
        //RDATA <= DO;
	      RID <= ARID;
      end
      DATA:   begin
        OE <= 1'b0;
        RDATA <= DO;
      end
    endcase
  end

  assign CS = 1'd1;

  always_ff @(posedge CK) begin
    if(state_r == 3'd0 && state_w == 3'd0) begin
      if(AWVALID)
        A <= AWADDR[15:2];
      else if (ARVALID)
        A <= ARADDR[15:2];
      else
        A <= 14'd0;
    end
    else
      A <= A;
  end

//-----------------------------------------------------------//

  SRAM i_SRAM (
    .A0   (A[0]  ),
    .A1   (A[1]  ),
    .A2   (A[2]  ),
    .A3   (A[3]  ),
    .A4   (A[4]  ),
    .A5   (A[5]  ),
    .A6   (A[6]  ),
    .A7   (A[7]  ),
    .A8   (A[8]  ),
    .A9   (A[9]  ),
    .A10  (A[10] ),
    .A11  (A[11] ),
    .A12  (A[12] ),
    .A13  (A[13] ),
    .DO0  (DO[0] ),
    .DO1  (DO[1] ),
    .DO2  (DO[2] ),
    .DO3  (DO[3] ),
    .DO4  (DO[4] ),
    .DO5  (DO[5] ),
    .DO6  (DO[6] ),
    .DO7  (DO[7] ),
    .DO8  (DO[8] ),
    .DO9  (DO[9] ),
    .DO10 (DO[10]),
    .DO11 (DO[11]),
    .DO12 (DO[12]),
    .DO13 (DO[13]),
    .DO14 (DO[14]),
    .DO15 (DO[15]),
    .DO16 (DO[16]),
    .DO17 (DO[17]),
    .DO18 (DO[18]),
    .DO19 (DO[19]),
    .DO20 (DO[20]),
    .DO21 (DO[21]),
    .DO22 (DO[22]),
    .DO23 (DO[23]),
    .DO24 (DO[24]),
    .DO25 (DO[25]),
    .DO26 (DO[26]),
    .DO27 (DO[27]),
    .DO28 (DO[28]),
    .DO29 (DO[29]),
    .DO30 (DO[30]),
    .DO31 (DO[31]),
    .DI0  (DI[0] ),
    .DI1  (DI[1] ),
    .DI2  (DI[2] ),
    .DI3  (DI[3] ),
    .DI4  (DI[4] ),
    .DI5  (DI[5] ),
    .DI6  (DI[6] ),
    .DI7  (DI[7] ),
    .DI8  (DI[8] ),
    .DI9  (DI[9] ),
    .DI10 (DI[10]),
    .DI11 (DI[11]),
    .DI12 (DI[12]),
    .DI13 (DI[13]),
    .DI14 (DI[14]),
    .DI15 (DI[15]),
    .DI16 (DI[16]),
    .DI17 (DI[17]),
    .DI18 (DI[18]),
    .DI19 (DI[19]),
    .DI20 (DI[20]),
    .DI21 (DI[21]),
    .DI22 (DI[22]),
    .DI23 (DI[23]),
    .DI24 (DI[24]),
    .DI25 (DI[25]),
    .DI26 (DI[26]),
    .DI27 (DI[27]),
    .DI28 (DI[28]),
    .DI29 (DI[29]),
    .DI30 (DI[30]),
    .DI31 (DI[31]),
    .CK   (CK    ),
    .WEB0 (WEB[0]),
    .WEB1 (WEB[1]),
    .WEB2 (WEB[2]),
    .WEB3 (WEB[3]),
    .OE   (OE    ),
    .CS   (CS    )
  );

endmodule

