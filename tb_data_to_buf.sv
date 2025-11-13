module tb;

logic clk;
logic rst;

always #10 clk = ~clk;
always #100 adc_clk = ~adc_clk;

logic i;
logic q;

bsram_18k_36 bbi
(
    .DO(dataout_i),
    .DI(datain_i),
    .AD({address, 5'd0}),
    .WRE(write_enable_0),
    .CE(1'd0),
    .CLK(clk),
    .RESET(1'd0)
);

bsram_18k_36 bbq
(
    .DO(dataout_q),
    .DI(datain_q),
    .AD({address, 5'd0}),
    .WRE(write_enable_0),
    .CE(1'd0),
    .CLK(clk),
    .RESET(1'd0)
);


logic [1:0] adc_clk_reg;
logic [1:0] i_sreg;
logic [1:0] q_sreg;
always_ff @(posedge clk)
begin
    adc_clk_reg <= {adc_clk_reg[0], adc_clk};
    i_sreg <= {i_sreg[0], i};
    q_sreg <= {q_sreg[0], q};
end

logic adc_clk_flag;
assign adc_clk_flag = ~adc_clk_reg[1] & adc_clk_reg[0];

logic [27:0] gomi;

logic [35:0] dataout_i;
logic [35:0] datain_i;
logic [35:0] dataout_q;
logic [35:0] datain_q;
logic [8:0] address;
logic write_enable_0;

logic capture;
logic [5:0] buf_count;
logic flag_buf_count;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        datain_i <= 36'd0;
        datain_q <= 36'd0;
        address <= 9'd0;
        buf_count <= 6'd0;
    end
    else
    begin
        if (capture)
        begin
            if (adc_clk_flag)
            begin
                datain_i[buf_count] <= i;
                datain_q[buf_count] <= q;

                if (buf_count < 6'd35)
                begin
                    buf_count <= buf_count + 6'd1;
                    flag_buf_count <= 1'b0;
                end
                else
                begin
                    buf_count <= 6'd0;
                    flag_buf_count <= 1'b1;
                end
            end
        end
    end
end

logic [1:0] flag_reg;
always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        write_enable_0 <= 1'd0;
    end
    else
    begin
        flag_reg <= {flag_reg[0], flag_buf_count};
        if (flag_reg[1] == 1'd0 && flag_reg[0] == 1'd1) write_enable_0 <= 1'd1;
        else write_enable_0 <= 1'd0;
        if (flag_reg[1] == 1'd1 && flag_reg[0] == 1'd0) address <= address + 9'd1;
    end
end

integer rnum;
integer fd;
integer num;
logic [7:0] tmp1;
logic [7:0] tmp2;

logic adc_clk;

integer ii;

initial
begin
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;
rst = 1'b1;
num = 0;
clk = 1'b0;
clk = 1'b0;
adc_clk = 1'b1;
#13;
rst = 1'b0;
#13;
rst = 1'b1;

@(posedge adc_clk);
@(negedge adc_clk);
capture = 1'd1;

@(posedge (address == 9'd112));

capture = 1'd0;

for (ii = 0; ii < 112; ii++)
begin
	address = ii[8:0];
	@(posedge clk);
	@(posedge clk);
	$display("AD = %d, i = %h", address, dataout_i);
	$display("AD = %d, q = %h", address, dataout_q);
end


$finish;
end

initial
begin
    fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
    repeat (200000) @(negedge adc_clk)
    begin
        rnum = $fread(tmp1, fd);
        rnum = $fread(tmp2, fd);

        i = tmp1[2];
        q = tmp2[2];
        num = num + 1;
    end
end


endmodule

