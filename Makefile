NAME = test.vcd
SRCS = ./tb_gps_ack3.sv #./tb_gps_ack2.sv ./gps_ack2.sv ./code_phase_to_lfsr.sv #./tb_ca_code_func_check.sv #./tb_corr_cacode.sv ./code_phase_to_lfsr.sv #./tb_gps_ack.sv ./gps_ack.sv ./code_phase_to_lfsr.sv
OBJS = ./obj_dir/Vtb_gps_ack3

$(OBJS): $(SRCS)
	${VERILATOR_ROOT}/bin/verilator --trace --binary $(^)

sim: $(OBJS)
	$(^)

wave: $(NAME)
	gtkwave $(^)

.PHONY: clean
clean:
	rm -rf $(OBJS) $(NAME)

