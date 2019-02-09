//
// top end ff for verilator
//

`define sdl_display
`define USE_VGA
//`define USE_CGA

module ff_verilator;

   wire CLK/*verilator public_flat*/;
   wire clk25/*verilator public_flat*/;
   wire clk12/*verilator public_flat*/;
   wire clk6/*verilator public_flat*/;
   wire reset/*verilator public_flat*/;
   
   wire       hsync;
   wire       vsync;
   wire       blank;
   wire [7:0] rgb;
   
   wire       led1;
   wire       led2;
   wire       led3;
   wire [11:0] sw/*verilator public_flat*/;
   wire [8:1]  sw1/*verilator public_flat*/;
   

   
   //-------------------------------------------------------------------

   wire       cga_hsync, cga_vsync, cga_blank;
   wire [7:0] cga_rgb;
   wire       vga_hsync;
   wire       vga_vsync;
   wire       vga_blank;
   wire [7:0] vga_rgb;
   wire [7:0] audio;
   wire       clk_6mhz_o/*verilator public_flat_rd*/;

   ff_top uut(
	      .clk12m(clk12),
	      .clk6m(clk6),
	      .reset(reset),
	      .led1(led1),
	      .led2(led2),
	      .led3(led3),
	      .hsync(cga_hsync),
	      .vsync(cga_vsync),
	      .blank(blank),
	      .rgb(cga_rgb),
	      .audio(audio),
	      .clk_6mhz_o(clk_6mhz_o),
	      .sw(sw),
	      .sw1(sw1)
	      );

   // cga -> vga
   scanconvert2_lx45 scanconv(
			      .clk6m(clk6),
			      .clk12m(clk12),
			      .clk25m(clk25),
			      .reset(reset),
			      .hsync_i(cga_hsync),
			      .vsync_i(cga_vsync),
			      .blank_i(cga_blank),
			      .rgb_i(cga_rgb),
			      .hsync_o(vga_hsync),
			      .vsync_o(vga_vsync),
			      .blank_o(vga_blank),
			      .rgb_o(vga_rgb)
			      );

`ifdef sdl_display
   //
   import "DPI-C" function void dpi_vga_init(input integer h,
					     input integer v);

   import "DPI-C" function void dpi_vga_display(input integer vsync_,
						input integer hsync_,
    						input integer pixel_);

   wire      pixclk;
   assign pixclk = /*clk12*/clk25/*CLK*/;

   initial
     begin
	dpi_vga_init(800, 600);
     end

   wire [31:0] pxd;
   wire [31:0] hs;
   wire [31:0] vs;

   wire [2:0]  vgaBlue;
   wire [2:0]  vgaGreen;
   wire [2:0]  vgaRed;

`ifdef USE_VGA
   assign vgaBlue = { vga_rgb[7:6], 1'b0 };
   assign vgaGreen = vga_rgb[5:3];
   assign vgaRed = vga_rgb[2:0];

   assign pxd = { 24'b0, vgaBlue, vgaGreen[2:1], vgaRed };
//   assign pxd = { 24'b0, rgb };

   assign vs = {31'b0, ~vga_vsync};
   assign hs = {31'b0, ~vga_hsync};
`endif

`ifdef USE_CGA
   assign vgaBlue = { cga_rgb[7:6], 1'b0 };
   assign vgaGreen = cga_rgb[5:3];
   assign vgaRed = cga_rgb[2:0];

   assign pxd = { 24'b0, vgaBlue, vgaGreen[2:1], vgaRed };

   assign vs = {31'b0, ~cga_vsync};
   assign hs = {31'b0, ~cga_hsync};
`endif
   
   always @(posedge pixclk)
     dpi_vga_display(vs, hs, pxd);
`endif
   
endmodule // ff_cpu_test

