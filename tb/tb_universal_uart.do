onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_universal_uart/clk
add wave -noupdate /tb_universal_uart/i_rst_n
add wave -noupdate /tb_universal_uart/i_data
add wave -noupdate /tb_universal_uart/o_data
add wave -noupdate /tb_universal_uart/i_info_bus
add wave -noupdate /tb_universal_uart/o_info_bus
add wave -noupdate /tb_universal_uart/comm_wire
add wave -noupdate /tb_universal_uart/SPI_device_sel
add wave -noupdate /tb_universal_uart/recieved_data
add wave -noupdate /tb_universal_uart/recieved_info
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/i_clk
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/i_rst_n
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/i_en
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/i_data
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/o_data
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/i_info_bus
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/o_info_bus
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/comm_wire_0
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/comm_wire_1
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/SPI_device_sel
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/r_registers
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/flags
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/msg_i_vld
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/msg_o_vld
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/msg_i_dat
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/msg_o_dat
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/msg_i_rdy
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/out_busy
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/clk_div
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/inf_rdy_strb
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/inf_reg
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/reg_op
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/reg_op_rdy_strb
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/rst_n
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/clk_en
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/en_rst
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/timeout_reg
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/timeout_s
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/timeout_rst
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/timeout_val
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/rst_r
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/parity_odd
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/timeout_en
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/parity_en
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/interrupt_en
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/allow_unexp_msg
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/auto_flag_rep
add wave -noupdate /tb_universal_uart/universal_ctrl_DUT/clk_div_sel
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {34443 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 347
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {96441 ps}
