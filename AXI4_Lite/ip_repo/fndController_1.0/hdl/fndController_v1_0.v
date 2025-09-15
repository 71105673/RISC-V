
`timescale 1 ns / 1 ps

	module fndController_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		output [ 3:0] fndCom,
    	output [ 7:0] fndFont,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

		wire fnd_en;
		wire [13:0] fnd_data;

// Instantiation of Axi Bus Interface S00_AXI
	fndController_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) fndController_v1_0_S00_AXI_inst (
		.fnd_en(fnd_en),
		.fnd_data(fnd_data),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here
	fndController U_FndController(
		.clk(s00_axi_aclk),
		.reset(~s00_axi_aresetn),
		.en(fnd_en),
		.number(fnd_data),
		.fndCom(fndCom),
		.fndFont(fndFont)
	);
	// User logic ends

	endmodule


module fndController (
    input         clk,
    input         reset,
    input         en,
    input  [13:0] number,
    output [ 3:0] fndCom,
    output [ 7:0] fndFont
);
    wire tick_1khz;
    wire [1:0] count;
    wire [3:0] digit_1, digit_10, digit_100, digit_1000, digit;

    clk_div_1khz U_Clk_Div_1khz (
        .clk      (clk),
        .reset    (reset),
        .en       (en),
        .tick_1khz(tick_1khz)
    );

    counter_2bit U_Counter_2bit (
        .clk  (clk),
        .reset(reset),
        .tick (tick_1khz),
        .count(count)
    );

    decoder_2x4 U_Decoder_2x4 (
        .en(en),
        .x (count),
        .y (fndCom)
    );

    digitSplitter U_DigitSplitter (
        .number    (number),
        .digit_1   (digit_1),
        .digit_10  (digit_10),
        .digit_100 (digit_100),
        .digit_1000(digit_1000)
    );

    mux_4x1 U_Mux_4x1 (
        .sel(count),
        .x0 (digit_1),
        .x1 (digit_10),
        .x2 (digit_100),
        .x3 (digit_1000),
        .y  (digit)
    );

    BCDtoFND_Decoder U_BCDtoFND (
        .bcd(digit),
        .fnd(fndFont)
    );
endmodule

module clk_div_1khz (
    input  clk,
    input  reset,
    input  en,
    output reg tick_1khz
);
    reg [$clog2(100_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick_1khz   <= 1'b0;
        end else begin
            if (en) begin
                if (div_counter == 100_000 - 1) begin
                    div_counter <= 0;
                    tick_1khz   <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick_1khz   <= 1'b0;
                end
            end
        end
    end
endmodule

module counter_2bit (
    input        clk,
    input        reset,
    input        tick,
    output reg [1:0] count
);
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if (tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module decoder_2x4 (
    input        en,
    input  [1:0] x,
    output reg [3:0] y
);
    always @(*) begin
        if (en) begin
            y = 4'b1111;
            case (x)
                2'b00: y = 4'b1110;
                2'b01: y = 4'b1101;
                2'b10: y = 4'b1011;
                2'b11: y = 4'b0111;
            endcase
        end else begin
            y = 4'b1111;
        end
    end
endmodule

module digitSplitter (
    input  [13:0] number,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);
    assign digit_1    = number % 10;
    assign digit_10   = number / 10 % 10;
    assign digit_100  = number / 100 % 10;
    assign digit_1000 = number / 1000 % 10;
endmodule

module mux_4x1 (
    input  [1:0] sel,
    input  [3:0] x0,
    input  [3:0] x1,
    input  [3:0] x2,
    input  [3:0] x3,
    output reg [3:0] y
);
    always @(*) begin
        y = 4'b0000;
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end
endmodule

module BCDtoFND_Decoder (
    input  [3:0] bcd,
    output reg [7:0] fnd
);
    always @(*) begin
        case (bcd)
            4'h0: fnd = 8'hc0;
            4'h1: fnd = 8'hf9;
            4'h2: fnd = 8'ha4;
            4'h3: fnd = 8'hb0;
            4'h4: fnd = 8'h99;
            4'h5: fnd = 8'h92;
            4'h6: fnd = 8'h82;
            4'h7: fnd = 8'hf8;
            4'h8: fnd = 8'h80;
            4'h9: fnd = 8'h90;
            4'ha: fnd = 8'h88;
            4'hb: fnd = 8'h83;
            4'hc: fnd = 8'hc6;
            4'hd: fnd = 8'ha1;
            4'he: fnd = 8'h86;
            4'hf: fnd = 8'h8e;
            default: fnd = 8'hff;
        endcase
    end
endmodule
