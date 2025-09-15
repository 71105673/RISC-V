`timescale 1ns / 1ps

module ram (
    input  logic       clk,
    input  logic [7:0] addr,
    input  logic       we,
    input  logic [7:0] wdata,
    output logic [7:0] rdata
);
    logic [7:0] mem[0:2**8-1];

    always_ff @(posedge clk) begin
        if (we) mem[addr] <= wdata;
    end

    assign rdata = mem[addr];
endmodule
