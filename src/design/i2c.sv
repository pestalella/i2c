`ifndef I2C_SV
`define I2C_SV

// I2C module. It will

module i2c (
    input wire clk100,
    input wire reset,

    input wire ck_scl,
    inout wire ck_sda,
    output wire start_detected_w,
    output wire ack_in_progress_w
);

logic ck_sda_r;
logic ck_scl_r;
logic [8:0] start_counter;
logic [8:0] stop_counter;

logic [6:0] address;
logic read_write;
logic [3:0] bits_read_prev;
logic [3:0] bits_read;
logic read_start;
logic reading_address;

logic start_detected;
logic stop_detected;

logic read_address_end;
logic [7:0] ack_in_progress_counter;
logic ack_counting;
logic ack_in_progress;

logic read_write_selected;

logic unused;

`ifndef VIVADO_SIMULATION
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
        .probe8(ack_in_progress_counter),
        .probe9(ack_in_progress),
        .probe10(bits_read_prev),
        .probe11(read_write),
        .probe12(read_write_selected),
        .probe13(read_address_end),
        .probe14(unused),
        .probe15(unused)
);
`endif

assign start_detected = |start_counter;
assign stop_detected = |stop_counter;
//assign ack_in_progress = |ack_in_progress_counter & ~(&ack_in_progress_counter);

assign ck_sda = ack_in_progress ? 0 : 'bz;
//assign ck_sda = 'bz;
assign ack_counting = |ack_in_progress_counter & ~(&ack_in_progress_counter);
assign ack_in_progress = read_write_selected & ck_scl & (bits_read_prev == 4'd8) & (address == 7'h42);
assign ack_in_progress_w = ack_in_progress;
assign start_detected_w = start_detected;

always_ff @(posedge clk100 or posedge reset) begin
    if (reset) begin
        read_write_selected <= 0;
        bits_read_prev <= '0;
        address <= '0;
        ck_sda_r <= 0;
        ck_scl_r <= 0;
        start_counter <= 0;
        stop_counter <= 0;
        reading_address <= 0;
        read_write <= 0;
    end else begin
        if (~ck_scl_r & ck_scl & ~ack_in_progress) begin  // posedge ck_scl
            read_start <= (bits_read_prev == 8) && ~(|bits_read);

            bits_read_prev <= bits_read;
            if (reading_address) begin
                if (read_start) begin
                    read_address_end <= 0;
                    address <= {6'b0, ck_sda};
                    bits_read <= 1;
                    read_write_selected <= 0;
                end else begin
                    if (bits_read <= 4'd6) begin
                        address <= {address[5:0], ck_sda};
                        bits_read <= bits_read + 1;
                    end else if (bits_read == 4'd7) begin
                        read_write <= ck_sda;
                        bits_read <= bits_read + 1;
                    end else begin
                        read_address_end <= 1;
                        read_write_selected <= 1;
                        bits_read <= 0;
                    end
                end
            end else begin
                bits_read <= 0;
            end
        end
        ck_scl_r <= ck_scl;

        if (|start_counter) begin
            start_counter <= start_counter + 1;
        end

        if (|stop_counter) begin
            stop_counter <= stop_counter + 1;
        end

        if (~read_address_end) begin
            ack_in_progress_counter <= 0;
        end else if (read_address_end && ~(|ack_in_progress_counter)) begin
            ack_in_progress_counter <= 50;
            reading_address <= 0;
        end else if (ack_in_progress) begin
            ack_in_progress_counter <= ack_in_progress_counter + 1;
        end

        if (~ack_in_progress) begin
            if (ck_sda_r & ~ck_sda) begin  // negedge ck_sda
                if (ck_scl) begin
                    start_counter <= 1;
                    reading_address <= 1;
                end
                ck_sda_r <= ck_sda;
            end else if (~ck_sda_r & ck_sda) begin  // posedge ck_sda
                if (ck_scl) begin
                    stop_counter <= 1;
                end
                ck_sda_r <= ck_sda;
            end
        end
    end
end

endmodule

`endif