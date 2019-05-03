/*
 * Avalon memory-mapped peripheral that generates VGA
 *
 * Stephen A. Edwards
 * Columbia University
 */

module vga_ball(input logic        clk,
	        input logic 	   reset,
		input logic [15:0]  writedata,
		input logic 	   write,
		input 		   chipselect,
		input logic [2:0]  address,

		output logic [7:0] VGA_R, VGA_G, VGA_B,
		output logic 	   VGA_CLK, VGA_HS, VGA_VS,
		                   VGA_BLANK_n,
		output logic 	   VGA_SYNC_n);

   logic [10:0]	   hcount;
   logic [9:0]     vcount;

   logic [7:0] 	   background_r, background_g, background_b;
   logic [10:0]     posX;
   logic [9:0]      posY;	
   logic [10:0]     dummy; 

   logic [1:0] flag;  
   logic [1:0] flag2;



//some variables for memory 

	      /*input logic        clk,*/
	      logic [9:0]  a1;
	      logic [15:0]  din1;
	      logic we1;
	      logic [15:0] dout1;

 	      logic [9:0]  a2;
	      logic [15:0]  din2;
	      logic we2;
	      logic [15:0] dout2;



//initializing the buffers
  //buffer 1
//memory m1(clk,a,din,we,dout);

// buffer 2 
   //memory m2( .* );

logic first;

logic [9:0] a_display;
logic [9:0] a_input;
logic [15:0] dout_display;
logic [15:0] din_input;
logic[1:0] we_input;

memory m1(clk, a1, din1, we1, dout1),
       m2(clk, a2, din2, we2, dout2);

always_comb begin
  if (first) begin
    a1 = a_display;
    a2 = a_input;
    din2 = din_input;
    dout_display = dout1;
    we1 = 1'b0;
    we2 = we_input;
  end else begin
    a1 = a_input;
    a2 = a_display;
    din2 =  dout1;
    dout_display =din_input;
    we1 = we_input;
    we2 =  1'b0;
  end
  end


/*
assign a1 = first ? a_display : 12'b0;
assign din1 = first ? 16'b0 : 16'b0;
assign we1 = first ? 1'b0 : we_input;

assign dout_display = first ? dout1 : dout2;*/

vga_counters counters(.clk50(clk), .*);

//initializing the buffers
  //buffer 1
//memory m1(clk,a,din,we,dout);
//memory m1(.*);



   always_ff @(posedge clk)
     if (reset) begin
	background_r <= 8'h0;
	background_g <= 8'h0;
	background_b <= 8'h80;
	
	posX <= 8'd50;
	posY <= 8'd50;
	flag <= 1'd0;
	flag2 <= 1'd0;
	dummy <= hcount;

	we_input<=0;
	//posX <= dout_display;
	first <=0;
	
     end else if (chipselect && write) begin
	first <=1;
	a_input<= a_input + 1'd1;
	if(a_input == 10'd200)begin
	a_input<= 1'd0;
        first<=0;
        end
       case (address)


// this part is irrelevant cause nothing is coming from software?
	/*
	 3'h0 : background_r <= writedata;
	 3'h1 : background_g <= writedata;
	 3'h2 : background_b <= writedata;
         3'h3 : posX <= writedata;
         3'h4 : posY <= writedata;
	 */

		
	 3'h0 : din_input<= writedata[10:0];
		
	 3'h1 : posY <= writedata[10:0];	
	


       endcase
	end

	

   always_comb begin
	a_display = hcount[10:1];
      {VGA_R, VGA_G, VGA_B} = {8'h0, 8'h0, 8'h0};
      if (VGA_BLANK_n )begin
	//if( (hcount[10:0]< posX+30) && (hcount[10:0] > posX-30) && (vcount[9:0]>posY-15) && (vcount[9:0] < posY + 15) )
	//if (((hcount[10:0] - posX)*(hcount[10:0]- posX)) + (4*(vcount[9:0]- posY)*(vcount[9:0]- posY)) < 900)
	//if ( (vcount[9:0] == posY) &&( (hcount[10:0]< posX+30) && (hcount[10:0] > posX-30) ) )
	if (dout_display[9:0] == vcount[9:0])
		{VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'hff};

	else if(vcount[9:0] == 150 )
		{VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'h00};

	else if ( (hcount[10:0]%30 == 0 || vcount[9:0]%15 == 0 ) && (vcount[9:0]<301) )
   		{VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'hff};

	//else if (dout[9:0] == vcount[9:0])
		//{VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'hff};

/*
	if (hcount[10:6] == 5'd3   &&
	    vcount[9:0]== 10'd1023)
	  {VGA_R, VGA_G, VGA_B} = {8'hff, 8'hff, 8'hff};*/
	

	else
	  {VGA_R, VGA_G, VGA_B} =
             //{background_r, background_g, background_b};
		{ 8'hff, 8'h00, 8'hff };
	end
       
   end
	       
endmodule

module vga_counters(
 input logic 	     clk50, reset,
 output logic [10:0] hcount,  // hcount[10:1] is pixel column
 output logic [9:0]  vcount,  // vcount[9:0] is pixel row
 output logic 	     VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 * HCOUNT 1599 0             1279       1599 0
 *             _______________              ________
 * ___________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */
   // Parameters for hcount
   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 32,
             HSYNC        = 11'd 192,
             HBACK_PORCH  = 11'd 96,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC +
                            HBACK_PORCH; // 1600
   
   // Parameters for vcount
   parameter VACTIVE      = 10'd 480,
             VFRONT_PORCH = 10'd 10,
             VSYNC        = 10'd 2,
             VBACK_PORCH  = 10'd 33,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC +
                            VBACK_PORCH; // 525

   logic endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;
       
   logic endOfField;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 10'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x5DF (0x57F)
   // 101 0010 0000 to 101 1101 1111
   assign VGA_HS = !( (hcount[10:8] == 3'b101) &
		      !(hcount[7:5] == 3'b111));
   assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 1'b0; // For putting sync on the green signal; unused
   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480
   // 110 0011 1111  1599	       10 0000 1100  524
   assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
			!( vcount[9] | (vcount[8:5] == 4'b1111) );

   /* VGA_CLK is 25 MHz
    *             __    __    __
    * clk50    __|  |__|  |__|
    *        
    *             _____       __
    * hcount[0]__|     |_____|
    */
   assign VGA_CLK = hcount[0]; // 25 MHz clock: rising edge sensitive
   
endmodule



// 16 X 8 synchronous RAM with old data read-during-write behavior
module memory(input logic        clk,
	      input logic [9:0]  a,
	      input logic [15:0]  din,
	      input logic 	 we,
	      output logic [15:0] dout);

//we have 1280 pixels, so 1280 digits coming in each of 16 bits
   
   logic [15:0] 			 mem [639:0];
   integer j;
   integer flag;
   initial begin

   for(j = 0; j < 639; j = j+1) 
	/*if (j%30==0 && flag ==1) begin
		flag = 0;
	end
	else if(j%30==0 && flag ==0)begin
		flag = 1;
	end

	if(flag ==0)begin
   		mem[j] = 16'd120;
	end
	else if(flag ==1)begin*/
   		mem[j] = 16'd180;
	//end

end

   always_ff @(posedge clk) begin
      if (we) mem[a] <= din;
      dout <= mem[a];
   end
        
endmodule
