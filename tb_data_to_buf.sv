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
    .DI({gomi, datain_i}),
    .AD(address),
    .WRE(write_enable),
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
logic [7:0] datain_i;
logic [13:0] address;
logic write_enable;

logic capture;
logic [2:0] buf_count;
logic flag_buf_count;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        datain_i <= 8'd0;
        address <= 14'd0;
        buf_count <= 3'd0;
        write_enable <= 1'b0;
    end
    else
    begin
        if (capture)
        begin
            if (adc_clk_flag)
            begin
                datain_i[buf_count] <= i;

                {flag_buf_count, buf_count} <= buf_count + 4'd1;
            end
        end
    end
end

logic [1:0] flag_reg;
always_ff @(posedge clk or negedge rst)
begin
    if (!rst) write_enable <= 1'd0;
    else
    begin
        flag_reg <= {flag_reg[0], flag_buf_count};
        if (flag_reg[1] == 1'd0 && flag_reg[0] == 1'd1) write_enable <= 1'd1;
        else write_enable <= 1'd0;
        if (flag_reg[1] == 1'd1 && flag_reg[0] == 1'd0) address <= address + 13'd1;
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
adc_clk = 1'b1;
#13;
rst = 1'b0;
#13;
rst = 1'b1;

@(posedge adc_clk);
@(negedge adc_clk);
capture = 1'd1;
repeat (500) @(posedge adc_clk);
$finish;
end

initial
begin
    fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
    repeat (1027) @(negedge adc_clk)
    begin
        rnum = $fread(tmp1, fd);
        rnum = $fread(tmp2, fd);

        i = tmp1[2];
        q = tmp2[2];
        num = num + 1;
    end
end


endmodule

