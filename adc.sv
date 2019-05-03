// CSEE 4840 Final Project: working with DE1-soc ADC
//
// Spring 2019
//
// By: oscilloscope group
// Uni: <your unis here>


module adc( 	input logic 	CLOCK_50,

				output logic		ADC_CS_N,
				output logic 		ADC_SCLK,
				output logic 		ADC_DIN,
				output logic [6:0] 	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, 

				input logic		ADC_DOUT

	     );

	logic [11:0]	ADC_REG;

	logic    ADC_DoSth;
	
	logic	[3:0] disp0, disp1, disp2, disp3, disp4, disp5;


	clockdiv cd(.clk(CLOCK_50), .en(ADC_SCLK));
	
	dosomething ds(.clk(CLOCK_50), .en(ADC_DoSth));
	
	chipselect cs(.mclk(CLOCK_50), .ds(ADC_DoSth), .csn(ADC_CS_N));
	
	toADC data2ADC(.mclk(CLOCK_50), .ds(ADC_DoSth), .cs(ADC_CS_N), .din(ADC_DIN));
	
	fromADC data4mADC(.mclk(CLOCK_50), .ds(ADC_DoSth), .cs(ADC_CS_N), .dout(ADC_DOUT), .out(ADC_REG));

	bin2dec b2d(.bin_data(ADC_REG), .dec0(disp0), .dec1(disp1), .dec2(disp2), .dec3(disp3), .dec4(disp4), .dec5(disp5));
	
	hex7seg h0(.in(disp0), .out(HEX0));
	hex7seg h1(.in(disp1), .out(HEX1));
	hex7seg h2(.in(disp2), .out(HEX2));
	hex7seg h3(.in(disp3), .out(HEX3));
	hex7seg h4(.in(disp4), .out(HEX4));
	hex7seg h5(.in(disp5), .out(HEX5));

endmodule
	
module clockdiv(input logic clk, output logic en);

   parameter clockDivisor = 4'd 4 ;
   //register stores the value of clock cycles
   logic [3:0] i = 4'd 0; 

   always_ff @( posedge clk )  
   begin

     i <= i + 4'd 1;
     //resetting the clock
     if ( i >= (clockDivisor-1)) 
     begin  
      	i <= 4'd 0;
     end

   end

   assign en = (i<clockDivisor/2)?1'b0:1'b1;

endmodule


module dosomething(input logic clk, output logic en);

	logic [3:0] counter = 4'd 0; 
	logic up_down = 1'd 0;

	always_ff @( posedge clk )
	begin

		if(counter == 4'd 0 && up_down == 1'd 0)
		begin
			up_down <= 1'd 1;
			counter <= counter + 4'd 1;
		end
		else if(counter == 4'd 1 && up_down == 1'd 1)
		begin
			up_down <= 1'd 0;
			counter <= counter + 4'd 1;
		end
		else if (counter == 4'd 2 && up_down == 1'd 0)
		begin
			counter <= counter + 4'd 1;
		end
		else
		begin
			counter <= 4'd 0;
		end

	end

	assign en = up_down;

endmodule


module chipselect(input logic mclk, input logic ds, output logic csn);

	logic [5:0] counter_down = 6'd 0; //counter(we need 12 cycles of low, 1 cycle of high)
	logic [5:0] counter_up = 6'd 0;
	logic chipselect = 1'd 1; //to control the value of chipselect
	logic hold1, hold2, hold3; //to introduce a cycle of delay on chipselect
	
	
	always_ff @ ( posedge mclk )
	begin

		if(ds && counter_up <= 6'd 20 && counter_down == 6'd 0)
		begin
			chipselect <= 1'd 1;
			counter_up <= counter_up + 6'd 1;
		end
		
		else if(ds && counter_up == 6'd 21 && counter_down == 6'd 0)
		begin
			chipselect <= 1'd 0;
			counter_down <= counter_down + 6'd 1;
			counter_up <= 6'd 0;
		end

		else if(ds && counter_up == 6'd 0 && counter_down <= 6'd 12)
		begin
			chipselect <= 1'd 0;
			counter_down <= counter_down + 6'd 1;
		end

		else if(chipselect == 1'd 0 && counter_down == 6'd 13)
		begin
			counter_down <= 6'd 0;
			counter_up <= 6'd 0;
			chipselect <= 1'd 1;
		end	
		hold1 <= chipselect;
		hold2 <= hold1;
		hold3 <= hold2;
		
	end

	assign csn = hold3;

endmodule


//controls the D_in signal
module toADC (input logic mclk, input logic ds, input logic cs, output logic din);
//make a shift register to send data to ADC

	logic [5:0] shiftreg = 6'b 100010; //initialize shift reg to 0s
	logic [5:0] counter = 6'd 0;
	
	always_ff @ ( posedge mclk ) 
	begin

		if (!cs && ds && counter < 6'd 6 )
		begin
			din <= shiftreg[5];
			shiftreg [5:1] <= shiftreg[4:0];
			shiftreg [0] <= 1'd 0;
			counter <= counter + 6'd 1;
		end

		else if(counter == 6'd 6 && !ds && cs)
		begin
			din <= din;
			shiftreg <= 6'b 100010;
			counter <= 6'd 0;
		end
		
		else
			din <= din;

	end

endmodule

//controls the D_out signal
module fromADC (mclk, ds, cs, dout, out);

	input logic mclk, ds, cs, dout; 
	output logic [11:0] out;
	logic [5:0] counter = 6'd 0;

	logic [11:0] shiftreg;

	logic load_data = 1'd 1; //check this if we have issues displaying	
	
	always_ff @ ( posedge mclk )
	begin

		if (!cs && ds && counter <= 6'd 11)
		begin
			shiftreg = {shiftreg[10:0], dout};
			counter <= counter + 6'd 1;
			load_data <= 1'd 1;
		end

		else if(cs && !ds && load_data)
		begin
			//counter = 6'd 0; 
			//out <= shiftreg;
			out[11:0] <= shiftreg[11:0];
			counter = 6'd 0;
			load_data <= 1'd 0;
		end
		
	end 

endmodule 

module hex7seg (input logic [3:0] in, output logic [0:7] out);

	logic [6:0] pre_seg_dis;
	always @ (*)
	begin

		case(in)
		
			4'h1: pre_seg_dis = 7'b1111001;		
			4'h2: pre_seg_dis = 7'b0100100;		
			4'h3: pre_seg_dis = 7'b0110000;		
			4'h4: pre_seg_dis = 7'b0011001;		
			4'h5: pre_seg_dis = 7'b0010010;		
			4'h6: pre_seg_dis = 7'b0000010;		
			4'h7: pre_seg_dis = 7'b1111000;		
			4'h8: pre_seg_dis = 7'b0000000;		
			4'h9: pre_seg_dis = 7'b0011000;		
			4'ha: pre_seg_dis = 7'b0001000;
			4'hb: pre_seg_dis = 7'b0000011;		
			4'hc: pre_seg_dis = 7'b1000110;		
			4'hd: pre_seg_dis = 7'b0100001;		
			4'he: pre_seg_dis = 7'b0000110;		
			4'hf: pre_seg_dis = 7'b0001110;		
			4'h0: pre_seg_dis = 7'b1000000;				
		
		endcase

	end
	
	assign out = pre_seg_dis;

endmodule


module bin2dec (input logic [11:0] bin_data, output logic [3:0] dec0, output logic [3:0] dec1, output logic [3:0] dec2, output logic [3:0] dec3, output logic [3:0] dec4, output logic [3:0] dec5);

	always @ (*)
	begin
	dec0 = (bin_data*409600/4096 ) %10;
	dec1 = (bin_data*409600/4096 /10) %10;
	dec2 = (bin_data*409600/4096 /100) %10;
	dec3 = (bin_data*409600/4096 /1000) %10;
	dec4 = (bin_data*409600/4096 /10000) %10;
	dec5 = (bin_data*409600/4096 /100000) %10;
	end

endmodule

