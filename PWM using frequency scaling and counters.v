`timescale 1ns / 1ps

module pwm_generator(
    input clk_1MHz,
    input [3:0] pulse_width,
    output reg clk_500Hz, pwm_signal
);

reg [9:0] count_scale = 0;
reg [4:0] pwm_counter = 0;
reg pwm_clk = 1;
reg [5:0] count=0;

initial begin
    clk_500Hz = 1;
    pwm_signal = 1;
end

always @ (posedge clk_1MHz) begin
    count_scale <= count_scale + 1;
    if (count_scale == 1000) begin
        clk_500Hz <= ~clk_500Hz;
        count_scale <= 1;
    end

    count <= count+1;
   if (count == 50) begin
     pwm_clk<= ~pwm_clk;
     count <= 1;
     end 
end 

always @(posedge pwm_clk ) begin
        pwm_counter <= pwm_counter + 1;
        if (pwm_counter<pulse_width) 
            pwm_signal <= 1;  
        else if (pwm_counter==pulse_width)
		  pwm_signal<=0;
        else
            pwm_signal <= 0;           

        if (pwm_counter == 19)         
            pwm_counter <= 0;
    end


endmodule

//test bench code

`timescale 1ns / 1ps

module pwm_generator_tb;

    // Inputs
    reg clk_1MHz;
    reg [3:0] pulse_width;

    // Outputs
    wire clk_500Hz;
    wire pwm_signal;

    // Instantiate the Device Under Test (DUT)
    pwm_generator dut (
        .clk_1MHz(clk_1MHz),
        .pulse_width(pulse_width),
        .clk_500Hz(clk_500Hz),
        .pwm_signal(pwm_signal)
    );

    // Clock generation (1 MHz clock, period = 1 µs)
    initial begin
        clk_1MHz = 0;
        forever #0.5 clk_1MHz = ~clk_1MHz; // Toggle every 500 ns
    end

    // Test scenarios
    initial begin
        
        // Test Case 1: 25% Duty Cycle
        pulse_width = 4;  // 4/20 = 20% duty cycle
        #20_000;          // Wait for a few PWM cycles

        // Test Case 2: 50% Duty Cycle
        pulse_width = 10; // 10/20 = 50% duty cycle
        #20_000;          
        
        // Test Case 3: 75% Duty Cycle
        pulse_width = 15; // 15/20 = 75% duty cycle
        #20_000;          

        // Test Case 4: 0% Duty Cycle
        pulse_width = 0;  // 0/20 = 0% duty cycle
        #20_000;          

        // Test Case 5: 100% Duty Cycle (Exceeding limit)
        pulse_width = 20; // Should be capped to 19/20 = 95%
        #20_000;          

        $stop; // End simulation
    end

endmodule
