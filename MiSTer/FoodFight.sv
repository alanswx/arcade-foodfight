//============================================================================
//  FoodFight port to MiSTer
//  Copyright (c) 2019 alanswx
//
//   
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR
);

//`define SOUND_DBG
assign VGA_SL=0;

assign VGA_F1=0;
assign CE_PIXEL=1;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

//assign VIDEO_ARX = status[9] ? 8'd16 : 8'd4;
//assign VIDEO_ARY = status[9] ? 8'd9  : 8'd3;


assign VIDEO_ARX = 4;
assign VIDEO_ARY = 3;

assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign LED_DISK  = 0;
assign LED_POWER = 1;
assign LED_USER  = ioctl_download;

`include "build_id.v"
localparam CONF_STR = {
	"A.FFIGHT;;",
	"-;",
	"-;",
	"-;",
	"-;",
	"T6,Reset;",
	"J,Throw,Start 1P,Start 2P;",
	"V,v",`BUILD_DATE
};


wire [31:0] status;
wire  [1:0] buttons;
wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [7:0] ioctl_data;
wire  [7:0] ioctl_index;
reg         ioctl_wait=0;

reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [7:0] sd_buff_addr;
wire  [15:0] sd_buff_dout;
wire  [15:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire        forced_scandoubler;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire reset;
assign reset = (RESET | status[0] | status[6] | buttons[1] | ioctl_download);


hps_io #(.STRLEN(($size(CONF_STR)>>3) )/*, .PS2DIV(1000), .WIDE(0)*/) hps_io
(
	.clk_sys(CLK_VIDEO/*clk_sys*/),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),
	.joystick_0(joystick_0),
	.joystick_analog_0(analog_joy_0),

	.joystick_1(joystick_1),
	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.new_vmode(new_vmode),

	.status(status),
	.status_in({status[31:8],region_req,status[5:0]}),
	.status_set(region_set),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	.ioctl_wait(ioctl_wait),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	
	
	.ps2_key(ps2_key)
	//.ps2_mouse(ps2_mouse)
);


wire [15:0] analog_joy_0;
wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge CLK_VIDEO) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX75: btn_up          <= pressed; // up
			'hX72: btn_down        <= pressed; // down
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right
			'h029: btn_fire        <= pressed; // space
			'h014: btn_fire        <= pressed; // ctrl

			'h005: btn_one_player  <= pressed; // F1
			'h006: btn_two_players <= pressed; // F2
			'h00C: btn_test <= pressed; // F4
		endcase
	end
end

reg btn_up    = 0;
reg btn_down  = 0;
reg btn_right = 0;
reg btn_left  = 0;
reg btn_fire  = 0;
reg btn_one_player  = 0;
reg btn_two_players = 0;
reg btn_test = 0;

wire m_up     =  btn_up    | joy[3];
wire m_down   =  btn_down  | joy[2];
wire m_left   =  btn_left  | joy[1];
wire m_right  =  btn_right | joy[0];
wire m_fire   =  btn_fire  | joy[4];

wire m_start1 = btn_one_player  | joy[5];
wire m_start2 = btn_two_players | joy[6];
wire m_coin   = m_start1 | m_start2;

// Using the self test in MAME:
// 00000000 right
// 01111111 center (127)
// 11111111 left

// The joystick is from -128 to 127 with 0 as center from MiSTer
// we need to normalize from 0 to 255, and flip.

wire [7:0] joyx=8'd255-($signed(analog_joy_0[7:0])+8'd128); 
wire [7:0] joyy=8'd255-($signed(analog_joy_0[15:8])+8'd128); 

ff ff(
	  .clk_12mhz(clk12m),
	  .clk_6mhz(clk6m),
	  .reset(reset),
	  .test(~btn_test),
	  .throw2(1),
	  .throw1(~m_fire),
	  .coinaux(1),
	  .start2(~m_start2),
	  .start1(~m_start1),
	  .coin2(1),
	  .coin1(~m_coin),
	  .js_analog({joyy,joyx}),
	  .js_l(~m_left),
	  .js_r(~m_right),
	  .js_u(~m_up),
	  .js_d(~m_down),
	  .sw1(sw1), 
	  .o_led1(),
	  .o_led2(),
	  .o_led3(),
	  .o_hsync(hsync),
	  .o_compsync(),
	  .o_vsync(vsync),
	  .o_blank(blank),
	  .o_rgb(rgb),
	  .o_audio(audio),
	  .o_clk_6mhz()
	  );
/*

ff_top ff_top(
	      .clk12m(clk12m),
	      .clk6m(clk6m),
			.reset(RESET),
			.led1(led1),
			.led2(led2),
			.led3(led3),
			.hsync(hsync),
			.vsync(vsync),
			.blank(blank),
			.rgb(rgb),
			.audio(audio),
			.clk_6mhz_o(clk_6mhz_o),
			.sw(sw),
			.sw1(sw1) );
*/

wire [11:0] sw;
wire [8:1]  sw1;
wire [7:0] audio;

//   assign sw = { sw_js_d, sw_js_u, sw_js_r, sw_js_l,
//		 sw_coin1, sw_coin2, sw_start1, sw_start2,
//		 sw_coinaux, sw_throw1, sw_throw2, sw_test };

//stuck on start screen - 20 credits			
//assign sw = { ~m_down, ~m_up, ~m_right, ~m_left,
//		 ~m_coin, 1'b1, ~m_start1, 1'b1,
//		 1'b1, ~m_fire, 1'b1, 1'b1 };

assign sw = { ~m_down, ~m_up, ~m_left, ~m_right,
		 ~m_coin, 1'b1, ~m_start1, 1'b1,
		 1'b1, ~m_fire, 1'b1, ~btn_test };

assign sw1 = 8'hbf;
			
///////////////////////////////////////////////////
//wire clk_sys, clk_ram, clk_ram2, clk_pixel, locked;
wire clk_sys,locked,clk12m,clk6m;
wire hsync,vsync;

wire [7:0] rgb;

wire blank;



			


assign VGA_R={rgb[2:0],5'b00000};
assign VGA_G={rgb[5:3],5'b00000};
assign VGA_B={rgb[7:6],6'b000000};
assign VGA_HS=hsync;
assign VGA_VS=vsync;

assign VGA_DE=~(blank);
assign CLK_VIDEO=clk_sys;


/*
   scanconvert2_lx45 scanconv(
			      .clk6m(clk6m),
			      .clk12m(clk12m),
			      .clk25m(clk_sys),
			      .reset(reset),
			      .hsync_i(hsync),
			      .vsync_i(vsync),
			      .blank_i(blank),
			      .rgb_i(rgb),
			      .hsync_o(vga_hsync),
			      .vsync_o(vga_vsync),
			      .blank_o(vga_blank),
			      .rgb_o(vga_rgb)
			      );
		   wire 	  vga_hsync,vga_vsync,vga_blank;
			wire [7:0]vga_rgb;

assign VGA_R={vga_rgb[2:0],5'b00000};
assign VGA_G={vga_rgb[5:3],5'b00000};
assign VGA_B={vga_rgb[7:6],6'b000000};
assign VGA_HS=vga_hsync;
assign VGA_VS=vga_vsync;

assign VGA_DE=~(blank);
assign CLK_VIDEO=clk_sys;

*/


//assign AUDIO_L= {audio[1],7'b0};
//assign AUDIO_R= {audio[4],7'b0};
//assign AUDIO_L= {1'b0,audio[1] | audio[4],6'b0};
//assign AUDIO_R= {1'b0,audio[1] | audio[4],6'b0};


assign AUDIO_L={audio[1] | audio[4],audio[1] | audio[4],audio[1] | audio[4],audio[1] | audio[4],audio[1] | audio[4],1'b0,1'b0,1'b0,8'b00000000};
assign AUDIO_R={audio[1] | audio[4],audio[1] | audio[4],audio[1] | audio[4],audio[1] | audio[4],audio[1] | audio[4],1'b0,1'b0,1'b0,8'b00000000};

/*
wire dac_o;
   
ds_dac ds_output(.clk_i(CLK_50M),
		    .res_i(reset),
		    .dac_i(audio),
		    .dac_o(dac_o)
		    );

assign AUDIO_L={dac_o,dac_o,dac_o,dac_o,dac_o,1'b0,1'b0,1'b0,8'b00000000};
assign AUDIO_R={dac_o,dac_o,dac_o,dac_o,dac_o,1'b0,1'b0,1'b0,8'b00000000};
*/

/*
   wire sysclk_buf;
   //BUFG sysclk_bufg (.I(sysclk), .O(sysclk_buf));

   wire dcm_reset;

   wire led1;
   wire led2;
   wire led3;
   wire [7:0] audio;
   wire       cga_hsync, cga_vsync, cga_blank;
   wire [7:0] cga_rgb;
   wire [11:0] sw;
   wire [8:1]  sw1;

   wire       clk_vga;
   wire       clk_cpu;
   wire       clk_pix;
   wire       reset;

	
//   assign sw = { sw_js_d, sw_js_u, sw_js_r, sw_js_l,
//		 sw_coin1, sw_coin2, sw_start1, sw_start2,
//		 sw_coinaux, sw_throw1, sw_throw2, sw_test };
assign sw = { ~m_down, ~m_up, ~m_left, ~m_right,
		 ~m_coin, 1'b1, ~m_start1, 1'b1,
		 1'b1, ~m_fire, 1'b1, ~btn_test };


   assign sw1 = 8'hbf;

   assign led[1] = led1;
   assign led[2] = led2;
   assign led[3] = led3;
   assign led[4] = reset;
   assign led[5] = switch;

   wire hsync, vsync, blank;

   // video from scan converter
   wire [7:0] vga_rgb;
   wire [2:0] vga_rrr, vga_ggg, vga_bbb;

   // to hdmi
   assign vga_bbb = { vga_rgb[7], vga_rgb[6], 1'b0 };
   assign vga_ggg = { vga_rgb[5], vga_rgb[4], vga_rgb[3] };
   assign vga_rrr = { vga_rgb[2], vga_rgb[1], vga_rgb[0] };

   // to raw vga output
   assign vga_b = vga_rgb[7] | vga_rgb[6];
   assign vga_g = vga_rgb[5] | vga_rgb[4] | vga_rgb[3];
   assign vga_r = vga_rgb[2] | vga_rgb[1] | vga_rgb[0];

   wire clk6m, clk12m, clk25m;

   // game & cpu
   ff_top ff_top(
		 .clk12m(clk12m),
		 .clk6m(clk6m),
		 .reset(reset),
		 .led1(led1),
		 .led2(led2),
		 .led3(led3),
		 .hsync(cga_hsync),
		 .vsync(cga_vsync),
		 .blank(cga_blank),
		 .rgb(cga_rgb),
		 .audio(audio),
		 .sw(sw),
		 .sw1(sw1),
		 .clk_6mhz_o()
		 );

   // clocks and reset
   car_lx45 car(
		.sysclk(sysclk_buf),
		.clk_vga(clk_vga),
		.clk_cpu(clk_cpu),
		.clk_pix(clk_pix),
		.dcm_reset(dcm_reset),
		.button(switch),
		.reset(reset),
		.auto_coin_n(auto_coin_n),
		.auto_start_n(auto_start_n),
		.auto_throw_n(auto_throw_n),
		.clk6m(clk6m),
		.clk12m(clk12m),
		.clk25m(clk25m)
		);

   // cga -> vga
   scanconvert2_lx45 scanconv(
			      .clk6m(clk6m),
			      .clk12m(clk12m),
			      .clk25m(clk25m),
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
   
`ifdef sound
   //
   wire dac_o;
   
   ds_dac ds_output(.clk_i(sysclk_buf),
		    .res_i(reset),
		    .dac_i(audio),
		    .dac_o(dac_o)
		    );
assign AUDIO_L={dac_o,dac_o,dac_o,dac_o,dac_o,1'b0,1'b0,1'b0,8'b00000000};
assign AUDIO_R={dac_o,dac_o,dac_o,dac_o,dac_o,1'b0,1'b0,1'b0,8'b00000000};

 //  assign audio_l = dac_o;
 //  assign audio_r = dac_o;
`else
 //  assign audio_l = audio[1] | audio[4];
 //  assign audio_r = audio[1] | audio[4];
`endif
*/


//assign SDRAM_CLK=ram_clock;
pll pll (
	 .refclk ( CLK_50M   ),
	 .rst(0),
	 .locked ( locked    ),        // PLL is running stable
	 .outclk_0    (clk_sys), 		//25
	 .outclk_1     ( clk12m   ),      //12
	 .outclk_2     ( clk6m     )        // 6 MHz
	 );
	 
	 
	 
	 

endmodule
