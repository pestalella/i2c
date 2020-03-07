`include "i2c.sv"

module tb_i2c;

localparam I2C_CLK_PERIOD_DIV10 = 100;
localparam I2C_CLK_PERIOD = 10*I2C_CLK_PERIOD_DIV10;

logic clk;
logic reset;
tri1 ck_scl_w;
tri1 ck_sda_w;

logic ck_sda;
logic ck_scl;

logic start_detected;
logic ack_in_progress;

i2c dut(.clk100(clk),
        .reset(reset),
        .ck_scl(ck_scl_w),
        .ck_sda(ck_sda_w),
        .start_detected_w(start_detected),
        .ack_in_progress_w(ack_in_progress));

assign ck_scl_w = ck_scl;
assign ck_sda_w = ck_sda;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

task drive_start_condition;
    #(2*I2C_CLK_PERIOD_DIV10) ck_sda = 0;
    #(2*I2C_CLK_PERIOD_DIV10) ck_scl = 0;
    #(10*I2C_CLK_PERIOD_DIV10);
endtask

task drive_stop_condition;
    #(2*I2C_CLK_PERIOD_DIV10) ck_scl = 'bz;
    #(2*I2C_CLK_PERIOD_DIV10) ck_sda = 'bz;
    #(10*I2C_CLK_PERIOD_DIV10);
endtask

task drive_address(bit [6:0] addr);
    for (int i = 0; i < 7; i++) begin
        ck_sda = addr[6-i] ? 'bz : 0;
        #(3*I2C_CLK_PERIOD_DIV10) ck_scl = 'bz;   // clock high
        #(4*I2C_CLK_PERIOD_DIV10) ck_scl = 0;   // clock low
        #(3*I2C_CLK_PERIOD_DIV10);
    end
endtask

task drive_read_bit;
    ck_sda = 0;
    #(3*I2C_CLK_PERIOD_DIV10) ck_scl = 'bz;   // clock high
    #(4*I2C_CLK_PERIOD_DIV10) ck_scl = 0;   // clock low
    #(3*I2C_CLK_PERIOD_DIV10);
endtask

initial begin
    // Leave the lines disconnected to get them pulled high
    ck_scl = 'bz;
    ck_sda = 'bz;

    // Reset the DUT
    reset = 1;
    #(I2C_CLK_PERIOD) reset = 0;

    drive_start_condition();
    drive_address(7'h42);
    drive_read_bit();

    // read acknowledgement from slave
    ck_sda = 'bz;
    #(3*I2C_CLK_PERIOD_DIV10) ck_scl = 'bz;   // clock high
    #(4*I2C_CLK_PERIOD_DIV10) ck_scl = 0;   // clock low

    // stop condition
    #(3*I2C_CLK_PERIOD_DIV10) ck_sda = 0;  // pull SDA low, to trigger the stop condition later
    #(3*I2C_CLK_PERIOD_DIV10) ck_scl = 'bz;   // clock high
    #(6*I2C_CLK_PERIOD_DIV10) ck_sda = 'bz;

    drive_stop_condition();
end

endmodule