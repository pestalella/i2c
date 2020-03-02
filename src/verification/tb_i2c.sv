`include "i2c.sv"

module tb_i2c;

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
    #100 ck_sda = 0;
    #100 ck_scl = 0;
    #500;
endtask

task drive_stop_condition;
    #100 ck_scl = 'bz;
    #100 ck_sda = 'bz;
    #500;
endtask

task drive_address(bit [6:0] addr);
    for (int i = 0; i < 7; i++) begin
        ck_sda = addr[6-i] ? 'bz : 0;
        #100 ck_scl = 'bz;   // clock high
        #300 ck_scl = 0;   // clock low
        #100;
    end
endtask

task drive_read_bit;
    ck_sda = 0;
    #100 ck_scl = 'bz;   // clock high
    #300 ck_scl = 0;   // clock low
    #100;    
endtask

initial begin
    // Leave the lines disconnected to get them pulled high
    ck_scl = 'bz;
    ck_sda = 'bz;

    // Reset the DUT
    reset = 1;
    #10 reset = 0;

    drive_start_condition();
    drive_address(7'h42);
    drive_read_bit();

    ck_sda = 'bz;
    #100 ck_scl = 'bz;   // clock high
    #300 ck_scl = 0;   // clock low
    #100;    

    drive_stop_condition();
end

endmodule