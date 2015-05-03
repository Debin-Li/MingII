onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /flash_bus_dispatch_tb/clk
add wave -noupdate -format Logic /flash_bus_dispatch_tb/adc_clk
add wave -noupdate -format Logic /flash_bus_dispatch_tb/rst
add wave -noupdate -expand -group Testbench -format Literal -radix unsigned /flash_bus_dispatch_tb/cyclecount_sum
add wave -noupdate -expand -group Testbench -format Literal -radix hexadecimal /flash_bus_dispatch_tb/chip_exists
add wave -noupdate -expand -group Testbench -format Literal -radix binary /flash_bus_dispatch_tb/bus_active
add wave -noupdate -expand -group Testbench -format Literal /flash_bus_dispatch_tb/sent_requests
add wave -noupdate -expand -group Testbench -format Literal /flash_bus_dispatch_tb/received_responses
add wave -noupdate -expand -group Testbench -format Literal /flash_bus_dispatch_tb/done_sending_requests
add wave -noupdate -expand -group {ADC Master Controller} -format Logic -radix binary {/flash_bus_dispatch_tb/fpga2adc_chip_select_n[0]}
add wave -noupdate -expand -group {ADC Master Controller} -format Logic -radix binary {/flash_bus_dispatch_tb/fpga2adc_chip_select_n[1]}
add wave -noupdate -expand -group {ADC Master Controller} -format Logic /flash_bus_dispatch_tb/fpga2adc_data
add wave -noupdate -expand -group {ADC Master Controller} -format Logic {/flash_bus_dispatch_tb/adc2fpga_data[0][0]}
add wave -noupdate -expand -group {ADC Master Controller} -format Logic {/flash_bus_dispatch_tb/adc2fpga_data[0][1]}
add wave -noupdate -expand -group {ADC Master Controller} -format Logic {/flash_bus_dispatch_tb/adc2fpga_data[1][0]}
add wave -noupdate -expand -group {ADC Master Controller} -format Logic {/flash_bus_dispatch_tb/adc2fpga_data[1][1]}
add wave -noupdate -expand -group {ADC Master Controller} -format Literal {/flash_bus_dispatch_tb/adc_cmd_fifo_data_out[0]}
add wave -noupdate -expand -group {ADC Master Controller} -format Literal {/flash_bus_dispatch_tb/adc_rsp_fifo_data_in[0]}
add wave -noupdate -expand -group {ADC Master Controller} -format Literal {/flash_bus_dispatch_tb/adc_rsp_fifo_data_out[0]}
add wave -noupdate -format Literal /flash_bus_dispatch_tb/adc_sample_fifo_data_in
add wave -noupdate -format Literal /flash_bus_dispatch_tb/adc_sample_fifo_almost_full
add wave -noupdate -format Literal /flash_bus_dispatch_tb/adc_sample_fifo_full
add wave -noupdate -format Literal /flash_bus_dispatch_tb/adc_sample_fifo_we
add wave -noupdate -group {Bus 0} -format Literal -radix hexadecimal {/flash_bus_dispatch_tb/Io[0]}
add wave -noupdate -group {Bus 0} -format Literal {/flash_bus_dispatch_tb/Ce_n[0]}
add wave -noupdate -group {Bus 0} -format Logic {/flash_bus_dispatch_tb/Cle[0]}
add wave -noupdate -group {Bus 0} -format Logic {/flash_bus_dispatch_tb/Ale[0]}
add wave -noupdate -group {Bus 0} -format Logic {/flash_bus_dispatch_tb/Re_n[0]}
add wave -noupdate -group {Bus 0} -format Logic {/flash_bus_dispatch_tb/We_n[0]}
add wave -noupdate -group {Bus 0} -format Literal {/flash_bus_dispatch_tb/Rb_n[0]}
add wave -noupdate -group {Bus 1} -format Literal -radix hexadecimal {/flash_bus_dispatch_tb/Io[1]}
add wave -noupdate -group {Bus 1} -format Logic {/flash_bus_dispatch_tb/Cle[1]}
add wave -noupdate -group {Bus 1} -format Logic {/flash_bus_dispatch_tb/Ale[1]}
add wave -noupdate -group {Bus 1} -format Literal {/flash_bus_dispatch_tb/Ce_n[1]}
add wave -noupdate -group {Bus 1} -format Logic {/flash_bus_dispatch_tb/Re_n[1]}
add wave -noupdate -group {Bus 1} -format Logic {/flash_bus_dispatch_tb/We_n[1]}
add wave -noupdate -group {Bus 1} -format Literal {/flash_bus_dispatch_tb/Rb_n[1]}
add wave -noupdate -group {Bus 2} -format Literal -radix hexadecimal {/flash_bus_dispatch_tb/Io[2]}
add wave -noupdate -group {Bus 2} -format Logic {/flash_bus_dispatch_tb/Cle[2]}
add wave -noupdate -group {Bus 2} -format Logic {/flash_bus_dispatch_tb/Ale[2]}
add wave -noupdate -group {Bus 2} -format Literal {/flash_bus_dispatch_tb/Ce_n[2]}
add wave -noupdate -group {Bus 2} -format Logic {/flash_bus_dispatch_tb/Re_n[2]}
add wave -noupdate -group {Bus 2} -format Logic {/flash_bus_dispatch_tb/We_n[2]}
add wave -noupdate -group {Bus 2} -format Literal {/flash_bus_dispatch_tb/Rb_n[2]}
add wave -noupdate -group {Bus 3} -format Literal -radix hexadecimal {/flash_bus_dispatch_tb/Io[3]}
add wave -noupdate -group {Bus 3} -format Logic {/flash_bus_dispatch_tb/Cle[3]}
add wave -noupdate -group {Bus 3} -format Logic {/flash_bus_dispatch_tb/Ale[3]}
add wave -noupdate -group {Bus 3} -format Literal {/flash_bus_dispatch_tb/Ce_n[3]}
add wave -noupdate -group {Bus 3} -format Logic {/flash_bus_dispatch_tb/Re_n[3]}
add wave -noupdate -group {Bus 3} -format Logic {/flash_bus_dispatch_tb/We_n[3]}
add wave -noupdate -group {Bus 3} -format Literal {/flash_bus_dispatch_tb/Rb_n[3]}
add wave -noupdate -group {Bus Interface} -expand -group {Command FIFO} -format Literal -radix hexadecimal /flash_bus_dispatch_tb/interface/i_cmd_fifo_data
add wave -noupdate -group {Bus Interface} -expand -group {Command FIFO} -format Literal -radix hexadecimal /flash_bus_dispatch_tb/interface/o_cmd_fifo_data
add wave -noupdate -group {Bus Interface} -expand -group {Command FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_cmd_fifo_re
add wave -noupdate -group {Bus Interface} -expand -group {Command FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_cmd_fifo_we
add wave -noupdate -group {Bus Interface} -expand -group {Command FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_cmd_fifo_empty
add wave -noupdate -group {Bus Interface} -expand -group {Command FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_cmd_fifo_full
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Literal /flash_bus_dispatch_tb/interface/i_wr_fifo_data
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Literal /flash_bus_dispatch_tb/interface/o_wr_fifo_data
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_wr_fifo_re
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_wr_fifo_we
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_wr_fifo_almost_empty
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_wr_fifo_empty
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_wr_fifo_almost_full
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_wr_fifo_full
add wave -noupdate -group {Bus Interface} -group {Write FIFO} -format Literal /flash_bus_dispatch_tb/interface/o_wr_fifo_count
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Literal /flash_bus_dispatch_tb/interface/i_rd_fifo_data
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Literal /flash_bus_dispatch_tb/interface/o_rd_fifo_data
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_rd_fifo_re
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_rd_fifo_we
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_rd_fifo_almost_empty
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_rd_fifo_empty
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_rd_fifo_almost_full
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_rd_fifo_full
add wave -noupdate -group {Bus Interface} -group {Read FIFO} -format Literal /flash_bus_dispatch_tb/interface/o_rd_fifo_count
add wave -noupdate -group {Bus Interface} -group {Result FIFO} -format Literal /flash_bus_dispatch_tb/interface/i_rslt_fifo_data
add wave -noupdate -group {Bus Interface} -group {Result FIFO} -format Literal /flash_bus_dispatch_tb/interface/o_rslt_fifo_data
add wave -noupdate -group {Bus Interface} -group {Result FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_rslt_fifo_re
add wave -noupdate -group {Bus Interface} -group {Result FIFO} -format Logic /flash_bus_dispatch_tb/interface/i_rslt_fifo_we
add wave -noupdate -group {Bus Interface} -group {Result FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_rslt_fifo_empty
add wave -noupdate -group {Bus Interface} -group {Result FIFO} -format Logic /flash_bus_dispatch_tb/interface/o_rslt_fifo_full
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_cmd_fifo_data
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_cmd_fifo_re
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_cmd_fifo_empty
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_wr_fifo_data
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_wr_fifo_re
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_wr_fifo_almost_empty
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_wr_fifo_empty
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_wr_fifo_count
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_rd_fifo_data
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_rd_fifo_we
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_rd_fifo_almost_full
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_rd_fifo_full
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_rslt_fifo_data
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_rslt_fifo_we
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_rslt_fifo_full
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_bus_cmd_req
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_bus_cmd_ack
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_bus_cmd_data
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_bus_rsp_req
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_bus_rsp_ack
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_bus_rsp_data
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_bus_chip_active
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_bus_wr_buffer_rsvd
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_bus_rd_buffer_rsvd
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_bus_wr_buffer_addr
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_bus_wr_buffer_data
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_bus_wr_buffer_we
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/o_bus_rd_buffer_addr
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/i_bus_rd_buffer_data
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/cmd_fifo_re_reg
add wave -noupdate -group Dispatch -format Logic /flash_bus_dispatch_tb/flash_bus_dispatch_inst/wr_fifo_re_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/cmd_tag_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/cmd_size_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/cmd_op_reg
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/cmd_addr_reg
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/new_cmd_req_reg
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/new_cmd_data_reg
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/new_rsp_ack_reg
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/wr_buffer_addr_reg
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/rd_buffer_addr_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/wr_size_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/cmd_state_reg
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/new_cmd_bus_decode
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/new_cmd_chip_decode
add wave -noupdate -group Dispatch -format Literal -radix hexadecimal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/tag_rnw_reg
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/rslt_tag_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/rslt_size_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/rslt_error_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/rd_size_reg
add wave -noupdate -group Dispatch -format Literal -radix unsigned /flash_bus_dispatch_tb/flash_bus_dispatch_inst/rslt_state_reg
add wave -noupdate -group Dispatch -format Literal /flash_bus_dispatch_tb/flash_bus_dispatch_inst/curr_rslt_bus_reg
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_clk}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_rst}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_adc_clk}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_top_bus_active}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_recording_en}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_cmd_req}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_disp_cmd_ack}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_cmd_data}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_disp_rsp_req}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_rsp_ack}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_rsp_listening}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_disp_rsp_data}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_disp_chip_active}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_disp_wr_buffer_rsvd}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_disp_rd_buffer_rsvd}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_adc_sample_fifo_data}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_adc_sample_fifo_almost_full}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_adc_sample_fifo_full}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_adc_sample_fifo_we}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_wr_buffer_addr}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_wr_buffer_data}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_wr_buffer_we}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_disp_rd_buffer_addr}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_disp_rd_buffer_data}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_cyclecount_sum}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_cyclecount_reset}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_cyclecount_start}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_cyclecount_end}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_adc_master_record}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_bus_data}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_bus_data}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_bus_data_tri_n}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_bus_we_n}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_bus_re_n}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_bus_ces_n}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_bus_cle}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_bus_ale}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/o_chip_exists}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_write_low_count}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_write_high_count}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_read_low_count}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/i_read_high_count}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/adc_sample_fifo_data_out}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/adc_sample_fifo_almost_empty}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/adc_sample_fifo_empty}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/adc_sample_fifo_re}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_wr_buffer_addr}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_wr_buffer_data_out}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_wr_buffer_re}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_rd_buffer_addr}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_rd_buffer_data_in}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_rd_buffer_we}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/rd_buffer_data_out}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_busy}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_operation}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_chip}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_addr}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_length}
add wave -noupdate -group {Flash Bus 0} -format Logic {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_start}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/ctrl_sample_count}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/chip_ready}
add wave -noupdate -group {Flash Bus 0} -format Literal {/flash_bus_dispatch_tb/genblk4[0]/flashBus/chip_result}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4204893575 ps} 0}
configure wave -namecolwidth 586
configure wave -valuecolwidth 196
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
WaveRestoreZoom {0 ps} {28240272900 ps}
