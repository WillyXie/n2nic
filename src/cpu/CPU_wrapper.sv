// CPU_wrapper
`define CACHE_BLOCK_BITS 2
`define CACHE_INDEX_BITS 6
`define CACHE_TAG_BITS 22
`define CACHE_DATA_BITS 128
`define CACHE_LINES 2**(`CACHE_INDEX_BITS)
`define CACHE_WRITE_BITS 16
`define CACHE_TYPE_BITS 3
`define CACHE_BYTE `CACHE_TYPE_BITS'b000
`define CACHE_HWORD `CACHE_TYPE_BITS'b001
`define CACHE_WORD `CACHE_TYPE_BITS'b010
`define CACHE_BYTE_U `CACHE_TYPE_BITS'b100
`define CACHE_HWORD_U `CACHE_TYPE_BITS'b101
`define DATA_BITS 32

module CPU_wrapper #(
    parameter AXI_ID_BITS     = 4       ,
    parameter AXI_IDS_BITS    = 8       ,
    parameter AXI_ADDR_BITS   = 32      ,
    parameter AXI_LEN_BITS    = 4       ,
    parameter AXI_SIZE_BITS   = 3       ,
    parameter AXI_DATA_BITS   = 32      ,
    parameter AXI_STRB_BITS   = 4       ,
    parameter AXI_LEN_ONE     = 4'h0    ,
    parameter AXI_SIZE_BYTE   = 3'b000  ,
    parameter AXI_SIZE_HWORD  = 3'b001  ,
    parameter AXI_SIZE_WORD   = 3'b010  ,
    parameter AXI_BURST_INC   = 2'h1    ,
    parameter AXI_STRB_WORD   = 4'b1111 ,
    parameter AXI_STRB_HWORD  = 4'b0011 ,
    parameter AXI_STRB_BYTE   = 4'b0001 ,
    parameter AXI_RESP_OKAY   = 2'h0    ,
    parameter AXI_RESP_SLVERR = 2'h2    ,
    parameter AXI_RESP_DECERR = 2'h3
  )(
  input  logic  CK,
  input  logic  RSTn,   //from top
  input  logic  ext_interrupt,

// MASTER INTERFACE FOR SLAVES--------------------------------------------------//
// Data Memory (Master 1)------------------------//
	//WRITE ADDRESS
	output logic [AXI_ID_BITS-1:0]   AWID_M1,
	output logic [AXI_ADDR_BITS-1:0] AWADDR_M1,
	output logic [AXI_LEN_BITS-1:0]  AWLEN_M1,
	output logic [AXI_SIZE_BITS-1:0] AWSIZE_M1,
	output logic [1:0]                AWBURST_M1,
	output logic                      AWVALID_M1,
	input                             AWREADY_M1,
	//WRITE DATA
	output logic [AXI_DATA_BITS-1:0] WDATA_M1,
	output logic [AXI_STRB_BITS-1:0] WSTRB_M1,
	output logic                      WLAST_M1,
	output logic                      WVALID_M1,
	input                             WREADY_M1,
	//WRITE RESPONSE
	input  [AXI_ID_BITS-1:0]         BID_M1,
	input  [1:0]                      BRESP_M1,
	input                             BVALID_M1,
	output logic                      BREADY_M1,
	
	//READ ADDRESS
	output logic [AXI_ID_BITS-1:0]   ARID_M1,
	output logic [AXI_ADDR_BITS-1:0] ARADDR_M1,
	output logic [AXI_LEN_BITS-1:0]  ARLEN_M1,
	output logic [AXI_SIZE_BITS-1:0] ARSIZE_M1,
	output logic [1:0]                ARBURST_M1,
	output logic                      ARVALID_M1,
	input                             ARREADY_M1,
	//READ DATA
	input  [AXI_ID_BITS-1:0]         RID_M1,
	input  [AXI_DATA_BITS-1:0]       RDATA_M1,
	input  [1:0]                      RRESP_M1,
	input                             RLAST_M1,
	input                             RVALID_M1,
	output logic                      RREADY_M1,

// Instruction Memory (Master 0)------------------//
	//READ ADDRESS
	output logic [AXI_ID_BITS-1:0]   ARID_M0,
	output logic [AXI_ADDR_BITS-1:0] ARADDR_M0,
	output logic [AXI_LEN_BITS-1:0]  ARLEN_M0,
	output logic [AXI_SIZE_BITS-1:0] ARSIZE_M0,
	output logic [1:0]                ARBURST_M0,
	output logic                      ARVALID_M0,
	input                             ARREADY_M0,
	//READ DATA
	input  [AXI_ID_BITS-1:0]         RID_M0,
	input  [AXI_DATA_BITS-1:0]       RDATA_M0,
	input  [1:0]                      RRESP_M0,
	input                             RLAST_M0,
	input                             RVALID_M0,
	output logic                      RREADY_M0
);

// D cache
    logic  [31:0]  CD_out;
    logic  [31:0]  CD_addr;
    logic  [31:0]  CD_in;
    logic  [2:0]   CD_type;
    logic          CD_wait;
    logic          CD_req;
    logic          CD_write;

    logic          CD_wait_w;
    logic          CD_wait_r;
    logic  [2:0]   CD_core_type;
    assign CD_wait = CD_wait_w || CD_wait_r;

// I cache
    logic  [31:0]  CI_out;
    logic  [31:0]  CI_addr;
    logic  [31:0]  CI_in;
    logic  [2:0]   CI_type;
    logic          CI_wait;
    logic          CI_req;
    logic          CI_write;

// CPU signal
    logic          im_wait;
    logic  [31:0]  im_data;
    logic  [31:0]  im_addr;
    logic  [31:0]  dm_rdata;
    logic  [31:0]  dm_wdata;
    logic  [31:0]  dm_addr;
    logic  [3:0]   dm_web;
    logic          dm_oe;

// Data Memory (Master 1 )------------------------------------//
// Write ----------------------------------------------------//
    logic [2:0] state_w;
    logic [2:0] nstate_w;

    logic [31:0] dm_addr_reg;
    logic [31:0] dm_data_reg;
    logic [3:0]  dm_strb_reg;

    logic        rst;
    assign rst = ~RSTn;  

    parameter   IDLE     = 3'd0;
    parameter   AW_VALID = 3'd1;
    parameter   W_VALID  = 3'd2;
    parameter   BREADY   = 3'd3;
    parameter   RESP     = 3'd4;

    always_ff @(posedge CK) begin
        if(rst) begin
            state_w <= IDLE;
            dm_addr_reg <= 32'd0;
            dm_data_reg <= 32'd0;
            dm_strb_reg <= 4'b1111;
        end
        else begin
            state_w <= nstate_w;
            if(state_w == IDLE) begin
                dm_addr_reg <= CD_addr;
                dm_data_reg <= CD_in;
                dm_strb_reg <= dm_web;
            end
        end
    end

    always_comb begin
        case(state_w)
            IDLE:     nstate_w = (CD_req && CD_write)? AW_VALID : IDLE ;
            AW_VALID: nstate_w = (AWREADY_M1)? W_VALID : AW_VALID ;
            W_VALID:  nstate_w = (WREADY_M1)? BREADY : W_VALID ;
	        BREADY:   nstate_w = RESP;
            RESP:     nstate_w = (BVALID_M1)? IDLE : RESP;
            default:  nstate_w = IDLE;
        endcase
    end

    always_comb begin
	    AWID_M1    = 8'd1;	// 0 for IM, 1 for DM
        AWLEN_M1   = 4'd0;
        AWSIZE_M1  = 3'd2;
	    AWBURST_M1 = 2'd1;
        CD_wait_w  = 1'b1;
        case(state_w)
            IDLE : begin
                AWVALID_M1 = 1'b0;
		        AWADDR_M1  = 32'd0;
                WVALID_M1  = 1'b0;
	   	        WDATA_M1   = 32'd0;
                WLAST_M1   = 1'b0;
                BREADY_M1  = 1'b0;
                WSTRB_M1   = dm_strb_reg;
                CD_wait_w  = 1'b0;
            end
            AW_VALID : begin
                AWVALID_M1 = 1'b1;
		        AWADDR_M1  = dm_addr_reg;
		        WVALID_M1  = 1'b0;
                WSTRB_M1   = dm_strb_reg;
            end
            W_VALID : begin
                AWVALID_M1 = 1'b0;
                WVALID_M1  = 1'b1; 
                WDATA_M1   = dm_data_reg;
                WLAST_M1   = 1'b1;
                WSTRB_M1   = dm_strb_reg;
		        BREADY_M1  = 1'b0;
            end
            BREADY : begin
                WVALID_M1  = 1'b0;
                WLAST_M1   = 1'b0;
		        BREADY_M1  = 1'b0;
            end
            RESP : begin
        	    BREADY_M1  = 1'b1;
            end
        endcase
    end

// Read ----------------------------------------------------//
    logic [2:0] state_r;
    logic [2:0] nstate_r;

    logic [31:0] dm_addr_tmp;

    always_ff @(posedge CK) begin
        if(rst)
            dm_addr_tmp <= 32'd0;
        else if(state_r == IDLE)
            dm_addr_tmp <= CD_addr;
        else
            dm_addr_tmp <= dm_addr_tmp;
    end
    
    parameter   R_VALID  = 3'd1;
    parameter   R_READY  = 3'd2;
    parameter   WAITING  = 3'd3;
    parameter   AR_VALID = 3'd4;

    always_ff @(posedge CK) begin
        if(rst)
            state_r <= IDLE;
        else
            state_r <= nstate_r;
    end

    always_comb begin
        case(state_r)
            IDLE:    nstate_r = (CD_req && ~CD_write)? R_VALID : IDLE;
            R_VALID: nstate_r = WAITING;
	        WAITING: nstate_r = (ARREADY_M1)? R_READY : WAITING;
            R_READY: nstate_r = (RVALID_M1)? IDLE : R_READY;
            default: nstate_r = IDLE;
        endcase
    end

    always_comb begin
	    ARID_M1     = 4'd1;	// 0 for IM, 1 for DM
	    ARLEN_M1    = 4'd0; 
	    ARSIZE_M1   = 3'd2;
	    ARBURST_M1  = 2'd1;
        ARVALID_M1  = 1'b0;
        ARADDR_M1   = 32'd0;
        RREADY_M1   = 1'b0;
        CD_wait_r   = 1'b1;
        case(state_r)
            IDLE : begin
                CD_out       = 32'd0;
                CD_wait_r   = 1'b0;
                
            end
            WAITING: begin
                ARVALID_M1  = 1'b1;	
		        ARADDR_M1   = dm_addr_tmp;		
                
	        end
            R_READY : begin 
		        CD_out       = RDATA_M1;
		        RREADY_M1   = 1'b1;
            end
        endcase
    end


// Instruction Memory (Master 0)-----------------------------//
// Read -----------------------------------------------------//   

    logic [2:0] state_M0;
    logic [2:0] nstate_M0;

    logic [31:0] im_addr_tmp;

    always_ff @(posedge CK) begin
        if(rst)
            im_addr_tmp <= 32'd0;
        else if(state_M0 == IDLE)
            im_addr_tmp <= CI_addr;
        else
            im_addr_tmp <= im_addr_tmp;
    end

    always_ff @(posedge CK) begin
        if(rst)
            state_M0 <= IDLE;
        else
            state_M0 <= nstate_M0;
    end


    always_comb begin
        case(state_M0)
            IDLE:    nstate_M0 = (CI_req)? R_VALID : IDLE;
            R_VALID: nstate_M0 = WAITING;
            WAITING: nstate_M0 = (ARREADY_M0)? R_READY : WAITING;
            R_READY: nstate_M0 = (RVALID_M0)? IDLE : R_READY;
            default: nstate_M0 = IDLE;
        endcase
    end

    always_comb begin
        ARID_M0     = 8'd0;	// 0 for IM, 1 for DM
	    ARLEN_M0    = 4'd0;
        ARSIZE_M0   = 3'd2;
	    ARBURST_M0  = 2'd1;

        CI_wait     = 1'b1;
        case(state_M0)
	     IDLE: begin
                ARVALID_M0  = 1'b0;
		        RREADY_M0   = 1'b0;
                CI_wait     = 1'b0;
	     end
         R_VALID : begin
                ARVALID_M0  = 1'b0;
                RREADY_M0   = 1'b0;
         end
	     WAITING: begin
                ARVALID_M0  = 1'b1;	
	            ARADDR_M0   = CI_addr;
		        RREADY_M0   = 1'b0;	
	     end
         R_READY : begin
		        ARVALID_M0  = 1'b0;
		        RREADY_M0   = 1'b1;
         end
        endcase
    end

    always_ff @(posedge CK) begin
        if(rst) begin
            CI_out  <= 32'd0;
            //im_valid <= 1'b0;
        end
        else begin
            CI_out  <= (RVALID_M0)? RDATA_M0 : CI_out;
            //im_valid <= RVALID_M0;
        end
    end


// submodule ------------------------------------------------------//

    logic dm_wait;
    logic dm_write;
    assign dm_write = (dm_web != 4'd15)? 1'b1 : 1'b0;
    logic dm_req;
    assign dm_req = dm_write || dm_oe;

    always_comb begin
        case(dm_web)
            4'b0000:
                CD_core_type = `CACHE_WORD;
            4'b0011:
                CD_core_type = `CACHE_HWORD;
            4'b1100:
                CD_core_type = `CACHE_HWORD;
            4'b1110:
                CD_core_type = `CACHE_BYTE;
            4'b1101:
                CD_core_type = `CACHE_BYTE;
            4'b1011:
                CD_core_type = `CACHE_BYTE;
            4'b0111:
                CD_core_type = `CACHE_BYTE;
            default:
                CD_core_type = 3'd3;
        endcase
    end

	CPU CPU1 (
	  .clk          (CK         ),
	  .rst          (rst        ),
      .ext_interrupt(ext_interrupt),
	  .im_data      (im_data    ),
      .im_wait      (im_wait    ),
	  .im_addr      (im_addr    ),
	  .dm_rdata     (dm_rdata   ),
      .dm_wdata     (dm_wdata   ),
      .dm_wait      (dm_wait    ),
	  .dm_addr      (dm_addr    ),
	  .dm_web       (dm_web     ),  // active low
	  .dm_oe        (dm_oe      )
	);

    L1C_data L1CD (
      .clk          (CK        ),
      .rst          (rst       ),
      .core_addr    (dm_addr   ),
      .core_req     (dm_req    ),
      .core_write   (dm_write  ),
      .core_in      (dm_wdata  ),
      .core_type    (CD_core_type ),
    //
      .D_out        (CD_out    ),
      .D_wait       (CD_wait   ),
    //
      .core_out     (dm_rdata  ),
      .core_wait    (dm_wait   ),
    //
      .D_req        (CD_req    ),
      .D_addr       (CD_addr   ),
      .D_write      (CD_write  ),
      .D_in         (CD_in     ),
      .D_type       (CD_type   )
    );

    L1C_inst L1CI (
      .clk          (CK        ),
      .rst          (rst       ),
      .core_addr    (im_addr   ),
      .core_req     (1'b1      ),
      .core_write   (1'b0      ),
      .core_in      (32'd0     ),
      .core_type    (`CACHE_WORD),
    // Mem to CPU wrapper
      .I_out        (CI_out    ),
      .I_wait       (CI_wait   ),
    // CPU wrapper to core
      .core_out     (im_data   ),
      .core_wait    (im_wait   ),
    // CPU wrapper to Mem
      .I_req        (CI_req    ),
      .I_addr       (CI_addr   ),
      .I_write      (CI_write  ),
      .I_in         (CI_in     ),
      .I_type       (CI_type   )
    );

endmodule

