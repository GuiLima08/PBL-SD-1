
module alu (
    input  wire        clk,          // clock 50 MHz
    input  wire        rst_n,        // reset em nível baixo
    input  wire        start,        // sinal de início vindo da UC
    input  wire [2:0]  algo_sel,     // algoritmo selecionado
    input  wire [3:0]  FACTOR_IN,    // fator de ampliação
    input  wire [3:0]  FACTOR_OUT,   // fator de redução
    input  wire [9:0]  ORIGINAL_WIDTH,   // largura original da imagem
    input  wire [9:0]  ORIGINAL_HEIGHT,  // altura original da imagem
    input  wire [7:0]  color_in,     // pixel lido da RAM
    output reg  [18:0] addr_in,     // endereço para ler o pixel da RAM
    output reg  [18:0] addr_out,   // endereço para escrever o pixel na RAM
    output reg  [7:0]  data_out,   // pixel a ser escrito na RAM
    output reg         wren,        // sinal de escrita na RAM
    output reg         alu_process_done,  // sinal de fim de processamento
	 output wire [9:0]  CURRENT_HEIGHT,   // altura atual da imagem com base no fator/algoritmo
	 output wire [9:0]  CURRENT_WIDTH     // largura atual da imagem com base no fator/algoritmo
);

	
    // Contadores principais
    reg [15:0] row, col;  
    reg [7:0]  cnt;       
    reg [15:0] sum;       

    // FSM states
    localparam IDLE        	= 4'd0,   // estado de espera
               FETCH       	= 4'd1,   // estado de busca do pixel
               WAIT_FETCH  	= 4'd2,   // estado de espera da leitura do pixel (atraso da RAM)
               PREPARATION 	= 4'd3,   // estado de preparação do pixel (soma para block average)
               CALC_ADDRESS = 4'd4,   // estado de cálculo do endereço de escrita
			   WRITE  	   	= 4'd5,   // estado de escrita do pixel na RAM
               NEXT        	= 4'd6,   // estado de calculo do próximo pixel
               DONE        	= 4'd7,   // estado de fim de processamento
			   WAIT_DONE   	= 4'd8;   // garante que o sinal de done fique alto por um ciclo

    // Algoritmos
    localparam [2:0] BLOCK_AVG     = 3'b000;
    localparam [2:0] NN_ZOOM_IN    = 3'b001;
    localparam [2:0] NN_ZOOM_OUT   = 3'b010;
    localparam [2:0] PIXEL_REP     = 3'b011;

    reg [3:0] state;

    // Dimensões da imagem de saída
    wire [9:0] NEW_WIDTH  = (algo_sel==BLOCK_AVG || algo_sel==NN_ZOOM_OUT) ? ORIGINAL_WIDTH/FACTOR_OUT : (algo_sel==NN_ZOOM_IN || algo_sel==PIXEL_REP) ? ORIGINAL_WIDTH*FACTOR_IN : ORIGINAL_WIDTH;
	wire [9:0] NEW_HEIGHT  = (algo_sel==BLOCK_AVG || algo_sel==NN_ZOOM_OUT) ? ORIGINAL_HEIGHT/FACTOR_OUT : (algo_sel==NN_ZOOM_IN || algo_sel==PIXEL_REP) ? ORIGINAL_HEIGHT*FACTOR_IN : ORIGINAL_HEIGHT;

	assign CURRENT_WIDTH[9:0] = NEW_WIDTH[9:0];
	assign CURRENT_HEIGHT[9:0] = NEW_HEIGHT[9:0];
	 
	 
    // dx/dy derivados de cnt
    wire [3:0] dx_blockavrg = cnt % FACTOR_OUT;
    wire [3:0] dy_blockavrg = cnt / FACTOR_OUT;

    reg [3:0] dx_rep, dy_rep;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state     <= IDLE;
            row       <= 0;
            col       <= 0;
            cnt       <= 0;
            sum       <= 0;
            addr_in   <= 0;
            addr_out  <= 0;
            data_out  <= 0;
            wren      <= 0;
            alu_process_done <= 0;
        end else begin
            case(state)

                //-------------------------------------
                IDLE: begin
                    wren      <= 0;
                    alu_process_done <= 0;
                    sum       <= 0;
                    cnt       <= 0;
                    row       <= 0;
                    col       <= 0;
                    if (start) state <= FETCH;
                end

                //-------------------------------------
                FETCH: begin
                    case(algo_sel)
                        PIXEL_REP: 
                            addr_in <= row * ORIGINAL_WIDTH + col;
                        BLOCK_AVG: 
                            addr_in <= (row*FACTOR_OUT + dy_blockavrg) * ORIGINAL_WIDTH + (col*FACTOR_OUT + dx_blockavrg); 
                        NN_ZOOM_IN: 
                            addr_in <= (row/FACTOR_IN) * ORIGINAL_WIDTH + (col/FACTOR_IN);           
                        NN_ZOOM_OUT: 
                            addr_in <= (row*FACTOR_OUT)*ORIGINAL_WIDTH + (col*FACTOR_OUT);   
								default:
									addr_in <= row * ORIGINAL_WIDTH + col;
                    endcase
                    state <= WAIT_FETCH;
                end

                //-------------------------------------
                WAIT_FETCH: begin                       //AQUI DEPENDE DO ATRASO DA LEITURA DO COLOR_IN NA RAM
                    state <= PREPARATION;
                end

                //-------------------------------------
                PREPARATION: begin
                    case(algo_sel)
                        BLOCK_AVG: begin 
                            sum <= sum + color_in;
                            if (cnt == FACTOR_OUT*FACTOR_OUT-1) begin  
                                state <= CALC_ADDRESS;
                            end else begin
                                cnt <= cnt + 1;
                                state <= FETCH;  //pega o próximo pixel do bloco
                            end
                        end
                        default: begin
                            data_out <= color_in;
                            state    <= CALC_ADDRESS;
                        end
                    endcase
                end

                //-------------------------------------
                CALC_ADDRESS: begin
                   
                    
                    case(algo_sel) 

                        NN_ZOOM_IN, NN_ZOOM_OUT: begin
                            addr_out <= row * NEW_WIDTH + col;
                            data_out <= color_in;
                        end

                        BLOCK_AVG: begin
                            addr_out <= row * NEW_WIDTH + col;
                            data_out <= sum / (FACTOR_OUT*FACTOR_OUT);
                        end

                        PIXEL_REP: begin
                            addr_out <= (row*FACTOR_IN + dy_rep)*NEW_WIDTH + (col*FACTOR_IN + dx_rep);
                            data_out <= color_in;
                        end
								
						default: begin
                            addr_out <= row * ORIGINAL_WIDTH + col;
                            data_out <= color_in;
                        end
                    endcase

                    state <= WRITE;
                end

                WRITE: begin
                    wren  <= 1;
                    state <= NEXT;
                end

                //-------------------------------------
                NEXT: begin
                    wren      <= 0;
                    sum       <= 0;
                    cnt       <= 0;

                    case(algo_sel)
    
                        BLOCK_AVG, NN_ZOOM_IN, NN_ZOOM_OUT: begin
                            if (col == NEW_WIDTH - 1) begin
                                col <= 0;
                                if (row == NEW_HEIGHT - 1) begin
                                    row <= 0;
                                    state <= DONE;
                                end else begin 
                                    row <= row + 1;
                                    state <= FETCH;
                                end
                            end else begin
                                col <= col + 1;
                                state <= FETCH;
                            end
                        end

                        PIXEL_REP: begin
                            if (dx_rep == FACTOR_IN-1 && dy_rep == FACTOR_IN-1) begin //primeiro incrementa dx --> dy --> coluna --> linha
                                dx_rep <= 0;
                                dy_rep <= 0;

                                if (col == ORIGINAL_WIDTH-1) begin
                                    col <= 0;
                                    if (row == ORIGINAL_HEIGHT-1) begin
                                        row <= 0;
                                        state <= DONE;
                                    end else begin 
                                        row <= row + 1;
                                        state <= FETCH;
                                    end
                                end else begin
                                    col <= col + 1;
                                    state <= FETCH;
                                end

                            end else begin
                                if (dx_rep == FACTOR_IN-1) begin
                                    dx_rep <= 0;
                                    dy_rep <= dy_rep + 1;
                                end else begin
                                    dx_rep <= dx_rep + 1;
                                end
                                state <= CALC_ADDRESS; //NAO PRECISA DE FETCH DE COLOR_IN POIS É O MESMO, REDUZINDO CICLOS
                            end
                        end
								
						default: begin

                            if (col == ORIGINAL_WIDTH - 1) begin
                                col <= 0;
                                if (row == ORIGINAL_HEIGHT - 1) begin
                                    row <= 0;
                                    state <= DONE;
                                end else begin 
                                    row <= row + 1;
                                    state <= FETCH;
                                end
                            end else begin
                                col <= col + 1;
                                state <= FETCH;
                            end

                        end
                    endcase
                end

                //-------------------------------------
                DONE: begin
                    alu_process_done <= 1;
                    state <= WAIT_DONE;
                end

					 WAIT_DONE: begin
						  state <= IDLE;
					 end
            endcase
        end
    end
endmodule