// TRANSMITTER

`timescale 1ns / 1ps

module uart_tx(
    input clk,
    input rst,                  
    input [31:0] clk_freq, baud_rate,
    input tx_start,
    input [7:0] data,
    input parity_en,             // Parity enable signal
    output reg tx_active,
    output reg tx_serial_data,
    output reg tx_done
);

parameter [2:0] IDLE   = 3'b000;
parameter [2:0] START  = 3'b001;
parameter [2:0] DATA   = 3'b010;
parameter [2:0] PARITY = 3'b011;
parameter [2:0] STOP   = 3'b100;

reg [7:0] data_reg;
reg [3:0] bit_count;
reg [2:0] state = IDLE;
reg [31:0] baud_count;
wire [31:0] clk_per_bit = clk_freq / baud_rate;
wire baud_tick = (baud_count == (clk_per_bit - 1));

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        tx_serial_data <= 1;  // Ensure idle is high
        tx_done <= 0;
        tx_active <= 0;
        baud_count <= 0;
    end 
    else begin
        if (baud_count < (clk_per_bit - 1))
            baud_count <= baud_count + 1;
        else 
            baud_count <= 0;
        
        if (state == IDLE && tx_start) begin
            state <= START;
            tx_active <= 1;
            tx_done <= 0;
            data_reg <= data;
            tx_serial_data <= 0; // Start bit
            baud_count <= 0;
            bit_count <= 0;
        end

        if (baud_tick) begin
            case (state)
                START: begin
                    state <= DATA;
                end

                DATA: begin
                    tx_serial_data <= data_reg[bit_count];
                    if (bit_count == 7) 
                        state <= parity_en ? PARITY : STOP;
                    else 
                        bit_count <= bit_count + 1;
                end

                PARITY: begin
                    tx_serial_data <= ~(^data_reg); // Even parity
                    state <= STOP;
                end

                STOP: begin
                    tx_serial_data <= 1; // Stop bit
                    tx_done <= 1;
                    tx_active <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
end

endmodule


// RECEIVER

`timescale 1ns / 1ps


module uart_reciever(
    input clk,
    input rst,
    input [31:0] clk_freq, baud_rate,
    input rx_serial_data,
    input parity_en,           // Parity enable signal
    output reg [7:0] rx_data,
    output reg rx_done,
    output reg parity_error
);

parameter [2:0] IDLE   = 3'b000;
parameter [2:0] START  = 3'b001;
parameter [2:0] DATA   = 3'b010;
parameter [2:0] PARITY = 3'b011;
parameter [2:0] STOP   = 3'b100;

reg [2:0] state = IDLE;
reg [3:0] bit_count;
reg [31:0] baud_count;
reg [7:0] data_reg;
wire [31:0] clk_per_bit = clk_freq / baud_rate;
wire baud_tick = (baud_count == (clk_per_bit - 1));

// Baud counter for sampling at mid-bit
always @(posedge clk or posedge rst) begin
    if (rst) 
        baud_count <= 0;
    else if (baud_count < (clk_per_bit - 1)) 
        baud_count <= baud_count + 1;
    else 
        baud_count <= 0;
end

// UART Receiver FSM
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        rx_done <= 0;
        parity_error <= 0;
        rx_data <= 8'b0;
        bit_count <= 0;
    end 
    else if (baud_tick) begin
        case (state)
            IDLE: begin
                rx_done <= 0;
                parity_error <= 0;
                if (rx_serial_data == 0) begin // Start bit detected
                    state <= START;
                    baud_count <= 0;
                end
            end

            START: begin
                state <= DATA;
                bit_count <= 0;
            end

            DATA: begin
                data_reg[bit_count] <= rx_serial_data;
                if (bit_count == 7) 
                    state <= parity_en ? PARITY : STOP;
                else 
                    bit_count <= bit_count + 1;
            end

            PARITY: begin
                if (parity_en) begin
                    if (rx_serial_data != ~(^data_reg)) 
                        parity_error <= 1; // Check even parity
                end
                state <= STOP;
            end

            STOP: begin
                if (rx_serial_data == 1) begin // Stop bit detected
                    rx_data <= data_reg;
                    rx_done <= 1;
                end
                state <= IDLE;
            end
        endcase
    end
end

endmodule

// Test bench

`timescale 1ns / 1ps

module uart_tb;
    // Testbench signals
    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;
    reg parity_en;
    reg [31:0] clk_freq = 100_000_000; // 100 MHz clock
    reg [31:0] baud_rate = 9600;
    wire tx_active;
    wire tx_serial_data;
    wire tx_done;
    wire [7:0] rx_data;
    wire rx_done;
    wire parity_error;
    
    // Instantiate UART Transmitter
    uart_tx transmitter (
        .clk(clk),
        .rst(rst),
        .clk_freq(clk_freq),
        .baud_rate(baud_rate),
        .tx_start(tx_start),
        .data(tx_data),
        .parity_en(parity_en),
        .tx_active(tx_active),
        .tx_serial_data(tx_serial_data),
        .tx_done(tx_done)
    );
    
    // Instantiate UART Receiver
    uart_reciever receiver (
        .clk(clk),
        .rst(rst),
        .clk_freq(clk_freq),
        .baud_rate(baud_rate),
        .rx_serial_data(tx_serial_data), // Connect TX to RX
        .parity_en(parity_en),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .parity_error(parity_error)
    );
    
    // Clock generation
    always #5 clk = ~clk; // 100MHz clock (10ns period)
    
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        tx_start = 0;
        tx_data = 8'b10101010;
        parity_en = 1; // Enable parity
        
        // Reset the system
        #20 rst = 0;
        #10;
        
        // Start transmission
        tx_start = 1;
        #10 tx_start = 0; // Deassert start signal
        
        // Wait for transmission to complete
        wait (tx_done);
        
        // Wait for reception
        wait (rx_done);
        
        // Display results
        if (parity_error)
            $display("Parity Error detected!");
        else
            $display("Received Data: %b", rx_data);
        
        // Finish simulation
        #1000;
        $finish;
    end
endmodule


