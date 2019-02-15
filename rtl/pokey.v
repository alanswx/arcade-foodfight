//
// foodfight
// pokey sound chip wrapper
// Brad Parker <brad@heeltoe.com> 5/2014
//

`define POKEY_ATOSM

`ifdef POKEY_ATOSM
 `include "../pokey/pokey_atosm.v"
`endif

module pokey(
	     input 	  phi2,
	     input 	  reset, 
	     input 	  r_w_n,
	     input 	  cs0_n,
	     input 	  cs1_n,
	     input [3:0]  a,
	     input [7:0]  d_in,
	     output [7:0] d_out,
	     input [7:0]  p,
	     output [7:0] aud
	     );

`ifdef POKEY_ATOSM
   wire stb;
   wire [7:0] audout;
   
   assign stb = ~cs0_n & ~cs1_n;
   assign aud = audout;
   
   pokey_atosm pokey(.rst_i(reset),
		     .clk_i(phi2),
		     .adr_i(a),
		     .dat_i(d_in),
		     .dat_o(d_out),
		     .we_i(r_w_n),
		     .stb_i(stb),
		     .ack_o(),
		     .irq(),
		     .audout(audout),
		     .p_i(p),
		     .key_code(8'b0), .key_pressed(1'b0), .key_shift(1'b0), .key_break(1'b0),
		     .serout(), .serout_rdy_o(), .serout_ack_i(),
		     .serin(8'b0), .serin_rdy_i(1'b0), .serin_ack_o()
		     );
`endif
   
endmodule // pokey
