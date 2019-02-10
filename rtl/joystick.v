//
// fake the analog joystick using a 4 position joystick
//

module joystick(
		input 	      clk6m,
		input 	      reset,
		input 	      vblank,
		input 	      js_l,
		input 	      js_r,
		input 	      js_u,
		input 	      js_d,
		input [1:0]   a,
		input 	      wr_n,
		input 	      rd_n,
		input  [15:0] analog,
		output [15:0] data_out
		);

   reg [7:0] horiz, vert;
   reg [7:0] out;
   reg 	     hist;
   wire      rise;
   reg   [1:0] cur_a;

   always @(posedge clk6m)
     if (reset)
       hist <= 0;
     else
       hist <= vblank;

   assign rise = ~hist & vblank;

   always @(negedge clk6m)
     if (reset)
       horiz <= 127;
     else
       if (rise)
	 begin
	    if (~js_l)
	      begin
		 if (horiz > 0)
		   horiz <= horiz - 8'd1;
	      end
	    else
	      if (~js_r)
		begin
		 if (horiz < 255)
		   horiz <= horiz + 8'd1;
		end
	      else
		// centered
		begin
		   if (horiz > 127)
		     horiz <= horiz - 8'd1;
		   else
		     if (horiz < 127)
		       horiz <= horiz + 8'd1;
		end
	 end // if (rise)
   
   
   always @(negedge clk6m)
     if (reset)
       vert <= 127;
     else
       if (rise)
	 begin
	    if (~js_d)
	      begin
		 if (vert > 0)
		   vert <= vert - 8'd1;
	      end
	    else
	      if (~js_u)
		begin
		 if (vert < 255)
		   vert <= vert + 8'd1;
		end
	      else
		// centered
		begin
		   if (vert > 127)
		     vert <= vert - 8'd1;
		   else
		     if (vert < 127)
		       vert <= vert + 8'd1;
		end
	 end // if (rise)
   
   // i/o read
   always @(posedge clk6m)
     if (reset)
       out <= 0;
     else
	  begin
	    // the original AtoD would start the conversion on the wr_n signal
		 //  then it would wait 8 cycles to finish - and then flag that it was done, and output the values
		 // this might be hacky, we wait until we see the "read" signal, and then we output the value 
		 // based on the a value that was given when the start signal was sent.
	    if (wr_n==0)
		 begin
			cur_a = a;
		 end
       if (rd_n==0)
			begin
			case (cur_a)
		   2'b00: out <= 127;
	      2'b01: out <= analog[15:8];
	      2'b10: out <= 127;
	      2'b11: out <= analog[7:0];
			endcase
		end
	 end

   assign data_out = { 8'b0, out };
   
endmodule
