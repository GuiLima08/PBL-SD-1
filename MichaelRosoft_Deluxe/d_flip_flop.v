module d_flip_flop (
    input  wire clk,   // clock
    input  wire rst_n, // reset assíncrono ativo baixo
    input  wire d,     // entrada
    output reg  q      // saída
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            q <= 1'b0;   // valor inicial após reset
        else
            q <= d;      // armazena a entrada na borda de subida do clock
    end

endmodule
