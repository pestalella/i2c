`ifndef I2C_SV
`define I2C_SV

// I2C module. It will

module i2c (
    input wire clk100,
    input wire reset,

    input wire ck_scl,
    inout wire ck_sda,
    output wire ack_in_progress_w
);

logic ck_sda_r;
logic [8:0] start_counter;
logic [8:0] stop_counter;

logic [7:0] address;
logic read_write;
logic [3:0] bits_read_prev;
logic [3:0] bits_read;
logic read_start;
logic reading_address;

logic start_detected;
logic stop_detected;

logic [7:0] ack_counter;
logic ack_in_progress;

logic unused;

ila_0 fpga_ila(
        .clk(clk100),
        .probe0(address),
        .probe1(reading_address),
        .probe2(start_detected),
        .probe3(stop_detected),
        .probe4(ck_scl),
        .probe5(ck_sda),
        .probe6(bits_read),
        .probe7(read_start),
        .probe8(ack_counter),
        .probe9(ack_in_progress),
        .probe10(bits_read_prev),
        .probe11(read_write),
        .probe12(unused),
        .probe13(unused),
        .probe14(unused),
        .probe15(unused)
);

initial begin
    ck_sda_r <= 0;
    start_counter <= 0;
    stop_counter <= 0;
    reading_address <= 0;
    address <= '0;
    read_write <= 0;
    read_start <= 0;
    bits_read <= '0;
    bits_read_prev <= '0;
    ack_in_progress <= 0;
    ack_counter <= '0;
end

assign start_detected = |start_counter;
assign stop_detected = |stop_counter;

//assign ck_sda = ack_in_progress ? 1 : 'bz;
assign ck_sda = 'bz;
assign ack_in_progress_w = ack_in_progress;

always_ff @(posedge clk100 or posedge reset) begin
    if (reset) begin
        ck_sda_r <= 0;
        start_counter <= 0;
        stop_counter <= 0;
        reading_address <= 0;
        address <= '0;
        read_write <= 0;
        read_start <= 0;
        bits_read <= '0;
        bits_read_prev <= '0;
        ack_in_progress <= 0;
        ack_counter <= '0;
    end else begin
        if (|start_counter) begin
            start_counter <= start_counter + 1;
        end

        if (|stop_counter) begin
            stop_counter <= stop_counter + 1;
        end

        if (bits_read_prev == 8 && bits_read == 0) begin
            if (reading_address) begin
                if (ack_in_progress) begin
                    if (ack_counter < 8'd200)
                        ack_counter <= ack_counter + 1;
                    else begin
                        ack_in_progress <= 0;
                        reading_address <= 0;
                    end
                end else begin
                    ack_counter <= 0;
                    ack_in_progress <= 1;
                end
            end
        end

        if (ck_sda_r & ~ck_sda) begin  // negedge ck_sda
            if (ck_scl) begin
                start_counter <= 1;
                reading_address <= 1;
                address <= '0;
            end
            ck_sda_r <= ck_sda;
        end else if (~ck_sda_r & ck_sda) begin  // posedge ck_sda
            if (ck_scl) begin
                stop_counter <= 1;
                reading_address <= 0;
            end
            ck_sda_r <= ck_sda;
        end
    end
end

always_ff @(posedge ck_scl) begin
    read_start <= ~(|bits_read);

    bits_read_prev <= bits_read;
    if (reading_address) begin
        if (read_start) begin
            address <= {6'b0, ck_sda};
            bits_read <= 1;
            read_start <= 0;
        end else begin
            if (bits_read <= 4'd6) begin
                address <= {address[5:0], ck_sda};
                bits_read <= bits_read + 1;
            end else if (bits_read == 4'd7) begin
                read_write <= ck_sda;
                bits_read <= bits_read + 1;
            end else begin
                bits_read <= 0;
            end
        end
    end else begin
        bits_read <= 0;
    end
end

endmodule

`endif