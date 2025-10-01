module control_unit (
    input  wire        clk,  // clock 50MHz
    input  wire        rst_n, // reset em nível baixo
    input  wire        start_frame_pulse, // pulso de 1 ciclo do botão
    input  wire        alu_done,  // sinal de done da ALU
    output reg         start_alu, // sinal para iniciar a ALU
    output reg         frame_ready // sinal que indica que a imagem está pronta

);
	
    // Estados da UC
    localparam IDLE = 2'b00;  // espera o start
    localparam RUN  = 2'b01;  // executa a ALU
	 localparam PREPARE = 2'b10;  // prepara para nova execução, garante que frame_ready é 0
    localparam DONE = 2'b11;  // mantém frame_ready até o próximo start

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state       <= IDLE;
            start_alu   <= 0;
            frame_ready <= 0;
          
        end else begin
            case (state)
                // Estado inicial, espera o pulso do botão
                IDLE: begin
                    start_alu   <= 0;
                    frame_ready <= 0;
                    if (start_frame_pulse) begin
                        state      <= RUN;
                    end
                end
			
					 PREPARE: begin
					 
						  state <= RUN;
					 
					 end
					 
                // Estado de execução da ALU
                RUN: begin
                    start_alu <= 1;
                    if (alu_done) begin
                        start_alu   <= 0;
                        frame_ready <= 1;  // imagem pronta
                        state       <= DONE;
                    end
                end

                // Mantém frame_ready até o próximo start
                DONE: begin
                    frame_ready <= 1;
                    if (start_frame_pulse) begin
                        // captura novos valores e reinicia processamento
								frame_ready <= 0;
                        state      <= PREPARE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
