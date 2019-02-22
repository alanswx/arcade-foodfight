//
// foodfight
// fpga top
// Brad Parker <brad@heeltoe.com> 5/2014
//

module ff_top(
	      input 	   clk12m,
	      input 	   clk6m,
	      input 	   reset,
	      output 	   led1,
	      output 	   led2,
	      output 	   led3,
	      output 	   hsync,
	      output 	   vsync,
	      output 	   blank,
	      output [7:0] rgb,
	      output [7:0] audio,
	      output 	   clk_6mhz_o,
	      input [11:0] sw,
	      input [8:1]  sw1,
              input clk_100mhz,
              input [15:0] js_analog,
	      output [7:0] o_audioL,
	      output [7:0] o_audioR
	      );

   ff ff(
	 .clk_12mhz(clk12m),
	 .clk_6mhz(clk6m),
	 .reset(reset),
	 .test(sw[0]),
	 .throw2(sw[1]),
	 .throw1(sw[2]),
	 .coinaux(sw[3]),
	 .start2(sw[4]),
	 .start1(sw[5]),
	 .coin2(sw[6]),
	 .coin1(sw[7]),
	 .js_l(sw[8]),
	 .js_r(sw[9]),
	 .js_u(sw[10]),
	 .js_d(sw[11]),
	 .sw1(sw1),
	 .o_led1(led1),
	 .o_led2(led2),
	 .o_led3(led3),
	 .o_hsync(hsync),
	 .o_compsync(),
	 .o_vsync(vsync),
	 .o_blank(blank),
	 .o_rgb(rgb),
	 .o_audio(audio),
	 .o_clk_6mhz(clk_6mhz_o),
         .clk_100mhz(clk_100mhz),
         .js_analog(js_analog),
	 .o_audioL(o_audioL),
	 .o_audioR(o_audioR)
	 );
   
endmodule // ff_top
