onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -label clk /flash_bus_tb/clk
add wave -noupdate -format Logic -label rst /flash_bus_tb/rst
add wave -noupdate -format Literal -label I/O -radix hexadecimal /flash_bus_tb/Io
add wave -noupdate -format Logic -label CLE -radix binary /flash_bus_tb/Cle
add wave -noupdate -format Logic -label ALE -radix binary /flash_bus_tb/Ale
add wave -noupdate -format Literal -label CE# -radix binary /flash_bus_tb/Ce_n
add wave -noupdate -format Logic -label RE# -radix binary /flash_bus_tb/Re_n
add wave -noupdate -format Logic -label WE# -radix binary /flash_bus_tb/We_n
add wave -noupdate -format Logic -label WP# -radix binary /flash_bus_tb/Wp_n
add wave -noupdate -format Logic -label R/B# -radix binary /flash_bus_tb/Rb_n
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/i_disp_cmd_req
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_disp_cmd_ack
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_disp_cmd_data
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_disp_rsp_req
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/i_disp_rsp_ack
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/o_disp_rsp_data
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/o_disp_chip_active
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_disp_wr_buffer_rsvd
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_disp_rd_buffer_rsvd
add wave -noupdate -group {Flash Bus} -format Literal -radix unsigned /flash_bus_tb/flashBus/i_disp_wr_buffer_addr
add wave -noupdate -group {Flash Bus} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/i_disp_wr_buffer_data
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/i_disp_wr_buffer_we
add wave -noupdate -group {Flash Bus} -format Literal -radix unsigned /flash_bus_tb/flashBus/i_disp_rd_buffer_addr
add wave -noupdate -group {Flash Bus} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/o_disp_rd_buffer_data
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/o_cyclecount_sum
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/i_cyclecount_reset
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_cyclecount_start
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_cyclecount_end
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_bus_data
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/o_bus_data
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_bus_data_tri_n
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_bus_we_n
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_bus_re_n
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/o_bus_ces_n
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_bus_cle
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/o_bus_ale
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_write_low_count
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_write_high_count
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_read_low_count
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/i_read_high_count
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_wr_buffer_addr
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_wr_buffer_data_out
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/ctrl_wr_buffer_re
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_rd_buffer_addr
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_rd_buffer_data_in
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/ctrl_rd_buffer_we
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/ctrl_busy
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_operation
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_chip
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_addr
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/ctrl_length
add wave -noupdate -group {Flash Bus} -format Logic /flash_bus_tb/flashBus/ctrl_start
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/chip_ready
add wave -noupdate -group {Flash Bus} -format Literal /flash_bus_tb/flashBus/chip_result
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/i_disp_cmd_req
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/o_disp_cmd_ack
add wave -noupdate -group {Bus State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busSM/i_disp_cmd_data
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/o_disp_rsp_req
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/i_disp_rsp_ack
add wave -noupdate -group {Bus State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busSM/o_disp_rsp_data
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/o_disp_chip_active
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/o_disp_wr_buffer_rsvd
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/o_disp_rd_buffer_rsvd
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/i_ctrl_busy
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/o_ctrl_operation
add wave -noupdate -group {Bus State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busSM/o_ctrl_chip
add wave -noupdate -group {Bus State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busSM/o_ctrl_addr
add wave -noupdate -group {Bus State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busSM/o_ctrl_length
add wave -noupdate -group {Bus State Machine} -format Logic -radix unsigned /flash_bus_tb/flashBus/busSM/o_ctrl_start
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/i_ctrl_chip_ready
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/i_ctrl_chip_result
add wave -noupdate -group {Bus State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busSM/cmd_tag_reg
add wave -noupdate -group {Bus State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busSM/cmd_size_reg
add wave -noupdate -group {Bus State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busSM/cmd_op_reg
add wave -noupdate -group {Bus State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busSM/cmd_addr_reg
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/sys_cycle_count_reg
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/op_cycle_count_reg
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/new_cmd_ack_reg
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/new_rsp_req_reg
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/new_rsp_data_reg
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/chip_active_reg
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/wr_buffer_rsvd_reg
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/rd_buffer_rsvd_reg
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/curr_chip_reg
add wave -noupdate -group {Bus State Machine} -format Literal /flash_bus_tb/flashBus/busSM/state_reg
add wave -noupdate -group {Bus State Machine} -format Logic /flash_bus_tb/flashBus/busSM/o_cycle_count_sum
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal /flash_bus_tb/flashBus/busSM/sb_addr
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Logic /flash_bus_tb/flashBus/busSM/sb_fifo_we
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_tag_rd -radix unsigned /flash_bus_tb/flashBus/busSM/sb_tag_rd
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_op_rd -radix unsigned /flash_bus_tb/flashBus/busSM/sb_tag_rd
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_chip_state_rd -radix unsigned /flash_bus_tb/flashBus/busSM/sb_chip_state_rd
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_length_rd -radix unsigned /flash_bus_tb/flashBus/busSM/sb_length_rd
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_bus_addr_rd -radix hexadecimal /flash_bus_tb/flashBus/busSM/sb_bus_addr_rd
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_cycle_count_rd -radix unsigned /flash_bus_tb/flashBus/busSM/sb_cycle_count_rd
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_tag_wr -radix decimal /flash_bus_tb/flashBus/busSM/sb_tag_wr
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_op_wr -radix decimal /flash_bus_tb/flashBus/busSM/sb_tag_wr
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_chip_state_wr -radix unsigned /flash_bus_tb/flashBus/busSM/sb_chip_state_wr
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_length_wr -radix unsigned /flash_bus_tb/flashBus/busSM/sb_length_wr
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_bus_addr_wr -radix hexadecimal /flash_bus_tb/flashBus/busSM/sb_bus_addr_wr
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Literal -label sb_cycle_count_wr -radix unsigned /flash_bus_tb/flashBus/busSM/sb_cycle_count_wr
add wave -noupdate -group {Bus State Machine} -expand -group Scoreboard -format Logic -label sb_fifo_we -radix binary /flash_bus_tb/flashBus/busSM/sb_fifo_we
add wave -noupdate -group {Bus State Machine} -format Literal -label state_reg -radix unsigned /flash_bus_tb/flashBus/busSM/state_reg
add wave -noupdate -group {Bus State Machine} -format Literal -label cmd_op_reg -radix unsigned /flash_bus_tb/flashBus/busSM/cmd_op_reg
add wave -noupdate -group {Bus State Machine} -format Literal -label i_ctrl_chip_ready -radix binary /flash_bus_tb/flashBus/busSM/i_ctrl_chip_ready
add wave -noupdate -group {Bus State Machine} -format Logic -label i_ctrl_busy -radix binary /flash_bus_tb/flashBus/busSM/i_ctrl_busy
add wave -noupdate -group {Bus State Machine} -format Logic -label o_ctrl_start /flash_bus_tb/flashBus/busSM/o_ctrl_start
add wave -noupdate -group {Bus State Machine} -format Literal -label o_ctrl_operation -radix unsigned /flash_bus_tb/flashBus/busSM/o_ctrl_operation
add wave -noupdate -group {Bus State Machine} -format Literal -label o_ctrl_chip -radix unsigned /flash_bus_tb/flashBus/busSM/o_ctrl_chip
add wave -noupdate -group {Bus State Machine} -format Literal -label o_ctrl_addr -radix hexadecimal /flash_bus_tb/flashBus/busSM/o_ctrl_addr
add wave -noupdate -group {Bus State Machine} -format Literal -label o_ctrl_length -radix unsigned /flash_bus_tb/flashBus/busSM/o_ctrl_length
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/o_busy
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/i_operation
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/i_chip
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busController/i_addr
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/i_length
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/i_start
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/o_chip_ready
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/o_chip_result
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/o_wr_buffer_addr
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busController/i_wr_buffer_data
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/o_rd_buffer_addr
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busController/o_rd_buffer_data
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/o_rd_buffer_we
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/i_bus_data
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/o_bus_data
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/o_bus_data_tri_n
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/o_bus_we_n
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/o_bus_re_n
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/o_bus_ces_n
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/o_bus_cle
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/o_bus_ale
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/i_write_low_count
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/i_write_high_count
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/i_read_low_count
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/i_read_high_count
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/i
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/chip_ready_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/chip_result_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/op_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/length_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/chip_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/addr_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/bus_data_in_reg
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/bus_dir_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/bus_data_out_reg
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/bus_we_n_reg
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/bus_re_n_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/bus_ces_n_reg
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/bus_cle_reg
add wave -noupdate -expand -group {Controller State Machine} -format Logic /flash_bus_tb/flashBus/busController/bus_ale_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/wr_buffer_addr_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/rd_buffer_addr_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/state_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/state_delay_count_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/byte_count_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix hexadecimal /flash_bus_tb/flashBus/busController/addr_out_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal -radix unsigned /flash_bus_tb/flashBus/busController/addr_bytes_reg
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/chip_decode
add wave -noupdate -expand -group {Controller State Machine} -format Literal /flash_bus_tb/flashBus/busController/chip_decode_n
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {690018219 ps} 0}
configure wave -namecolwidth 467
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
WaveRestoreZoom {0 ps} {8099943600 ps}
