module clock_divider(
    input clk,               // Clock de 50 MHz
    input reset,             // Sinal de reset
    output reg clk_25        // Clock de 10 Hz
);

    reg [22:0] counter;      // Contador de 23 bits (2^23 = 8.388.608 ciclos)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_25 <= 0;
        end
        else begin
            if (counter == 4999999) begin // 5.000.000 ciclos de 50 MHz
                clk_25 <= ~clk_25;      // Alterna o sinal de clk_25
                counter <= 0;           // Reinicia o contador
            end
            else begin
                counter <= counter + 1; // Incrementa o contador
            end
        end
    end
endmodule
