module clock_div_2 (
    input  wire clk_in,   // Clock de entrada (50 MHz)
    input  wire rst_n,    // Reset assíncrono ativo baixo
    output wire clk_out   // Clock dividido por 2 (25 MHz)
);

    wire d_in;
    wire q_out;

    // D recebe o inverso de Q -> toggle
    assign d_in = ~q_out;

    // Flip-flop D
    d_flip_flop dff_inst (
        .clk(clk_in),
        .rst_n(rst_n),
        .d(d_in),
        .q(q_out)
    );

    assign clk_out = q_out;

endmodule
