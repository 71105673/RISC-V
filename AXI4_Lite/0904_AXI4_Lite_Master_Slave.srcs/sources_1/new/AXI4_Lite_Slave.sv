`timescale 1ns / 1ps

module AXI4_Lite_Slave (
    //Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // WRITE Transaction, AW Channel
    input  logic [ 3:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // WRITE Transaction, W Channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // WRITE Transaction, B Channel
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // READ Transaction, AR Channel
    input  logic [ 3:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // READ Transaction, R Channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    // WRITE Transaction, AW Channel transfer
    typedef enum {
        AW_IDLE,
        AW_READY
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;
    logic [3:0] temp_awaddr_reg, temp_awaddr_next;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            aw_state        <= AW_IDLE;
            temp_awaddr_reg <= 0;
        end else begin
            aw_state        <= aw_state_next;
            temp_awaddr_reg <= temp_awaddr_next;
        end
    end

    always_comb begin
        aw_state_next    = aw_state;
        AWREADY          = 1'b0;
        temp_awaddr_next = temp_awaddr_reg;
        case (aw_state)
            AW_IDLE: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next    = AW_READY;
                    temp_awaddr_next = AWADDR;
                end
            end
            AW_READY: begin
                AWREADY = 1'b1;
                temp_awaddr_next = AWADDR;
                aw_state_next = AW_IDLE;
            end
        endcase
    end

    // WRITE Transaction, W Channel transfer
    typedef enum {
        W_IDLE,
        W_READY
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            w_state <= W_IDLE;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WREADY       = 1'b0;
        case (w_state)
            W_IDLE: begin
                WREADY = 1'b0;
                if (AWVALID) begin
                    w_state_next = W_READY;
                end
            end
            W_READY: begin
                if (WVALID) begin
                    w_state_next = W_IDLE;
                    WREADY = 1'b1;
                    case (temp_awaddr_reg[3:2])
                        2'b00: slv_reg0 = WDATA;
                        2'b01: slv_reg1 = WDATA;
                        2'b10: slv_reg2 = WDATA;
                        2'b11: slv_reg3 = WDATA;
                    endcase
                end

            end
        endcase
    end

    // WRITE Transaction, B Channel transfer
    typedef enum {
        B_IDLE,
        B_VALID
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            b_state <= B_IDLE;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        BVALID       = 1'b0;
        BRESP        = 2'b00;
        case (b_state)
            B_IDLE: begin
                BVALID = 1'b0;
                if (WVALID & WREADY) begin
                    b_state_next = B_VALID;
                end
            end
            B_VALID: begin
                BVALID       = 1'b1;
                BRESP        = 2'b00;
                b_state_next = B_IDLE;
            end
        endcase
    end

    // READ Transaction, AR Channel transfer
    typedef enum {
        AR_IDLE,
        AR_READY
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;
    logic [3:0] temp_araddr_reg, temp_araddr_next;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            ar_state        <= AR_IDLE;
            temp_araddr_reg <= 0;
        end else begin
            ar_state        <= ar_state_next;
            temp_araddr_reg <= temp_araddr_next;
        end
    end

    always_comb begin
        ar_state_next    = ar_state;
        ARREADY          = 1'b0;
        temp_araddr_next = temp_araddr_reg;
        case (ar_state)
            AR_IDLE: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next    = AR_READY;
                    temp_araddr_next = ARADDR;
                end
            end
            AR_READY: begin
                ARREADY = 1'b1;
                temp_araddr_next = ARADDR;
                ar_state_next = AR_IDLE;
            end
        endcase
    end

    // READ Transaction, R Channel transfer
    typedef enum {
        R_IDLE,
        R_VALID
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK, negedge ARESETn) begin
        if (!ARESETn) begin
            r_state <= R_IDLE;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RVALID       = 1'b0;
        RRESP        = 2'b00;
        case (r_state)
            R_IDLE: begin
                RVALID = 1'b0;
                if (ARVALID) begin
                    r_state_next = R_VALID;
                end
            end
            R_VALID: begin
                r_state_next = R_IDLE;
                RVALID       = 1'b1;
                RRESP        = 2'b00;
                case (temp_araddr_reg[3:2])
                    2'b00: RDATA = slv_reg0;
                    2'b01: RDATA = slv_reg1;
                    2'b10: RDATA = slv_reg2;
                    2'b11: RDATA = slv_reg3;
                endcase
            end
        endcase
    end
endmodule
