`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    input  logic [ 1:0] size,   // 00:byte, 01:half, 10:word
    output logic [31:0] rData
);
    logic [31:0] mem[0:2**4-1];
    initial begin
        for (int i = 0; i < 16; i++) begin
            mem[i] = 32'bx;  // 명시적으로 unknown 상태로 설정
        end
    end
    always_ff @(posedge clk) begin
        if (we) begin
            case (size)
                2'b00: begin  // byte write
                    case (addr[1:0])
                        2'b00: mem[addr[31:2]][7:0] <= wData[7:0];
                        2'b01: mem[addr[31:2]][15:8] <= wData[7:0];
                        2'b10: mem[addr[31:2]][23:16] <= wData[7:0];
                        2'b11: mem[addr[31:2]][31:24] <= wData[7:0];
                    endcase
                end
                2'b01: begin  // halfword write
                    case (addr[1])
                        1'b0: mem[addr[31:2]][15:0] <= wData[15:0];
                        1'b1: mem[addr[31:2]][31:16] <= wData[15:0];
                    endcase
                end
                2'b10: mem[addr[31:2]] <= wData;  // word write (기존 동작)
                default: mem[addr[31:2]] <= wData;  // 안전장치
            endcase
        end
    end

    assign rData = mem[addr[31:2]];  // 항상 전체 word 반환
endmodule
