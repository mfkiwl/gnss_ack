NAME = test.vcd
SRCS = ./tb_gps_ack2.sv ./gps_ack2.sv ./code_phase_to_lfsr.sv #./tb_data_read_check.sv #./tb_ca_code_func_check.sv #./tb_corr_cacode.sv ./code_phase_to_lfsr.sv #./tb_gps_ack.sv ./gps_ack.sv ./code_phase_to_lfsr.sv
OBJS = a.out

$(OBJS): $(SRCS)
	iverilog $(^) -g2012 -W all

$(NAME): $(OBJS)
	vvp $(^)

sim: $(NAME)
	gtkwave $(^)

.PHONY: clean
clean:
	rm -rf $(OBJS) $(NAME)

