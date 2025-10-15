NAME = test.vcd
SRCS = ./gps_ack.sv
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

