module coprocessor (
    input  wire        		clk,
    input  wire        		rst_n,
    input  wire        		start_frame_btn,  // botão debounced
    input  wire [2:0]  		algo_sel,         // chaves externas
    input  wire [1:0]  		factor_reg,       // chaves externas
    input  wire [7:0]  		color_in,         // pixel lido da RAM
	output wire [9:0]  		CURRENT_HEIGHT,   // altura atual da imagem
	output wire [9:0]  		CURRENT_WIDTH,		// largura atual da imagem
    output wire [18:0] 	    addr_in_ram,      // endereco para leitura da RAM
    output wire [7:0] 		color_out,        // pixel para escrita na RAM
    output wire [18:0] 	    addr_out_ram,     // endereco para escrita na RAM
    output wire        		frame_ready,      // indica imagem pronta
    output wire        		wren             // ativa escrita na RAM
);

    //
    localparam ORIGINAL_WIDTH  = 10'd160;  // Largura da imagem padrao 
    localparam ORIGINAL_HEIGHT = 10'd120;  // Altura da imagem padrao

    // ======================================
    // Pulso de start de 1 ciclo a partir do botão
    // ======================================
    reg btn_sync0, btn_sync1;
    reg btn_prev;
    wire start_frame_pulse;

    // Sincronizador duplo para metastabilidade
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            btn_sync0 <= 1'b0;
            btn_sync1 <= 1'b0;
        end else begin
            btn_sync0 <= start_frame_btn;
            btn_sync1 <= btn_sync0;
        end
    end

    // Registrador para detecção de borda
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            btn_prev <= 1'b0;
        else
            btn_prev <= btn_sync1;
    end

    // Pulso de 1 ciclo quando ocorre borda de subida
    assign start_frame_pulse = btn_sync1 & ~btn_prev;

    // ======================================
    // Registradores internos para ALU
    // ======================================
    reg [2:0] algo_reg;
    reg [3:0] factor_out;
	reg [3:0] factor_in;
    //reg [7:0] color_in_reg;
	 
    // Captura valores das chaves e pixel de entrada no início do frame
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            algo_reg   <= 3'b000;
            factor_out <= 2'b00;
            factor_in  <= 2'b00;
        end else if (start_frame_pulse) begin
            algo_reg <= algo_sel;       // captura chaves
            case(factor_reg)
                2'b00, 2'b11: begin 
						factor_out <= 4'd2;
						factor_in <= 4'd2;
						
					end
                2'b01: begin 
						factor_out <= 4'd4;
						factor_in <= 4'd4;
					end
                2'b10: begin
						factor_out <= 4'd8;
						factor_in <= 4'd4;
					end
            endcase
        end
    end

    // ======================================
    // Sinais de controle para UC e ALU
    // ======================================
    wire start_alu; // da UC para ALU
    wire alu_done;  // da ALU para UC

    // Instancia UC 
    control_unit uc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_frame_pulse(start_frame_pulse),
        .alu_done(alu_done),
        .start_alu(start_alu),
        .frame_ready(frame_ready)
    );

    // Instancia ALU 
    alu alu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_alu),
        .algo_sel(algo_reg),
        .FACTOR_IN(factor_in),
        .FACTOR_OUT(factor_out),
        .ORIGINAL_WIDTH(ORIGINAL_WIDTH),
        .ORIGINAL_HEIGHT(ORIGINAL_HEIGHT),
        .CURRENT_WIDTH(CURRENT_WIDTH),
        .CURRENT_HEIGHT(CURRENT_HEIGHT),
        .color_in(color_in),
        .addr_in(addr_in_ram),
        .addr_out(addr_out_ram),
        .data_out(color_out),
        .wren(wren),
        .alu_process_done(alu_done)
    );

endmodule
