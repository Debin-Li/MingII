CC=microblaze-unknown-linux-gnu-gcc

OUT= \
calib_adc \
get_adc_gain readallids read_adc_samples disable_adc_recording enable_adc_recording set_adc_gain reset_cyclecount set_cyclecount_params get_cyclecount send_adc_command print_registers chip_reset read write reset readparam readid erase readidloop

COMPILE_OPTS=-static -Wall -O3

all: library $(OUT)

library: lib/libmingii.a

lib/libmingii.a: lib/obj/mingii.o
	$(AR) rcs lib/libmingii.a lib/obj/mingii.o

lib/obj/mingii.o: lib/src/mingii.c lib/inc/mingii.h lib/inc/mingii_driver.h
	$(CC) $(CC_OPTS) -c lib/src/mingii.c -Ilib/inc -o lib/obj/mingii.o

%: src/%.c
	$(CC) $(COMPILE_OPTS) src/$*.c -Iinc -Ilib/inc -Llib -lmingii -o bin/$@

.PHONY: clean
clean:
	@rm -f lib/libmingii.a lib/obj/* obj/* bin/* 
	
