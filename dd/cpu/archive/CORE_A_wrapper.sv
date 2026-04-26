
module CORE_A_wrapper(
    input CK,
    input RSTn,
    input ext_interrupt,
    input int_interrupt_I,
    //data to arbiter
    output logic Icache_req,
    output logic Icache_write,
    output logic [31:0]Icache_addr,
    output logic [31:0]Icache_data,
    output logic [2:0]Icache_type,
    output logic [1:0]IESI_status,
    output logic Dcache_req,
    output logic Dcache_write,
    output logic [31:0]Dcache_addr,
    output logic [31:0]Dcache_data,
    output logic [2:0]Dcache_type,
    output logic [1:0]DESI_status,
    //data from L2 cache
    input L2Icache_wait,
    input [127:0]L2Icache_data,
    input L2Dcache_wait,
    input [127:0]L2Dcache_data,
    //data from Arbiter
    input [1:0]I_grant,
    input Ido_snoop,
    input [31:0]Iaddr,
    input Iwrite,
    input [1:0]IB_ESI_status,
    input [1:0]D_grant,
    input Ddo_snoop,
    input [31:0]Daddr,
    input Dwrite,
    input [1:0]DB_ESI_status,
    input I_snp_hit_I,
    input I_snp_hit_valid_I,
    output logic I_snp_hit_O,
    output logic I_snp_hit_valid_O,
    input D_snp_hit_I,
    input D_snp_hit_valid_I,
    output logic D_snp_hit_O,
    output logic D_snp_hit_valid_O,
    output logic int_interrupt_O,
    output logic A_core_wait
);

//--------------------------declare ports--------------------------------//
logic [31:0]    im_data;
logic           im_wait;
logic [31:0]    im_addr;
logic [31:0]    dm_rdata;
logic [31:0]    dm_wdata;
logic           dm_wait;
logic [31:0]    dm_addr;
logic [3:0]     dm_web;
logic           dm_oe;
logic [2:0]     dm_type;
logic dm_write;
assign dm_write = (dm_web != 4'd15)? 1'b1 : 1'b0;
logic rst;
assign rst = ~RSTn;
logic dm_req;
assign dm_req = dm_write || dm_oe;
assign A_core_wait = dm_wait;

always_comb begin
    case(dm_web)
        4'b0000:
            dm_type = `CACHE_WORD;
        4'b0011:
            dm_type = `CACHE_HWORD;
        4'b1100:
            dm_type = `CACHE_HWORD;
        4'b1110:
            dm_type = `CACHE_BYTE;
        4'b1101:
            dm_type = `CACHE_BYTE;
        4'b1011:
            dm_type = `CACHE_BYTE;
        4'b0111:
            dm_type = `CACHE_BYTE;
        default:
            dm_type = 3'd3;
    endcase
end


L1C_inst_A L1CI_A(
    .clk            (CK                 ),
    .rst            (rst                ),
    //data from cpu
    .core_addr      (im_addr            ),
    .core_req       (1'b1               ),
    .core_write     (1'b0               ),
    .core_in        (32'd0              ),
    .core_type      (`CACHE_WORD        ),
    //data to cpu
    .core_out       (im_data            ),
    .core_wait      (im_wait            ),
    //data from L2 cache
    .L2_DataIn         (L2Icache_data    ),
    .Icache_wait       (L2Icache_wait    ),
    //data from arbiter
    .ARB_grant      (I_grant            ),
    .ARB_do_snp     (Ido_snoop        ),
    .ARB_addr_I       (Iaddr            ),
    .ARB_write_I    (Iwrite           ),
    .ARB_status_I   (IB_ESI_status    ),
    //data to arbiter
    .ARB_req        (Icache_req       ),
    .ARB_addr_O      (Icache_addr      ),
    .ARB_write_O    (Icache_write     ),
    .ARB_out        (Icache_data      ),
    .ARB_type       (Icache_type      ),
    .ARB_status_O   (IESI_status      ),
    // from another L1 cache
    .snp_hit_I      (I_snp_hit_I        ),
    .snp_hit_valid_I(I_snp_hit_valid_I  ),
    // to another L1 cache
    .snp_hit_O      (I_snp_hit_O        ),
    .snp_hit_valid_O(I_snp_hit_valid_O  )    
);
L1C_data_A L1CD_A(
    .clk            (CK                 ),
    .rst            (rst                ),
    //data from cpu
    .core_addr      (dm_addr            ),
    .core_req       (dm_req             ),
    .core_write     (dm_write           ),
    .core_in        (dm_wdata           ),
    .core_type      (dm_type            ),
    //data from L2 cache
    .L2_DataIn         (L2Dcache_data    ),
    .Icache_wait       (L2Dcache_wait    ),
    //data to cpu
    .core_out       (dm_rdata           ),
    .core_wait      (dm_wait            ),
    //data to arbiter
    .ARB_req        (Dcache_req       ),
    .ARB_addr_O       (Dcache_addr      ),
    .ARB_write_O    (Dcache_write     ),
    .ARB_out        (Dcache_data      ),
    .ARB_type       (Dcache_type    ),
    .ARB_status_O   (DESI_status      ),
    //data from arbiter
    .ARB_grant      (D_grant            ),
    .ARB_do_snp     (Ddo_snoop        ),
    .ARB_addr_I       (Daddr            ),
    .ARB_write_I    (Dwrite           ),
    .ARB_status_I   (DB_ESI_status    ),
    //
    .snp_hit_I      (D_snp_hit_I        ),
    .snp_hit_valid_I(D_snp_hit_valid_I  ),
    //
    .snp_hit_O      (D_snp_hit_O        ),
    .snp_hit_valid_O(D_snp_hit_valid_O  )
);


CPU_A CPU1_A (
	  .clk            (CK             ),
	  .rst            (rst            ),
      .ext_interrupt  (ext_interrupt  ),
      .int_interrupt_I(int_interrupt_I),
	  .im_data        (im_data        ),
      .im_wait        (im_wait        ),
	  .im_addr        (im_addr        ),
	  .dm_rdata       (dm_rdata       ),
      .dm_wdata       (dm_wdata       ),
      .dm_wait        (dm_wait        ),
	  .dm_addr        (dm_addr        ),
	  .dm_web         (dm_web         ),  // active low
	  .dm_oe          (dm_oe          ),
      .int_interrupt_O(int_interrupt_O)
	);

endmodule

