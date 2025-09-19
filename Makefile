NAME = test.vcd
SRCS = tb.sv cacode.v
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

