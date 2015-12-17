
module ram_moram(input 	       p1_clk,
		 input [7:0]   p1_a,
		 input [15:0]  p1_di,
		 input 	       p1_r,
		 input 	       p1_w,
		 input 	       p2_clk,
		 input [7:0]   p2_a,
		 input 	       p2_r,
		 output [15:0] p1_do,
		 output [15:0] p2_do
);

   reg [15:0] ram[0:255];
   reg [15:0] d1, d2;
   
`ifdef debug
   integer    j;
   
   initial
     begin
	for (j = 0; j < 256; j = j + 1)
	  ram[j] = 0;
     end
`endif

   always @(posedge p1_clk)
     if (p1_r)
       d1 <= ram[p1_a];

   always @(posedge p1_clk)
     if (p1_w)
       ram[p1_a] <= p1_di;

   assign p1_do = d1;
   
   always @(posedge p2_clk)
     if (p2_r)
       d2 <= ram[p2_a];

   assign p2_do = d2;
   
endmodule