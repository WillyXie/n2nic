// CSR two stage version

module CSR(
    input                  clk,
    input                  rst,
    input                  ext_interrupt,
    input                  stall,

	input        [2:0]     funct3,
	input        [4:0]     rd,			  // instr[11:7]
	input        [4:0]     uimm,		  // instr[19:15]
	input        [11:0]    addr,		  // instr[31:20]
	input        [31:0]    pc,
	input        [31:0]    reg_rs1,
    input                  csr_valid,
    input                  instr_valid,

	output logic [31:0]    csr_data,
	output logic           regwr_csr,
    output logic           csr_valid_o,
    output logic           trap_jump,
    output logic [31:0]    trap_addr,
    output logic           wfi_stall
);

// define ----------------------------------------------
parameter MSTATUS   = 12'h300;
parameter MIE       = 12'h304;
parameter MTVEC     = 12'h305;
parameter MEPC      = 12'h341;
parameter MIP       = 12'h344;
parameter MCYCLE    = 12'hB00;
parameter MINSTRET  = 12'hB02;
parameter MCYCLEH   = 12'hB80;
parameter MINSTRETH = 12'hB82;

parameter RW = 2'b01;
parameter RS = 2'b10;
parameter RC = 2'b11;

parameter MRET = 12'b001100000010;
parameter WFI  = 12'b000100000101;

// -----------------------------------------------------
//logic [31:0] csr_data; debug
logic [31:0] csr_rdata;
logic [31:0] csr_wdata;
logic [31:0] mask;

logic csr_wr_en;
logic mcycle_wenh, mcycle_wenl;
logic minstret_wenh, minstret_wenl;

logic int_taken, int_return;
logic wfi;
logic mret;
//debug added logic
logic [11:0] addr_q;
logic [2:0]  funct3_q;

// CSRs -----------------------------------------------
struct packed {
	logic [1:0] mpp;
	logic mpie;
	logic mie;
} mstatus;

struct packed {
	logic meie;
} mie;

struct packed {
	logic meip;
} mip;

logic [31:0] mepc;
logic [31:0] mcycle, mcycleh;
logic [31:0] minstret, minstreth;

// Read (first stage)------------------------------------------------

always_comb begin
    csr_rdata = 32'd0;
    if(addr == addr_q) csr_rdata = csr_wdata;   // forwarding
    else begin
        case(addr)
            MSTATUS : begin
                csr_rdata[3] = mstatus.mie;
                csr_rdata[7] = mstatus.mpie;
                csr_rdata[12:11] = mstatus.mpp;
            end
            MIE : begin
                csr_rdata[11] = mie.meie;
            end
            MTVEC : csr_rdata = 32'h0001_0000;
            MEPC  : csr_rdata = {mepc[31:2], 2'd0};
            MIP : begin
                csr_rdata[11] = mip.meip;
            end
            MCYCLE   : csr_rdata = mcycle;
            MINSTRET : csr_rdata = minstret;
            MCYCLEH  : csr_rdata = mcycleh;
            MINSTRETH: csr_rdata = minstreth;
        endcase
    end
end

always_ff @(posedge clk) begin
    if(rst || wfi_stall) begin
        mask        <= 32'd0;
        addr_q      <= 12'd0;
        funct3_q    <= 3'd0;
        csr_data    <= 32'd0;
        csr_wr_en   <= 1'b0;
        regwr_csr   <= 1'b0;
        csr_valid_o <= 1'b0;
    end
    else if(stall) begin
        mask        <= mask;
        addr_q      <= addr_q;
        funct3_q    <= funct3_q;
        csr_data    <= csr_data;
        csr_wr_en   <= csr_wr_en;
        regwr_csr   <= regwr_csr;
        csr_valid_o <= csr_valid_o;        
    end
    else begin
        mask        <= (funct3[2])? {27'd0, uimm} : reg_rs1 ;
        addr_q      <= addr;
        funct3_q    <= funct3;
        csr_data    <= csr_rdata;
        csr_wr_en   <= ~((funct3 == 3'b010 || funct3 == 3'b011) && uimm == 5'd0) && csr_valid;
        regwr_csr   <= ~(rd == 5'd0) && csr_valid;
        csr_valid_o <= csr_valid;
    end
end

// Write (second stage)-----------------------------------------------

always_comb begin
	case(funct3_q[1:0])
        RW : csr_wdata = mask;
		RS : csr_wdata = csr_data | mask;
		RC : csr_wdata = csr_data & (~mask);
		default : csr_wdata = mask;
  endcase
end


always_ff @(posedge clk) begin
	if(rst) begin
        mstatus.mie  <= 1'b0;
		mstatus.mpie <= 1'b0;
		mstatus.mpp  <= 2'b11;  // machine mode
		mip <= 1'b0;
		mie <= 1'b0;
	end
	else begin
		if(csr_wr_en) begin
			case(addr_q)
				MSTATUS : begin
					mstatus.mie  <= csr_wdata[3];
					mstatus.mpie <= csr_wdata[7];
                    mstatus.mpp  <= csr_wdata[12:11];
				end
				MIE  : mie.meie <= csr_wdata[11];
				MEPC : mepc <= {csr_wdata[31:2], 2'd0};
			endcase
		end
		else if(int_taken && mstatus.mie) begin
			mstatus.mpie <= mstatus.mie;
			mstatus.mie  <= 1'b0;
			mepc <= {pc[31:2], 2'b00};
		end
		else if(int_return) begin
			mstatus.mpie <= 1'b1;
			mstatus.mie  <= mstatus.mpie;
		end
		mip.meip <= ext_interrupt & mstatus.mie & mie.meie;
	end
end

// Core Interrupter ------------------------------------
always_ff @(posedge clk) begin
    if(rst)
        int_taken <= 1'b0;
    else
        int_taken <= |{mip};
end

// Trap Handle
always_comb begin
    if(int_taken) begin
        trap_jump = 1'b1;
        trap_addr = 32'h0001_0000;
    end
    else if(int_return) begin
        trap_jump = 1'b1;
        trap_addr = mepc;
    end
    else trap_jump = 1'b0;
end

assign wfi =  (addr == WFI) && csr_valid;
assign int_return = (addr == MRET) && csr_valid;

// wfi FSM ---------------------------------------------

logic state, nstate;
parameter IDLE = 1'b0;
parameter WAIT = 1'b1;

always_ff @(posedge clk) begin
    if(rst) state <= IDLE;
    else state <= nstate;
end

always_comb begin
    case(state)
        IDLE : nstate = (wfi)? WAIT : IDLE;
        WAIT : nstate = (int_taken)? IDLE : WAIT; 
    endcase
end

assign wfi_stall = (state == WAIT)? 1'b1 : 1'b0;

// counter ---------------------------------------------

// mcycle
assign mcycle_wenl = csr_wr_en && (addr_q == MCYCLE);
assign mcycle_wenh = csr_wr_en && (addr_q == MCYCLEH);

counter mcycle_count (
  .clk        (clk         ),
  .rst        (rst         ),
  .incr       (1'b1        ),
  .load_data  (csr_wdata   ),
  .load_low   (mcycle_wenl ),
  .load_high  (mcycle_wenh ),
  .count_low  (mcycle      ),
  .count_high (mcycleh     )
);

// minstret
assign minstret_wenl = csr_wr_en && (addr_q == MINSTRET);
assign minstret_wenh = csr_wr_en && (addr_q == MINSTRETH);

counter minstret_count (
  .clk        (clk           ),
  .rst        (rst           ),
  .incr       (instr_valid   ),
  .load_data  (csr_wdata     ),
  .load_low   (minstret_wenl ),
  .load_high  (minstret_wenh ),
  .count_low  (minstret      ),
  .count_high (minstreth     )
);

endmodule

