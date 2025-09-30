`timescale 1ns/1ps

module tb_image_alu_ram_out;

    // Parâmetros da imagem
    parameter WIDTH       = 10'd4;
    parameter HEIGHT      = 10'd2;
    parameter FACTOR_IN   = 4'd4;

    reg [1:0] factor;

    reg clk, rst_n;
    reg [1:0] algo_sel;
    reg [7:0] color_in;
    wire [15:0] addr_out, row, col, addr_in;
    wire [7:0] data_out;
    wire wren, frame_done, unit_done, enable;
    wire [6:0] cntr;
    wire [15:0] sum;

    reg [3:0] FACTOR_OUT_reg;
    always @(*) begin
        case(factor)
            2'b00: begin
                FACTOR_OUT_reg = 4'd2;
                dx = cntr[0];
                dy = cntr[1];
                end
            2'b01: begin
                FACTOR_OUT_reg = 4'd4;
                dx = cntr[1:0];
                dy = cntr[3:2];
            end
            2'b10: begin
                FACTOR_OUT_reg = 4'd8;
                dx = cntr[2:0];
                dy = cntr[5:3];
            end
            default: begin
                FACTOR_OUT_reg = 4'd2;
                dx = cntr[0];
                dy = cntr[1];
            end
        endcase
    end

    wire [3:0] FACTOR_OUT = FACTOR_OUT_reg;
    wire [9:0] NEW_WIDTH_IN = WIDTH * FACTOR_IN;
    wire [9:0] NEW_HEIGHT_IN = HEIGHT * FACTOR_IN;
    wire [9:0] NEW_WIDTH_OUT = WIDTH / FACTOR_OUT;
    wire [9:0] NEW_HEIGHT_OUT = HEIGHT / FACTOR_OUT;
    reg [2:0] dx, dy;

    // RAM de saída behavioral
    reg [7:0] ram_out [0:63];
    wire [5:0] ram_addr = addr_out[5:0];

    always @(posedge clk) begin
        if (wren)
            ram_out[ram_addr] <= data_out;
    end

    // ROM/matriz inicial para teste
    reg [7:0] rom_in [0:64];
    integer i;
    
    initial begin
        
        for(i = 0; i < 64; i = i + 1)
            rom_in[i] = i+1;  // valores simples para teste
    end


    // Instancia ALU
    image_alu alu_inst (
        .FACTOR_IN(FACTOR_IN),
        .FACTOR_OUT(FACTOR_OUT),
        .NEW_HEIGHT_IN(NEW_HEIGHT_IN),
        .NEW_WIDTH_IN(NEW_WIDTH_IN),
        .NEW_HEIGHT_OUT(NEW_HEIGHT_OUT),
        .NEW_WIDTH_OUT(NEW_WIDTH_OUT),
        .clk(clk),
        .rst_n(rst_n),
        .algo_sel(algo_sel),
        .row(row),
        .col(col),
        .color_in(color_in),
        .addr_out(addr_out),
        .data_out(data_out),
        .wren(wren),
   
        .unit_done(unit_done),
        .enable(enable),
        .cntr(cntr),
        .sum(sum)
    );

    // Instancia UC
    generate_row_col uc_inst (
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .FACTOR_IN(FACTOR_IN),
        .FACTOR_OUT(FACTOR_OUT),
        .NEW_HEIGHT_IN(NEW_HEIGHT_IN),
        .NEW_WIDTH_IN(NEW_WIDTH_IN),
        .NEW_HEIGHT_OUT(NEW_HEIGHT_OUT),
        .NEW_WIDTH_OUT(NEW_WIDTH_OUT),
        .clk(clk),
        .rst_n(rst_n),
        .algo_sel(algo_sel),
        .alu_done(unit_done),
        .row(row),
        .col(col),
        .addr_in(addr_in), // ALU recebe o addr_out da UC
        .frame_done(frame_done),
        .enable(enable),
        .dx(dx),
        .dy(dy)
    );

    

    // Clock
    initial clk = 0;
    always #5 clk = ~clk; // 10ns período

    integer cycle_count;

    initial begin
        rst_n = 0;
        // 0 = block avg
        // 1 = NN zoom-in
        // 2 = NN zoom-out
        // 3 = pixel replication
        algo_sel = 2'd3; // Pixel replication
        cycle_count = 0;
        #20;
        rst_n = 1;
        factor = 2'b00;


        // Loop até terminar o frame
        while (!frame_done) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            // Lê o valor da ROM usando addr_out
            color_in = rom_in[addr_in[5:0]];

            // Imprime apenas quando wren ativo
            
                $display("row=%0d col=%0d addr_out=%0d wren=%b data_out=%0d unit_done=%0d cntr=%0d sum=%0d color_in=%0d dx=%0d dy=%0d",
                     row, col, addr_out, wren, data_out, unit_done, cntr, sum, color_in, cntr[2:0], cntr[5:3]);
        end

        $display("Simulação completa em %0d ciclos.", cycle_count);

        // Imprime conteúdo final da RAM de saída
        $display("Conteúdo final da RAM de saída:");
        for (integer i=0; i<64; i=i+1)
            $display("ram_out[%0d] = %0d", i, ram_out[i]);

        $display("Conteúdo da RAM de entrada:");
        for (integer i=0; i<64; i=i+1)
            $display("rom_in[%0d] = %0d", i, rom_in[i]);

        $display("nova altura = %0d", NEW_HEIGHT_IN);
        $display("Nova largura = %0d", NEW_WIDTH_IN);
        $finish;
    end

endmodule
