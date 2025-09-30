module generate_row_col(

    input [9:0] WIDTH,
    input [9:0] HEIGHT,
    input [9:0] NEW_HEIGHT_IN,
    input [9:0] NEW_WIDTH_IN,
    input [9:0] NEW_HEIGHT_OUT,
    input [9:0] NEW_WIDTH_OUT,
    input [3:0] FACTOR_IN,
    input [3:0] FACTOR_OUT,

    input  wire clk,
    input  wire rst_n,
    input  wire [2:0] dx, dy,
    input  wire [1:0] algo_sel,
    input  wire alu_done,             // indica que a ALU terminou o bloco/pixel
    output reg  [15:0] addr_in,
    output reg  [15:0] row,
    output reg  [15:0] col,
    output reg  frame_done,
    output reg  enable                 // sinal para ALU
);
    
    // Dimensões máximas dependendo do algoritmo
    wire [15:0] max_row = (algo_sel == 2'd1 || algo_sel == 2'd3) ? NEW_HEIGHT_IN : NEW_HEIGHT_OUT;
    wire [15:0] max_col = (algo_sel == 2'd1 || algo_sel == 2'd3) ? NEW_WIDTH_IN  : NEW_WIDTH_OUT;

    /*
    always @(posedge alu_done) begin
        enable <= 0;
    end
    */
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            row        <= 0;
            col        <= 0;
            addr_in    <= 0;
            frame_done <= 0;
            enable     <= 0;
        end else if (~frame_done) begin
            enable <= 1; // habilita a ALU

            // Apenas incrementa quando ALU termina o bloco
            if (alu_done) begin
                enable <= 0;

                case (algo_sel)
                    2'd0: begin
                        // Block averaging: percorre bloco de FACTOR_OUT x FACTOR_OUT

                        if (col == NEW_WIDTH_OUT-1) begin
                            col <= 0;
                            if (row == NEW_HEIGHT_OUT-1) begin
                                row <= 0;
                                frame_done <= 1;
                            end else row <= row + 1;
                        end else col <= col + 1;
                    end

                    2'd1: begin
                        // NN zoom in
                        if (col == NEW_WIDTH_IN-1) begin
                            col <= 0;
                            if (row == NEW_HEIGHT_IN-1) begin
                                row <= 0;
                                frame_done <= 1;
                            end else row <= row + 1;
                        end else col <= col + 1;
                    end

                    2'd2: begin
                        // NN zoom out
                        if (col == NEW_WIDTH_OUT-1) begin
                            col <= 0;
                            if (row == NEW_HEIGHT_OUT-1) begin
                                row <= 0;
                                frame_done <= 1;
                            end else row <= row + 1;
                        end else col <= col + 1;
                    end

                    2'd3: begin
                        // Pixel replication: percorre blocos de entrada
                        if (col == WIDTH-1) begin
                            col <= 0;
                            if (row == HEIGHT-1) begin
                                row <= 0;
                                frame_done <= 1;
                            end else row <= row + 1;
                        end else col <= col + 1;
                    end
                endcase
            end

            // Calcula endereço para a ALU de acordo com o algoritmo
            case(algo_sel)
                2'd0: addr_in <= (row*FACTOR_OUT + dy)*WIDTH + (col*FACTOR_OUT + dx);          // block avg
                2'd1: addr_in <= ((row / FACTOR_IN) * WIDTH) + (col / FACTOR_IN);
                2'd2: addr_in <= row*FACTOR_OUT*WIDTH + col*FACTOR_OUT;              // NN zoom out
                2'd3: addr_in <= (row)*WIDTH + (col);            // pixel replication
            endcase
        end
    end

endmodule
