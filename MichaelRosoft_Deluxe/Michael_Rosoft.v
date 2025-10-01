module Michael_Rosoft(
	input clk,
	input start,
	input rst_n,
   input start_frame_btn,
   input [2:0]  		algo_sel,
   input [1:0]  		factor_out,
	output reg [7:0] red,     
   output reg [7:0] green,   
   output reg [7:0] blue,
   output reg hsync,
   output reg vsync,
   output reg sync,
   output clk_vga,
   output reg blank,
	output [9:0] LEDS
);
	
	 wire clk_25;

	 clock_div_2 div (
		.clk_in(clk),
		.clk_out(clk_25),
		.rst_n(1'b1)
	 );
	 
	 wire [7:0] redv, greenv, bluev;
	 wire hsyncv, vsyncv, syncv, blankv; 
	 wire [18:0] addr_in, addr_out, addr_geral, addr_vga;
	 wire [7:0] color_rom, color_alu, ram_out_color, vga_color;
	 wire wren, frame_ready;
	 wire [9:0] next_x, next_y;
	  
	 wire [9:0]  CURRENT_HEIGHT;
	 wire [9:0]  CURRENT_WIDTH;
	 
	wire [9:0] x_offset = (CURRENT_WIDTH == 10'd640) ? (10'd0) : ((10'd639 - CURRENT_WIDTH)/2);
   wire [9:0] y_offset = (CURRENT_HEIGHT == 10'd480) ? (10'd0) : ((10'd479 - CURRENT_HEIGHT)/2);
	
	assign addr_vga = (in_image) ? (next_y - y_offset)*CURRENT_WIDTH + (next_x - x_offset) : 19'd0;
	assign addr_geral = (frame_ready) ? addr_vga : addr_out;
	
	wire in_image = (next_x >= x_offset && next_x < x_offset + CURRENT_WIDTH) && (next_y >= y_offset && next_y < y_offset + CURRENT_HEIGHT);
	assign vga_color = (in_image) ? ram_out_color : 8'b00000000;
	
	wire clk_100;
	
	always@(clk_25)begin
		red <= redv;
		blue <= bluev;
		green <= greenv;
		hsync <= hsyncv;
		vsync <= vsyncv;
		sync <= syncv;
		blank <= blankv;
	end
	
	pll100mhz_0002 pll100mhz_inst (
		.refclk   (clk),   //  refclk.clk
		.rst      (1'b0),      //   reset.reset
		.outclk_0 (clk_100), // outclk0.clk
		.locked   ()    //  locked.export
	);
	
	ram_final final(
		 .address(addr_geral),
		 .clock(clk_100),
		 .data(color_alu),
		 .wren(wren),
		 .q(ram_out_color)
    );
	 
    // ROM/matriz inicial para teste
    ram_initial init(
		 .address(addr_in),
		 .clock(clk_100),
		 .data(8'b00000000),
		 .wren(1'b0),
		 .q(color_rom)
    );
	
	 coprocessor coprocessor_inst(
	 .clk(clk),
	 .rst_n(rst_n),
	 .start_frame_btn(start_frame_btn),
	 .algo_sel(algo_sel),
	 .factor_out(factor_out),
	 .color_in(color_rom),
	 .addr_in_ram(addr_in),
    .color_out(color_alu),
    .addr_out_ram(addr_out),
    .frame_ready(frame_ready),
    .wren(wren),
	 .CURRENT_WIDTH(CURRENT_WIDTH),
	 .CURRENT_HEIGHT(CURRENT_HEIGHT)
	 );
	 
	
	 vga_driver vga(
	 .clock(clk_25),
	 .reset(rst_n),
	 .color_in(vga_color), 				// Pixel color data (RRRGGGBB)
    .next_x(next_x), 				  	   	// x-coordinate of NEXT pixel that will be drawn
    .next_y(next_y),  							// y-coordinate of NEXT pixel that will be drawn
    .hsync(hsyncv),    		// HSYNC (to VGA connector)
    .vsync(vsyncv),    		// VSYNC (to VGA connctor)
    .red(redv),     			// RED (to resistor DAC VGA connector)
    .green(greenv),   		// GREEN (to resistor DAC to VGA connector)
    .blue(bluev),    		// BLUE (to resistor DAC to VGA connector)
    .sync(syncv),          // SYNC to VGA connector
    .clk(clk_vga),            // CLK to VGA connector
    .blank(blankv)        // BLANK to VGA connector
	 );
	 
endmodule