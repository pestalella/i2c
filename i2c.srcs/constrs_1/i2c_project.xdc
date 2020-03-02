set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk100]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk100]

## ChipKit I2C
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports ck_scl]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports ck_sda]

set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { ack_in_progress_w }]; #IO_L9N_T1_DQS_D13_14 		Sch=ck_io[40]
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L6N_T0_VREF_16 Sch=btn[0]
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { start_detected_w }]; #IO_L9P_T1_DQS_14 			Sch=ck_io[41]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ck_scl_IBUF]
