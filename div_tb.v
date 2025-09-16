`timescale 1ns/1ps

module tb_division;

    reg clk;
    reg reset;

    reg input_valid;

    reg [31:0] divisor_data;
    reg [39:0] dividend_data;

    wire quo_valid;
    wire [39:0] quo_data;

    // Instantiate DUT
    division uut (
        .clk(clk),
        .reset(reset),
        .input_valid(input_valid),
        .divisor_data(divisor_data),
        .dividend_data(dividend_data),
        .quo_valid(quo_valid),
        .quo_data(quo_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("div_wave.vcd");
        $dumpvars(0, tb_division);

        // Initialize
        clk = 0;
        reset = 0;
        input_valid = 0;

        #15 reset = 1; // release reset

        dividend_data = -1072;
        divisor_data  = -2296;
        input_valid = 1;

        #10;
        dividend_data = 40'd809041920;
        divisor_data  = 32'd8060928;

        #10;
        dividend_data = -2;
        divisor_data  = -1;


        #10;
        input_valid = 0;

        wait (quo_valid);
        dividend_data = 40'd809041920;
        divisor_data  = 32'd8060928;
        input_valid = 1;

        #10;
        input_valid = 0;

        wait (quo_valid);

        // Done
        #200 $finish;
    end
endmodule