module image_alu(

    input [9:0] NEW_HEIGHT_IN,
    input [9:0] NEW_WIDTH_IN,
    input [9:0] NEW_HEIGHT_OUT,
    input [9:0] NEW_WIDTH_OUT,
    input [3:0] FACTOR_IN,
    input [3:0] FACTOR_OUT,

    input  wire clk,
    input  wire rst_n,
    input  wire [1:0] algo_sel,        // 0: block avg, 1: nn zoom in, 2: nn zoom out, 3: pixel replication
    input  wire [15:0] row,            // da UC
    input  wire [15:0] col,            // da UC
    input  wire [7:0] color_in,        // pixel da RAM original
    input  wire enable,                // enable vindo da UC
    output reg  [15:0] addr_out,
    output reg  [7:0] data_out,
    output reg  wren,
    output reg  frame_done,
    output reg  unit_done,
    output [6:0] cntr,
    output state,
    output [15:0] sum
);

    // Contadores internos
    reg [6:0] cnt;  
    reg [10:0] dx, dy;
    reg [15:0] soma;

    assign sum = soma;
    assign cntr = cnt;

    // Tamanho de saída
    wire [15:0] new_width  = (algo_sel == 2'd1) ? NEW_WIDTH_IN :
                              (algo_sel == 2'd2) ? NEW_WIDTH_OUT :
                              (algo_sel == 2'd3) ? NEW_WIDTH_IN : NEW_WIDTH_OUT;

    wire [15:0] new_height = (algo_sel == 2'd1) ? NEW_HEIGHT_IN :
                              (algo_sel == 2'd2) ? NEW_HEIGHT_OUT :
                              (algo_sel == 2'd3) ? NEW_HEIGHT_IN : NEW_HEIGHT_OUT;

    localparam IDLE = 2'b00, RUN = 2'b01, PAUSE = 2'b10;
    reg state;
    
    // registrador extra para atraso de 1 ciclo no block averaging
    reg unit_done_d, pipe;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state       <= IDLE;
            cnt         <= 0;
            dx          <= 0;
            dy          <= 0;
            addr_out    <= 0;
            data_out    <= 0;
            wren        <= 0;
            frame_done  <= 0;
            unit_done   <= 0;
            unit_done_d <= 0;
            soma        <= 0;
            pipe        <= 1'b0;
        end else begin
            case(state)
                IDLE: begin
                    frame_done <= 0;
                    unit_done  <= 0;
                    unit_done_d <= 0;
                    cnt        <= 0; 
                    dx         <= 0; 
                    dy         <= 0;
                    soma       <= 0;
                    state      <= RUN;
                end

                PAUSE: begin
                    state <= RUN;
                end

                RUN: begin
                    if (enable) begin  // só processa quando a UC habilitar
                        unit_done <= 0;  
                        wren      <= 0;  

                        case(algo_sel)
                            2'd0: begin
                                if(~pipe)
                                    pipe <= 1'b1;
                                else begin
                                // block averaging: acumula soma
                                    soma <= soma + color_in;

                                    if (cnt == (FACTOR_OUT*FACTOR_OUT)-1) begin
                                        data_out = (soma+color_in) / (FACTOR_OUT*FACTOR_OUT);
                                        addr_out <= row * NEW_WIDTH_OUT + col;
                                        unit_done_d <= 1;  // sinal antecipado 1 ciclo antes do wren
                                        cnt <= cnt + 1;
                                    end else if (cnt == FACTOR_OUT*FACTOR_OUT) begin
                                        // agora escreve o resultado
                                        wren <= 1;
                                        unit_done <= 1;
                                        state <= PAUSE;
                                        cnt <= 0;
                                        soma <= 0;
                                        unit_done_d <= 0;
                                    end else begin
                                        cnt <= cnt + 1;
                                        pipe <= 1'b0;
                                    end
                                end
                            end

                            2'd1: begin
                                // NN Zoom-in
                                addr_out <= row*NEW_WIDTH_IN + (col);
                                data_out <= color_in;
                                wren <= 1;
                                unit_done <= 1;
                                state <= PAUSE;
                            end

                            2'd2: begin
                                // NN Zoom-out
                                addr_out <= row * NEW_WIDTH_OUT + col;
                                data_out <= color_in;
                                wren <= 1;
                                unit_done <= 1; 
                                state <= PAUSE;
                            end

                            2'd3: begin
                                // Pixel replication
                                addr_out <= (row*FACTOR_IN + dy)*NEW_WIDTH_IN + (col*FACTOR_IN + dx);
                                data_out <= color_in;
                                wren <= 1;
                                if (dx == FACTOR_IN-1 && dy == FACTOR_IN-1) begin
                                    unit_done <= 1;
                                    state <= PAUSE;
                                    dx <= 0; dy <= 0;
                                end else begin
                                    if (dx == FACTOR_IN-1) begin dx<=0; dy<=dy+1; end
                                    else dx <= dx+1;
                                end
                            end
                        endcase

                        // Garante que wren só é ativado 1 ciclo após preparar data_out no block averaging
                        if (algo_sel == 2'd0) begin
                            wren <= unit_done_d;
                        end

                    end else begin
                        wren      <= 0;
                        unit_done <= 0;
                        unit_done_d <= 0;
                    end
                end
            endcase
        end
    end
endmodule
