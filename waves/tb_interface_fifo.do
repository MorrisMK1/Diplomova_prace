onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_interface_fifo/i_clk
add wave -noupdate /tb_interface_fifo/i_rst_n
add wave -noupdate /tb_interface_fifo/i_sl_data_data
add wave -noupdate /tb_interface_fifo/i_sl_info_data
add wave -noupdate /tb_interface_fifo/o_sl_data_data
add wave -noupdate /tb_interface_fifo/o_sl_info_data
add wave -noupdate /tb_interface_fifo/i_ms_data_data
add wave -noupdate /tb_interface_fifo/i_ms_info_data
add wave -noupdate /tb_interface_fifo/o_ms_data_data
add wave -noupdate /tb_interface_fifo/o_ms_info_data
add wave -noupdate /tb_interface_fifo/sl_push_info
add wave -noupdate /tb_interface_fifo/sl_push_data
add wave -noupdate -color Yellow /tb_interface_fifo/sl_next_info
add wave -noupdate /tb_interface_fifo/sl_next_data
add wave -noupdate /tb_interface_fifo/sl_emty_info
add wave -noupdate /tb_interface_fifo/sl_emty_data
add wave -noupdate /tb_interface_fifo/sl_full_info
add wave -noupdate /tb_interface_fifo/sl_full_data
add wave -noupdate -color Blue /tb_interface_fifo/ms_push_info
add wave -noupdate /tb_interface_fifo/ms_push_data
add wave -noupdate /tb_interface_fifo/ms_next_info
add wave -noupdate /tb_interface_fifo/ms_next_data
add wave -noupdate /tb_interface_fifo/ms_emty_info
add wave -noupdate /tb_interface_fifo/ms_emty_data
add wave -noupdate /tb_interface_fifo/ms_full_info
add wave -noupdate /tb_interface_fifo/ms_full_data
add wave -noupdate /tb_interface_fifo/tx_sl
add wave -noupdate /tb_interface_fifo/rx_sl
add wave -noupdate /tb_interface_fifo/tx_ms
add wave -noupdate /tb_interface_fifo/rx_ms
add wave -noupdate /tb_interface_fifo/i_settings
add wave -noupdate /tb_interface_fifo/o_ready
add wave -noupdate /tb_interface_fifo/gen_header
add wave -noupdate /tb_interface_fifo/msg_to_ms
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/p_downstream/st_downstr
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/p_upstream/st_upstr
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/sync_up
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/sync_dw
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/r_registers
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/msg_o_dat
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/msg_o_vld
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/reg_op
add wave -noupdate /tb_interface_fifo/uart_ctrl_inst/reg_op_rdy_strb
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {265630000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 282
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
configure wave -timelineunits ps
update
WaveRestoreZoom {39538038 ps} {297013788 ps}
