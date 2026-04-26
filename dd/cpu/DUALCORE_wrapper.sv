//----------------include-----------------------//

module DUALCORE_wrapper(
    input CK,
    input RSTn,
    input ext_interrupt,
    // Data Memory (Master 1)------------------------//
    //WRITE ADDRESS
    output logic [`AXI_ID_BITS-1:0]   AWID_M1,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_M1,
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_M1,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_M1,
	output logic [1:0]                AWBURST_M1,
	output logic                      AWVALID_M1,
	input                             AWREADY_M1,
	//WRITE DATA
	output logic [`AXI_DATA_BITS-1:0] WDATA_M1,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_M1,
	output logic                      WLAST_M1,
	output logic                      WVALID_M1,
	input                             WREADY_M1,
	//WRITE RESPONSE
	input  [`AXI_ID_BITS-1:0]         BID_M1,
	input  [1:0]                      BRESP_M1,
	input                             BVALID_M1,
	output logic                      BREADY_M1,
	
	//READ ADDRESS
	output logic [`AXI_ID_BITS-1:0]   ARID_M1,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_M1,
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_M1,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M1,
	output logic [1:0]                ARBURST_M1,
	output logic                      ARVALID_M1,
	input                             ARREADY_M1,
	//READ DATA
	input  [`AXI_ID_BITS-1:0]         RID_M1,
	input  [`AXI_DATA_BITS-1:0]       RDATA_M1,
	input  [1:0]                      RRESP_M1,
	input                             RLAST_M1,
	input                             RVALID_M1,
	output logic                      RREADY_M1,

// Instruction Memory (Master 0)------------------//
	//READ ADDRESS
	output logic [`AXI_ID_BITS-1:0]   ARID_M0,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_M0,
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_M0,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M0,
	output logic [1:0]                ARBURST_M0,
	output logic                      ARVALID_M0,
	input                             ARREADY_M0,
	//READ DATA
	input  [`AXI_ID_BITS-1:0]         RID_M0,
	input  [`AXI_DATA_BITS-1:0]       RDATA_M0,
	input  [1:0]                      RRESP_M0,
	input                             RLAST_M0,
	input                             RVALID_M0,
	output logic                      RREADY_M0



);
//--------------------------declare ports--------------------------------//
logic rst;
assign rst = ~RSTn;
//coreA to arbiter
logic           A_Icache_req;
logic           A_Icache_write;
logic [31:0]    A_Icache_addr;
logic [31:0]    A_Icache_data;
logic [2:0]     A_Icache_type;
logic [1:0]     A_IESI_status;
logic           A_Dcache_req;
logic           A_Dcache_write;
logic [31:0]    A_Dcache_addr;
logic [31:0]    A_Dcache_data;
logic [2:0]     A_Dcache_type;
logic [1:0]     A_DESI_status;
//coreB to arbiter
logic           B_Icache_req;
logic           B_Icache_write;
logic [31:0]    B_Icache_addr;
logic [31:0]    B_Icache_data;
logic [2:0]     B_Icache_type;
logic [1:0]     B_IESI_status;
logic           B_Dcache_req;
logic           B_Dcache_write;
logic [31:0]    B_Dcache_addr;
logic [31:0]    B_Dcache_data;
logic [2:0]     B_Dcache_type;
logic [1:0]     B_DESI_status;
//L2 cache to L1 cache
// to coreA
logic           A_L2_Icache_wait;
logic [127:0]   A_L2_Icache_data;
logic           A_L2_Dcache_wait;
logic [127:0]   A_L2_Dcache_data;
// to coreB
logic           B_L2_Icache_wait;
logic [127:0]   B_L2_Icache_data;
logic           B_L2_Dcache_wait;
logic [127:0]   B_L2_Dcache_data;
//ARB output
logic [1:0]     ARB_Icache_grant;
logic [1:0]     ARB_Dcache_grant;
//arbiter to coreA
logic           A_ARB_Icache_dosnp;
logic [31:0]    A_ARB_Icache_addr;
logic           A_ARB_Icache_write;
logic [1:0]     A_ARB_IESI_status;
logic           A_ARB_Dcache_dosnp;
logic [31:0]    A_ARB_Dcache_addr;
logic           A_ARB_Dcache_write;
logic [1:0]     A_ARB_DESI_status;    
//arbiter to coreB 
logic           B_ARB_Icache_dosnp;
logic [31:0]    B_ARB_Icache_addr;
logic           B_ARB_Icache_write;
logic [1:0]     B_ARB_IESI_status;
logic           B_ARB_Dcache_dosnp;
logic [31:0]    B_ARB_Dcache_addr;
logic           B_ARB_Dcache_write;
logic [1:0]     B_ARB_DESI_status;
//for internal interrupt data switch between core
logic           A_B_int_interrupt;
logic           B_A_int_interrupt;
//for cache snoop data switch between core
logic           A_B_Icache_snp_hit;  
logic           A_B_Icache_snp_valid;  
logic           B_A_Icache_snp_hit;  
logic           B_A_Icache_snp_valid;
logic           A_B_Dcache_snp_hit;  
logic           A_B_Dcache_snp_valid;  
logic           B_A_Dcache_snp_hit;  
logic           B_A_Dcache_snp_valid;
//arbiter to L2 cache
logic           L2_ARB_Icache_req;
logic           L2_ARB_Icache_write;
logic [31:0]    L2_ARB_Icache_addr;
logic [31:0]    L2_ARB_Icache_data;
logic [2:0]     L2_ARB_Icache_type;
logic           L2_ARB_Dcache_req;
logic           L2_ARB_Dcache_write;
logic [31:0]    L2_ARB_Dcache_addr;
logic [31:0]    L2_ARB_Dcache_data;
logic [2:0]     L2_ARB_Dcache_type;
//L2 and AXI
logic           CD_req;
logic           CD_write;
logic [31:0]    CD_addr;
logic [31:0]    CD_data;
logic [2:0]     CD_type;
logic           CD_wait;
logic [31:0]    CD_out; //AXI input data

logic          CD_wait_w;
logic          CD_wait_r;
assign CD_wait = CD_wait_w || CD_wait_r;

logic  [31:0]  CI_out;
logic  [31:0]  CI_addr;
logic  [31:0]  CI_data;
logic  [2:0]   CI_type;
logic          CI_wait;
logic          CI_req;
logic          CI_write;
logic          A_core_wait;
logic          B_core_wait;

logic          L2_Icache_finish;
assign L2_Icache_finish = (A_L2_Icache_wait^B_L2_Icache_wait) ;
logic          L2_Dcache_finish;
assign L2_Dcache_finish = (A_L2_Dcache_wait^B_L2_Dcache_wait) ;
logic          L1_Dcache_finish;
always_comb begin
    if(ARB_Dcache_grant==2'b01)
        L1_Dcache_finish = ~A_core_wait;
    else if (ARB_Dcache_grant==2'b10)
        L1_Dcache_finish = ~B_core_wait;
    else L1_Dcache_finish = ~(A_core_wait&B_core_wait);
end
//assign L1_Dcache_finish = ~(A_core_wait&B_core_wait);
//--------------------------end declare ports----------------------------//
//--------------------------Master 1 Write-------------------------------//
logic [2:0]     state_w;
logic [2:0]     nstate_w;

logic [31:0]    dm_addr_reg;
logic [31:0]    dm_data_reg;
logic [3:0]     dm_strb_reg;

parameter   IDLE        = 3'd0;
parameter   AW_VALID    = 3'd1;
parameter   W_VALID     = 3'd2;
parameter   BREADY      = 3'd3;
parameter   RESP        = 3'd4;

always_ff @(posedge CK, posedge rst) begin
    if (rst)
        state_w <= IDLE;
    else 
        state_w <= nstate_w;
end
always_ff @(posedge CK, posedge rst) begin
    if (rst) begin
        dm_addr_reg <= 32'd0;
        dm_data_reg <= 32'd0;
        dm_strb_reg <= 4'b1111;
    end
    else if (state_w == IDLE) begin
        dm_addr_reg <= CD_addr;
        dm_data_reg <= CD_data;
        if(CD_type == `CACHE_WORD)
            dm_strb_reg <= 4'b0000;
        else if (CD_type == `CACHE_HWORD && CD_addr[1] == 1'b1)
            dm_strb_reg <= 4'b0011;
        else if (CD_type == `CACHE_HWORD && CD_addr[1] == 1'b0)
            dm_strb_reg <= 4'b1100;
        else if (CD_type == `CACHE_BYTE && CD_addr[1:0] == 2'b00)
            dm_strb_reg <= 4'b1110;
        else if (CD_type == `CACHE_BYTE && CD_addr[1:0] == 2'b01)
            dm_strb_reg <= 4'b1101;
        else if (CD_type == `CACHE_BYTE && CD_addr[1:0] == 2'b10)
            dm_strb_reg <= 4'b1011;
        else if (CD_type == `CACHE_BYTE && CD_addr[1:0] == 2'b11)
            dm_strb_reg <= 4'b0111;
        else
            dm_strb_reg <= 4'b1111;
    end
    else begin
        dm_addr_reg <= dm_addr_reg;
        dm_data_reg <= dm_data_reg;
        dm_strb_reg <= dm_strb_reg;
        
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
//--------------------------Master 1 Read-------------------------------//
    logic [2:0] state_r;
    logic [2:0] nstate_r;

    logic [31:0] dm_addr_tmp;

    always_ff @(posedge CK or posedge rst) begin
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
    always_ff @(posedge CK or posedge rst) begin
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
    logic [31:0]RDATA_reg;
    always_ff @(posedge CK, posedge rst) begin
        if(rst)begin
            RDATA_reg <= 32'b0;
        end
        else if (state_r == R_READY)begin
            RDATA_reg <= RDATA_M1;
        end
        else begin
            RDATA_reg <= RDATA_reg;
        end
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
                CD_out       = RDATA_reg;
                CD_wait_r   = 1'b0;
                
            end
            WAITING: begin
                ARVALID_M1  = 1'b1;	
		        ARADDR_M1   = dm_addr_tmp;		
                
	        end
            R_READY : begin 
		        CD_out       = RDATA_reg;
		        RREADY_M1   = 1'b1;
            end
        endcase
    end
//--------------------------Master 0 Read-------------------------------//
    logic [2:0] state_M0;
    logic [2:0] nstate_M0;

    logic [31:0] im_addr_tmp;

    always_ff @(posedge CK or posedge rst) begin
        if(rst)
            im_addr_tmp <= 32'd0;
        else if(state_M0 == IDLE)
            im_addr_tmp <= CI_addr;
        else
            im_addr_tmp <= im_addr_tmp;
    end

    always_ff @(posedge CK or posedge rst) begin
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

    always_ff @(posedge CK or posedge rst) begin
        if(rst) begin
            CI_out  <= 32'd0;
            //im_valid <= 1'b0;
        end
        else begin
            CI_out  <= (RVALID_M0)? RDATA_M0 : CI_out;
            //im_valid <= RVALID_M0;
        end
    end

CORE_A_wrapper COREA(
    .CK                 (CK                     ),
    .RSTn               (RSTn                   ),
    .ext_interrupt      (ext_interrupt          ), //don't know what it is
    .int_interrupt_I    (B_A_int_interrupt      ),
    .Icache_req         (A_Icache_req           ),
    .Icache_write       (A_Icache_write         ),
    .Icache_addr        (A_Icache_addr          ),
    .Icache_data        (A_Icache_data          ),
    .Icache_type        (A_Icache_type          ),
    .IESI_status        (A_IESI_status          ),
    .Dcache_req         (A_Dcache_req           ),
    .Dcache_write       (A_Dcache_write         ),
    .Dcache_addr        (A_Dcache_addr          ),
    .Dcache_data        (A_Dcache_data          ),
    .Dcache_type        (A_Dcache_type          ),
    .DESI_status        (A_DESI_status          ),
    //data from L2 cache
    .L2Icache_wait      (A_L2_Icache_wait       ),
    .L2Icache_data      (A_L2_Icache_data       ),
    .L2Dcache_wait      (A_L2_Dcache_wait       ),
    .L2Dcache_data      (A_L2_Dcache_data       ),
    //data from Arbiter
    .I_grant            (ARB_Icache_grant       ),
    .Ido_snoop          (A_ARB_Icache_dosnp     ),
    .Iaddr              (A_ARB_Icache_addr      ),
    .Iwrite             (A_ARB_Icache_write     ),
    .IB_ESI_status      (A_ARB_IESI_status      ),
    .D_grant            (ARB_Dcache_grant       ),
    .Ddo_snoop          (A_ARB_Dcache_dosnp     ),
    .Daddr              (A_ARB_Dcache_addr      ),
    .Dwrite             (A_ARB_Dcache_write     ),
    .DB_ESI_status      (A_ARB_DESI_status      ),
    //data switch between cores
    .I_snp_hit_I        (B_A_Icache_snp_hit     ),
    .I_snp_hit_valid_I  (B_A_Icache_snp_valid   ),
    .I_snp_hit_O        (A_B_Icache_snp_hit     ),
    .I_snp_hit_valid_O  (A_B_Icache_snp_valid   ),
    .D_snp_hit_I        (B_A_Dcache_snp_hit     ),
    .D_snp_hit_valid_I  (B_A_Dcache_snp_valid   ),
    .D_snp_hit_O        (A_B_Dcache_snp_hit     ),
    .D_snp_hit_valid_O  (A_B_Dcache_snp_valid   ),
    .int_interrupt_O    (A_B_int_interrupt      ),
    .A_core_wait        (A_core_wait            )

);
CORE_B_wrapper COREB(
    .CK                 (CK                     ),
    .RSTn               (RSTn                   ),
    .ext_interrupt      (ext_interrupt          ), //don't know what it is
    .int_interrupt_I    (A_B_int_interrupt      ),
    .Icache_req         (B_Icache_req           ),
    .Icache_write       (B_Icache_write         ),
    .Icache_addr        (B_Icache_addr          ),
    .Icache_data        (B_Icache_data          ),
    .Icache_type        (B_Icache_type          ),
    .IESI_status        (B_IESI_status          ),
    .Dcache_req         (B_Dcache_req           ),
    .Dcache_write       (B_Dcache_write         ),
    .Dcache_addr        (B_Dcache_addr          ),
    .Dcache_data        (B_Dcache_data          ),
    .Dcache_type        (B_Dcache_type          ),
    .DESI_status        (B_DESI_status          ),
    .L2Icache_wait      (B_L2_Icache_wait       ),
    .L2Icache_data      (B_L2_Icache_data       ),
    .L2Dcache_wait      (B_L2_Dcache_wait       ),
    .L2Dcache_data      (B_L2_Dcache_data       ),
    .I_grant            (ARB_Icache_grant       ),
    .Ido_snoop          (B_ARB_Icache_dosnp     ),
    .Iaddr              (B_ARB_Icache_addr      ),
    .Iwrite             (B_ARB_Icache_write     ),
    .IB_ESI_status      (B_ARB_IESI_status      ),
    .D_grant            (ARB_Dcache_grant       ),
    .Ddo_snoop          (B_ARB_Dcache_dosnp     ),
    .Daddr              (B_ARB_Dcache_addr      ),
    .Dwrite             (B_ARB_Dcache_write     ),
    .DB_ESI_status      (B_ARB_DESI_status      ),
    .I_snp_hit_I        (A_B_Icache_snp_hit     ),
    .I_snp_hit_valid_I  (A_B_Icache_snp_valid   ),
    .I_snp_hit_O        (B_A_Icache_snp_hit     ),
    .I_snp_hit_valid_O  (B_A_Icache_snp_valid   ),
    .D_snp_hit_I        (A_B_Dcache_snp_hit     ),
    .D_snp_hit_valid_I  (A_B_Dcache_snp_valid   ),
    .D_snp_hit_O        (B_A_Dcache_snp_hit     ),
    .D_snp_hit_valid_O  (B_A_Dcache_snp_valid   ),
    .int_interrupt_O    (B_A_int_interrupt      ),
    .B_core_wait        (B_core_wait            )
);

cache_arbiter I_arbiter(
    .clk                (CK                     ),
    .rst                (rst                    ),
    //signals from coreA cache
    .A_cache_req        (A_Icache_req           ),
    .A_cache_write      (A_Icache_write         ),
    .A_cache_addr       (A_Icache_addr          ),
    .A_cache_data       (A_Icache_data          ),
    .A_cache_type       (A_Icache_type          ),
    .A_ESI_status       (A_IESI_status          ),
    //signals feom coreB cache
    .B_cache_req        (B_Icache_req           ),
    .B_cache_write      (B_Icache_write         ),
    .B_cache_addr       (B_Icache_addr          ),
    .B_cache_data       (B_Icache_data          ),
    .B_cache_type       (B_Icache_type          ),
    .B_ESI_status       (B_IESI_status          ),
    //output for snoop
    //to coreA
    .A_do_snoop         (A_ARB_Icache_dosnp     ), 
    .A_addr             (A_ARB_Icache_addr      ), 
    .A_write            (A_ARB_Icache_write     ), 
    .A_B_ESI_status     (A_ARB_IESI_status      ),
    //to both core and L2 cache
    .grant              (ARB_Icache_grant       ), 
    //to coreB
    .B_do_snoop         (B_ARB_Icache_dosnp     ),
    .B_addr             (B_ARB_Icache_addr      ),
    .B_write            (B_ARB_Icache_write     ),
    .B_A_ESI_status     (B_ARB_IESI_status      ),
    //output for L2 cache
    .L2_cache_req       (L2_ARB_Icache_req      ),
    .L2_cache_write     (L2_ARB_Icache_write    ),
    .L2_cache_addr      (L2_ARB_Icache_addr     ),
    .L2_cache_data      (L2_ARB_Icache_data     ),
    .L2_cache_type      (L2_ARB_Icache_type     ),
    //input from L2 cache
    .L2_finish          (L2_Icache_finish       )
);
cache_arbiter D_arbiter(
    .clk                (CK                     ),
    .rst                (rst                    ),
    //signals from coreA cache
    .A_cache_req        (A_Dcache_req           ),
    .A_cache_write      (A_Dcache_write         ),
    .A_cache_addr       (A_Dcache_addr          ),
    .A_cache_data       (A_Dcache_data          ),
    .A_cache_type       (A_Dcache_type          ),
    .A_ESI_status       (A_DESI_status          ),
    .B_cache_req        (B_Dcache_req           ),
    .B_cache_write      (B_Dcache_write         ),
    .B_cache_addr       (B_Dcache_addr          ),
    .B_cache_data       (B_Dcache_data          ),
    .B_cache_type       (B_Dcache_type          ),
    .B_ESI_status       (B_DESI_status          ),
    .A_do_snoop         (A_ARB_Dcache_dosnp     ), 
    .A_addr             (A_ARB_Dcache_addr      ),
    .A_write            (A_ARB_Dcache_write     ), 
    .A_B_ESI_status     (A_ARB_DESI_status      ),
    //to both core and L2 cache
    .grant              (ARB_Dcache_grant       ), 
    .B_do_snoop         (B_ARB_Dcache_dosnp     ),
    .B_addr             (B_ARB_Dcache_addr      ),
    .B_write            (B_ARB_Dcache_write     ),
    .B_A_ESI_status     (B_ARB_DESI_status      ),
    .L2_cache_req       (L2_ARB_Dcache_req      ),
    .L2_cache_write     (L2_ARB_Dcache_write    ),
    .L2_cache_addr      (L2_ARB_Dcache_addr     ),
    .L2_cache_data      (L2_ARB_Dcache_data     ),
    .L2_cache_type      (L2_ARB_Dcache_type     ),
    .L2_finish          (L1_Dcache_finish       )
);

L2C_inst L2CI(
    .clk                (CK                     ),
    .rst                (rst                    ),
    //input from Arbitor
    .cache_arb_req      (L2_ARB_Icache_req      ),
    .cache_arb_write    (L2_ARB_Icache_write    ),
    .cache_arb_addr     (L2_ARB_Icache_addr     ),
    .cache_arb_data     (L2_ARB_Icache_data     ),
    .cache_arb_type     (L2_ARB_Icache_type     ),
    .cache_arb_grant    (ARB_Icache_grant       ),
    //input from AXI
    .L2_Icache_wait     (CI_wait                ),
    .AXI_data           (CI_out                 ),
    //output to AXI
    .L2_Icache_req      (CI_req                 ),
    .L2_Icache_write    (CI_write               ),
    .L2_Icache_addr     (CI_addr                ),
    .L2_Icache_data     (CI_data                ),
    .L2_Icache_type     (CI_type                ),
    //output to L1 cache
    .A_Icache_wait      (A_L2_Icache_wait       ),
    .B_Icache_wait      (B_L2_Icache_wait       ),
    .A_Icache_data      (A_L2_Icache_data       ), 
    .B_Icache_data      (B_L2_Icache_data       )
);
L2C_data L2CD(
    .clk                (CK                     ),
    .rst                (rst                    ),
    //input from Arbitor
    .cache_arb_req      (L2_ARB_Dcache_req      ),
    .cache_arb_write    (L2_ARB_Dcache_write    ),
    .cache_arb_addr     (L2_ARB_Dcache_addr     ),
    .cache_arb_data     (L2_ARB_Dcache_data     ),
    .cache_arb_type     (L2_ARB_Dcache_type     ),
    .cache_arb_grant    (ARB_Dcache_grant       ),
    //input from AXI
    .L2_Dcache_wait     (CD_wait                ),
    .AXI_data           (CD_out                 ),
    //output to AXI
    .L2_Dcache_req      (CD_req                 ),
    .L2_Dcache_write    (CD_write               ),
    .L2_Dcache_addr     (CD_addr                ),
    .L2_Dcache_data     (CD_data                ),
    .L2_Dcache_type     (CD_type                ),
    //output to L1 cache
    .A_Dcache_wait      (A_L2_Dcache_wait       ),
    .B_Dcache_wait      (B_L2_Dcache_wait       ),
    .A_Dcache_data      (A_L2_Dcache_data       ), 
    .B_Dcache_data      (B_L2_Dcache_data       )
);

endmodule

