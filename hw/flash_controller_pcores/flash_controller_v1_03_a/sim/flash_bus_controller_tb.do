if {[file exists "work"] == 0} {
	vlib work
}

vlog -novopt +define+V33 +define+x8 +define+CLASSB nand_model/src/nand_model.v +incdir+nand_model/src
vlog -novopt +define+V33 +define+x8 +define+CLASSB nand_model/src/nand_die_model.v +incdir+nand_model/src
vlog -novopt ../hdl/verilog/flash_bus_controller.v +incdir+../hdl/verilog/
vlog -novopt flash_bus_controller_tb.v +incdir+../hdl/verilog

vsim -novopt flash_bus_controller_tb -L unisims_ver

#do flash_bus_controller_tb_wave.do
log -r *

run -all
