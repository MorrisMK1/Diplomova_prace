onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_uart/clk
add wave -noupdate /tb_uart/tx
add wave -noupdate /tb_uart/data_byte
add wave -noupdate /tb_uart/rx
add wave -noupdate /tb_uart/data_byte_received
add wave -noupdate /tb_uart/valid
add wave -noupdate /tb_uart/rst_n
add wave -noupdate /tb_uart/par_en
add wave -noupdate /tb_uart/par_type
add wave -noupdate /tb_uart/par_st
add wave -noupdate /tb_uart/clk_div
add wave -noupdate /tb_uart/flags
add wave -noupdate /tb_uart/msg_o_dat
add wave -noupdate /tb_uart/msg_i_dat
add wave -noupdate /tb_uart/msg_o_vld
add wave -noupdate /tb_uart/msg_i_rdy
add wave -noupdate /tb_uart/out_busy
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22094319235 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 197
configure wave -valuecolwidth 164
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
WaveRestoreZoom {0 ps} {23199036 ns}
