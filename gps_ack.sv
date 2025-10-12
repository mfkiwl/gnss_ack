module gps_ack
(
    input wire clk,
    input wire rst,
    input wire i_sample,
    input wire [5:0] satelite,
    input wire [9:0] chip_delay,
    input wire [31:0] doppler,
    output wire [15:0] integrator
);


logic [3:0] T0;
logic [3:0] T1;

always_comb
begin
    case(satelite)
        6'd1: begin T0 = 4'd2; T1 = 4'd6; end
        6'd2:  begin T0 = 4'd3;  T1 = 4'd7;  end
        6'd3:  begin T0 = 4'd4;  T1 = 4'd8;  end
        6'd4:  begin T0 = 4'd5;  T1 = 4'd9;  end
        6'd5:  begin T0 = 4'd1;  T1 = 4'd9;  end
        6'd6:  begin T0 = 4'd2;  T1 = 4'd10; end
        6'd7:  begin T0 = 4'd1;  T1 = 4'd8;  end
        6'd8:  begin T0 = 4'd2;  T1 = 4'd9;  end
        6'd9:  begin T0 = 4'd3;  T1 = 4'd10; end
        6'd10: begin T0 = 4'd2;  T1 = 4'd3;  end
        6'd11: begin T0 = 4'd3;  T1 = 4'd4;  end
        6'd12: begin T0 = 4'd5;  T1 = 4'd6;  end
        6'd13: begin T0 = 4'd6;  T1 = 4'd7;  end
        6'd14: begin T0 = 4'd7;  T1 = 4'd8;  end
        6'd15: begin T0 = 4'd8;  T1 = 4'd9;  end
        6'd16: begin T0 = 4'd9;  T1 = 4'd10; end
        6'd17: begin T0 = 4'd1;  T1 = 4'd4;  end
        6'd18: begin T0 = 4'd2;  T1 = 4'd5;  end
        6'd19: begin T0 = 4'd3;  T1 = 4'd6;  end
        6'd20: begin T0 = 4'd4;  T1 = 4'd7;  end
        6'd21: begin T0 = 4'd5;  T1 = 4'd8;  end
        6'd22: begin T0 = 4'd6;  T1 = 4'd9;  end
        6'd23: begin T0 = 4'd1;  T1 = 4'd3;  end
        6'd24: begin T0 = 4'd4;  T1 = 4'd6;  end
        6'd25: begin T0 = 4'd5;  T1 = 4'd7;  end
        6'd26: begin T0 = 4'd6;  T1 = 4'd8;  end
        6'd27: begin T0 = 4'd7;  T1 = 4'd9;  end
        6'd28: begin T0 = 4'd8;  T1 = 4'd10; end
        6'd29: begin T0 = 4'd1;  T1 = 4'd6;  end
        6'd30: begin T0 = 4'd2;  T1 = 4'd7;  end
        6'd31: begin T0 = 4'd3;  T1 = 4'd8;  end
        6'd32: begin T0 = 4'd4;  T1 = 4'd9;  end
        default: begin T0 = 4'd0; T1 = 4'd0;  end
    endcase
end










endmodule
