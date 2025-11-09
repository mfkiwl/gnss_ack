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
    .AD(address),
    .WRE(write_enable),
    .CE(1'd0),
    .CLK(1'd0),
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

logic [35:0] dataout_i;
logic [35:0] datain_i;
logic [13:0] address;
logic write_enable;

logic [7:0] buf_count;
always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        datain_i <= 36'd0;
        address <= 14'd0;
        buf_count <= 8'd0;
        write_enable <= 1'b0;
    end
    else
    begin
        if (adc_clk_flag)
        begin
            datain_i <= {i, datain_i[35:1]};

            if (buf_count < 8'd35)
            begin
                buf_count <= buf_count + 8'd1;
                write_enable <= 1'b0;
            end
            else
            begin
                buf_count <= 8'd0;
                write_enable <= 1'b1;
            end
        end
    end
end




integer rnum;
integer fd;
integer num;
logic [7:0] tmp1;
logic [7:0] tmp2;

logic adc_clk;

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
adc_clk = 1'b0;
#13;
rst = 1'b0;
#13;
rst = 1'b1;
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
repeat (1027) @(negedge adc_clk)
begin
    rnum = $fread(tmp1, fd);
    rnum = $fread(tmp2, fd);

    i = tmp1[2];
    q = tmp2[2];
    num = num + 1;
end
$finish;
end

endmodule

