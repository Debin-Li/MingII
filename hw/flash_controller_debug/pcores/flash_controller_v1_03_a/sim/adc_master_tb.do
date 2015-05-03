if {[file exists "work"] == 0} {
	vlib work
}

vlog -novopt ../hdl/verilog/adc_comm_fifo.v
vlog -novopt ../hdl/verilog/adc_sample_fifo.v
vlog -novopt ../hdl/verilog/adc_master.v +incdir+../hdl/verilog/
vlog -novopt adc_slave.v +incdir+../hdl/verilog
vlog -novopt adc_master_tb.v +incdir+../hdl/verilog

vsim -novopt work.adc_master_tb -L xilinxcorelib_ver

log -r *

run -all
