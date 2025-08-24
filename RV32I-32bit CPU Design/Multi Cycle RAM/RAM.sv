`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    input  logic [ 2:0] func3,
    output logic [31:0] rData
);
    logic [31:0] mem[0:2**4-1];  // 0x00 ~ 0x0f => 0x10 * 4 => 0x40

    logic [31:0] w_Data_com;

    always_ff @(posedge clk) begin
        if (we) mem[addr[31:2]] <= w_Data_com;
    end

    assign rData = mem[addr[31:2]];

    // -----------------------
    // Store (S-type)
    // -----------------------
    always_comb begin
        case (func3)
            3'b000: begin  // SB
                case (addr[1:0])
                    2'b00: w_Data_com = {mem[addr[31:2]][31:8], wData[7:0]};
                    2'b01:
                    w_Data_com = {
                        mem[addr[31:2]][31:16], wData[7:0], mem[addr[31:2]][7:0]
                    };
                    2'b10:
                    w_Data_com = {
                        mem[addr[31:2]][31:24],
                        wData[7:0],
                        mem[addr[31:2]][15:0]
                    };
                    2'b11: w_Data_com = {wData[7:0], mem[addr[31:2]][23:0]};
                    default: w_Data_com = mem[addr[31:2]];
                endcase
            end
            3'b001: begin  // SH
                case (addr[1])
                    1'b0: w_Data_com = {mem[addr[31:2]][31:16], wData[15:0]};
                    1'b1: w_Data_com = {wData[15:0], mem[addr[31:2]][15:0]};
                    default: w_Data_com = mem[addr[31:2]];
                endcase
            end
            3'b010:  w_Data_com = wData;  // SW
            default: w_Data_com = mem[addr[31:2]];
        endcase
    end

    // -----------------------
    // Load L(-Type)
    // -----------------------
    always_comb begin
        case (func3)
            3'b000: begin  // LB
                case (addr[1:0])
                    2'b00:
                    rData = {
                        {24{mem[addr[31:2]][7]}}, mem[addr[31:2]][7:0]
                    };  // byte0
                    2'b01:
                    rData = {
                        {24{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:8]
                    };  // byte1
                    2'b10:
                    rData = {
                        {24{mem[addr[31:2]][23]}}, mem[addr[31:2]][23:16]
                    };  // byte2
                    2'b11:
                    rData = {
                        {24{mem[addr[31:2]][31]}}, mem[addr[31:2]][31:24]
                    };  // byte3
                    default: rData = 32'bx;
                endcase
            end
            3'b001: begin  // LH
                case (addr[1])
                    1'b0:
                    rData = {{16{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:0]};
                    1'b1:
                    rData = {{16{mem[addr[31:2]][31]}}, mem[addr[31:2]][31:16]};
                    default: rData = 32'bx;
                endcase
            end
            3'b010: rData = mem[addr[31:2]];  // LW
            3'b100:  // LBU
            case (addr[1:0])
                2'b00:   rData = {{24{1'b0}}, mem[addr[31:2]][7:0]};  // byte0
                2'b01:   rData = {{24{1'b0}}, mem[addr[31:2]][15:8]};  // byte1
                2'b10:   rData = {{24{1'b0}}, mem[addr[31:2]][23:16]};  // byte2
                2'b11:   rData = {{24{1'b0}}, mem[addr[31:2]][31:24]};  // byte3
                default: rData = 32'bx;
            endcase
            3'b101: begin   // LHU
                case (addr[1])
                    1'b0: rData = {{16{1'b0}}, mem[addr[31:2]][15:0]};
                    1'b1: rData = {{16{1'b0}}, mem[addr[31:2]][31:16]};
                    default: rData = 32'bx;
                endcase
            end  
            default: rData = 32'bx;
        endcase
    end


endmodule
