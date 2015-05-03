onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -label clk /flash_bus_controller_tb/clk
add wave -noupdate -format Literal -label IO -radix hexadecimal /flash_bus_controller_tb/Io
add wave -noupdate -format Logic -label Cle /flash_bus_controller_tb/Cle
add wave -noupdate -format Logic -label Ale /flash_bus_controller_tb/Ale
add wave -noupdate -format Literal -label Ce_n /flash_bus_controller_tb/Ce_n
add wave -noupdate -format Logic -label Re_n /flash_bus_controller_tb/Re_n
add wave -noupdate -format Logic -label We_n /flash_bus_controller_tb/We_n
add wave -noupdate -format Logic -label Wp_n /flash_bus_controller_tb/Wp_n
add wave -noupdate -format Literal -label Rb_n /flash_bus_controller_tb/Rb_n
add wave -noupdate -format Literal -radix hexadecimal /flash_bus_controller_tb/bus_i_data
add wave -noupdate -format Literal -radix hexadecimal /flash_bus_controller_tb/bus_o_data
add wave -noupdate -format Logic -radix hexadecimal /flash_bus_controller_tb/bus_data_tri
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/i_clk
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/o_busy
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/i_operation
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/i_chip
add wave -noupdate -expand -group Controller -format Literal -radix hexadecimal /flash_bus_controller_tb/controller/i_addr
add wave -noupdate -expand -group Controller -format Literal -radix unsigned /flash_bus_controller_tb/controller/i_length
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/i_start
add wave -noupdate -expand -group Controller -format Literal -radix unsigned /flash_bus_controller_tb/controller/o_sample_count
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/o_chip_ready
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/o_chip_result
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/o_chip_exists
add wave -noupdate -expand -group Controller -format Literal -radix hexadecimal /flash_bus_controller_tb/controller/i_adc_sample_fifo_data
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/i_adc_sample_fifo_almost_empty
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/i_adc_sample_fifo_empty
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/o_adc_sample_fifo_re
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/i_adc_sample_fifo_valid
add wave -noupdate -expand -group Controller -format Literal -radix hexadecimal /flash_bus_controller_tb/controller/o_wr_buffer_addr
add wave -noupdate -expand -group Controller -format Literal -radix hexadecimal /flash_bus_controller_tb/controller/i_wr_buffer_data
add wave -noupdate -expand -group Controller -format Literal -radix hexadecimal /flash_bus_controller_tb/controller/o_rd_buffer_addr
add wave -noupdate -expand -group Controller -format Literal -radix hexadecimal /flash_bus_controller_tb/controller/o_rd_buffer_data
add wave -noupdate -expand -group Controller -format Logic /flash_bus_controller_tb/controller/o_rd_buffer_we
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/chip_ready_reg
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/chip_result_reg
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/op_reg
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/length_reg
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/chip_reg
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/addr_reg
add wave -noupdate -expand -group Controller -format Literal -radix unsigned /flash_bus_controller_tb/controller/state_reg
add wave -noupdate -expand -group Controller -format Literal /flash_bus_controller_tb/controller/byte_count_reg
add wave -noupdate -expand -group Controller -format Literal -radix hexadecimal /flash_bus_controller_tb/controller/addr_out_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2234713810 ps} 0}
configure wave -namecolwidth 517
configure wave -valuecolwidth 138
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
WaveRestoreZoom {0 ps} {4372266150 ps}
