//
//
//

module scanconvert2_lx45(
			 input 	      clk6m,
			 input 	      clk12m,
			 input 	      clk25m,
			 input 	      reset,
			 input 	      hsync_i,
			 input 	      vsync_i,
			 input 	      blank_i,
			 input [7:0]  rgb_i,
			 output       hsync_o,
			 output       vsync_o,
			 output       blank_o,
			 output [7:0] rgb_o
			);

   // ----------------------------------------------------
   // cga-ish 512x253
   
   wire [16:0] cga_ram_addr;
   wire [7:0]  cga_data;
   wire        cga_we;
   wire        cga_visable;

   reg [10:0]  cga_hcount;
   reg [10:0]  cga_vcount;

   reg 	      hsync_i_d, vsync_i_d;
   wire       hsync_i_fall, vsync_i_fall;

   always @(posedge clk12m)
     if (reset)
       begin
	  hsync_i_d <= 0;
	  vsync_i_d <= 0;
       end
     else
       begin
	  hsync_i_d <= hsync_i;
	  vsync_i_d <= vsync_i;
       end

   assign hsync_i_fall = hsync_i_d & ~hsync_i;
   assign vsync_i_fall = vsync_i_d & ~vsync_i;

   //
   always @(posedge clk12m)
     if (reset)
       begin
	  cga_hcount <= 0;
	  cga_vcount <= 0;
       end
     else
       begin
	  if (hsync_i_fall)
	    cga_hcount <= 0;
	  else
	    cga_hcount <= cga_hcount + 10'd1;

	  if (vsync_i_fall)
	    cga_vcount <= 0;
	  else
	    if (hsync_i_fall)
	      cga_vcount <= cga_vcount + 11'd1;
       end
   
   assign cga_visable = (cga_hcount < 624) && (cga_vcount < 253);

   // -------------------------------------------------
   // vga 640x480
   //
   // mapping 2x
   //  320x200 -> 640x400
   //
   wire [16:0] vga_ram_addr;
   wire [7:0]  vga_data;
   wire        vga_ce;
   wire        vga_visable;
   
   reg [10:0] vga_hcount;
   reg [10:0] vga_vcount;
   wire       vga_hsync;
   wire       vga_vsync;

   wire [9:0] r_addr;
   reg [7:0]  rgb_data;

   
   //
   // output is 2x hsync rate of input
   //
   // input	--l0-- --l1-- --l2-- --l3-- ...
   // output	xx-xx- l0-l0- l1-l1- l2-l2- ...
   //

   always @(posedge clk25m)
     if (reset)
       begin
	  vga_hcount <= 0;
	  vga_vcount <= 11'h7ff;
       end
     else
       begin
	  if (vga_hcount == 800-1)
	    vga_hcount <= 0;
	  else
	    vga_hcount <= vga_hcount + 10'd1;

	  if (vga_vcount == 525-1)
	    vga_vcount <= 0;
	  else
	    if (vga_hcount == 799)
	      vga_vcount <= vga_vcount + 11'd1;
       end

   assign vga_visable = (vga_hcount < 514/*640*/) && (vga_vcount < 255/*525*/)/* && (vga_vcount > 32)*/;
   
   assign vga_hsync = (vga_hcount >= (640+16) & vga_hcount <= (640+16+96));
   assign vga_vsync = (vga_vcount >= (480+10) & vga_vcount <= (480+10+2));

   assign hsync_o = ~vga_hsync;
   assign vsync_o = ~vga_vsync;
   assign blank_o = 1'b0;


   // ----------------------------------------------------

//   assign cga_ram_addr = { cga_vcount[7:0], cga_hcount[8:0] };
//   assign cga_we_n = cga_visable;

   wire [10:0] cga_hcount_offset;
   assign cga_hcount_offset = cga_hcount - 11'd110;
   
   assign cga_ram_addr = { cga_vcount[7:0], cga_hcount_offset[8:0] };
   assign cga_we = cga_visable && (cga_hcount >= 11'd110);
   assign cga_data = rgb_i;
   
   assign vga_ram_addr = { vga_vcount[7:0], vga_hcount[8:0] };
   assign vga_ce = vga_visable;
   assign rgb_o = vga_visable ? vga_data : 8'hff;
   
   ram_dp128kx8 scan_ram(
			 .rclk(clk25m),
			 .wclk(clk6m),
			 .ai(cga_ram_addr),
			 .i(cga_data),
			 .w(cga_we),
			 .ao(vga_ram_addr),
			 .o(vga_data),
			 .r(vga_ce)
			 );
   
   
endmodule
