if {[file exists "work"] == 0} {
	vlib work
}

vlog -novopt +define+V33 +define+x8 +define+CLASSA nand_model/src/nand_model.v +incdir+nand_model/src
vlog -novopt +define+V33 +define+x8 +define+CLASSA nand_model/src/nand_die_model.v +incdir+nand_model/src
vlog -novopt ../hdl/verilog/command_fifo.v
vlog -novopt ../hdl/verilog/write_fifo.v
vlog -novopt ../hdl/verilog/read_fifo.v
vlog -novopt ../hdl/verilog/result_fifo.v
vlog -novopt ../hdl/verilog/chip_scoreboard.v
vlog -novopt ../hdl/verilog/write_buffer.v
vlog -novopt ../hdl/verilog/read_buffer.v
vlog -novopt ../hdl/verilog/flash_bus_controller.v +incdir+../hdl/verilog
vlog -novopt ../hdl/verilog/flash_bus_sm.v +incdir+../hdl/verilog
vlog -novopt ../hdl/verilog/wr_fifo_interface.v +incdir+../hdl/verilog/
vlog -novopt ../hdl/verilog/rd_fifo_interface.v +incdir+../hdl/verilog
vlog -novopt ../hdl/verilog/flash_bus.v +incdir+../hdl/verilog/
vlog -novopt ../hdl/verilog/flash_bus_interface.v
vlog -novopt ../hdl/verilog/flash_bus.v +incdir+../hdl/verilog/
vlog -novopt flash_bus_tb.v +incdir+../hdl/verilog

vsim -novopt work.flash_bus_tb -L xilinxcorelib_ver

do flash_bus_tb_wave.do

run -all
