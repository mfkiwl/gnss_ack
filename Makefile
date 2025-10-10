NAME = test.vcd
SRCS = ./tb_cacode_arb.sv ./cacode_arb_phi_omega.sv ./cacode.v code_phase_to_lfsr.sv
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

