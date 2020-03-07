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

logic [6:0] address;
logic read_write;
logic [3:0] bits_read;

logic [7:0] ack_counter;
logic ack_in_progress;

logic clk_posedge_detect;
logic raw_clk_posedge_detect;

logic unused;
typedef enum bit [2:0] {IDLE, ADDRESS, RDWR_SEL, ACK} FsmState;
FsmState state;


`ifndef VIVADO_SIMULATION
ila_0 fpga_ila(
        .clk(clk100),
        .probe0(address),
        .probe1(clk_posedge_detect),
        .probe2(ck_sda_r),
        .probe3(ck_scl_r),
        .probe4(ck_scl),
        .probe5(ck_sda),
        .probe6(bits_read),
        .probe7(raw_clk_posedge_detect),
        .probe8(ack_counter),
        .probe9(ack_in_progress),
        .probe10(state),
        .probe11(read_write),
        .probe12(unused),
        .probe13(unused),
        .probe14(unused),
        .probe15(unused)
);
`endif

assign ck_sda = ack_in_progress ? 0 : 'bz;
//assign ck_sda = 'bz;

//assign ack_in_progress = ck_scl & (state == ACK);
assign ack_in_progress = (state == ACK) & (|ack_counter);
assign ack_in_progress_w = ack_in_progress;

assign start_detected_w = 'bz;

always_ff @(posedge clk100 or posedge reset) begin
    if (reset) begin
        bits_read <= '0;
        address <= '0;
        ck_sda_r <= 1;
        ck_scl_r <= 1;
        read_write <= 0;
        ack_counter <= 0;
        state = IDLE;
        clk_posedge_detect <= 0;
    end else begin
        clk_posedge_detect <= 0;
        raw_clk_posedge_detect <= (~ck_scl_r & ck_scl);
        if (|ack_counter) begin
            ack_counter <= ack_counter + 1;
        end else begin
            case (state)
                IDLE: begin
                    if (ck_sda_r & ~ck_sda & ck_scl) begin  // negedge ck_sda
                        clk_posedge_detect <= 1;
                        address <= 0;
                        bits_read <= 0;
                        state <= ADDRESS;
                    end
                end
                ADDRESS: begin
                    if (~ck_scl_r & ck_scl) begin  // posedge ck_scl
                        clk_posedge_detect <= 1;
                        if (bits_read < 4'd7) begin
                            address <= {address[5:0], ck_sda};
                            state <= ADDRESS;  // keep the same state
                            bits_read <= bits_read + 1;
                        end else if (bits_read == 4'd7) begin
                            bits_read <= 0;
                            read_write <= ck_sda;
                            state <= RDWR_SEL;
                        end
                    end
                end
                RDWR_SEL: begin
                    if (~ck_scl_r & ck_scl) begin  // posedge ck_scl
                        clk_posedge_detect <= 1;

                        // ACK if address is 0x42
                        ack_counter <= (address==7'h42)?   1 : 0;
                        state       <= (address==7'h42)? ACK : IDLE;
                    end
                end
                ACK: begin
                    if (~ck_scl_r & ck_scl) begin  // posedge ck_scl
                        clk_posedge_detect <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
        ck_scl_r <= ck_scl;
        ck_sda_r <= ck_sda;
    end
end

endmodule

`endif