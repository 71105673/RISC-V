`timescale 1ns / 1ps

interface adder_intf;   // InterFace
    logic       clk;
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] result;
endinterface //adder_intf

class transaction;      // Data의 묶음
    rand bit [7:0] a;
    rand bit [7:0] b;
    bit [8:0] result;
endclass //transaction

class generator;        // Class의 값을 생성
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox #(transaction) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox;   // this.() -> 이 클래스의 멤버에 매개변수로 들어온 new()라는애를 연결해준다.
    endfunction 

    task run(int run_count);
        repeat (run_count) begin
            tr = new();     // make instance. 실체화 시킨다. memory에 class 자료형을 만든다.
            tr.randomize(); // a, b라는 rand bit 변수에 값을 넣겠다. 라는 소리
            gen2drv_mbox.put(tr);   // random하게 생성된 핸들러 값을 메일박스에 넣겠다.
            #10;
        end
    endtask 
endclass //generator

class driver;
    transaction tr;                 // 자료형을 받을 수 있어야 한다.
    virtual adder_intf adder_if;    // 인터페이스 변수형으로 adder_if
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox #(transaction) gen2drv_mbox, virtual adder_intf adder_if);
        this.gen2drv_mbox = gen2drv_mbox;   // 매개변수를 연결시켜주겠다.     
        this.adder_if = adder_if;           // 매개변수를 연결시켜주겠다. 
    endfunction 

    task run();
        forever begin
            gen2drv_mbox.get(tr);   // 만들어둔 tr에 이 값을 넣겠다.
            adder_if.a = tr.a;      // 그리고 interface에 넘기겠다.
            adder_if.b = tr.b;
            @(posedge adder_if.clk);
        end
    endtask 
endclass //driver

class monitor;
    transaction tr;                 // 자료형을 받을 수 있어야 한다.
    virtual adder_intf adder_if;    // 인터페이스 변수형으로 adder_if
    mailbox #(transaction) mon2scb_mbox;

    function new(mailbox #(transaction) mon2scb_mbox, virtual adder_intf adder_if);
        this.mon2scb_mbox = mon2scb_mbox;   // 매개변수를 연결시켜주겠다.     
        this.adder_if = adder_if;           // 매개변수를 연결시켜주겠다. 
    endfunction 

    task run();
        forever begin
            tr = new();
            @(posedge adder_if.clk);
            #1;
            tr.a = adder_if.a;
            tr.b = adder_if.b;
            tr.result = adder_if.result;
            mon2scb_mbox.put(tr);
        end
    endtask 
endclass //monitor

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    bit [7:0] a, b;

    function new(mailbox #(transaction) mon2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction //new()

    task run();
        // tr = new();
        forever begin
            mon2scb_mbox.get(tr);
            a = tr.a;
            b = tr.b;
            if (tr.result == (a + b)) begin
                $display("Pass!: %d + %d = %d", a, b, tr.result);
            end else begin
                $display("FAIL!: %d + %d = %d", a, b, tr.result);
            end
        end
    endtask 
endclass //scoreboard

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    function new(virtual adder_intf adder_if);
        gen2drv_mbox = new();       // mailbox라는 것을 실제 메모리에 생성 -> 인스턴스화
        mon2scb_mbox = new(); 
        gen = new(gen2drv_mbox);
        drv = new(gen2drv_mbox, adder_if);
        mon = new(mon2scb_mbox, adder_if);
        scb = new(mon2scb_mbox);
    endfunction //new()

    task run();
        fork
            gen.run(10);    // 매개변수 n번 돌리기
            drv.run();
            mon.run();
            scb.run();
        join_any
        #100 $finish;
    endtask 

endclass //environment

module tb_adder ();
    environment env;
    adder_intf adder_if();

    adder dut(
        .clk(adder_if.clk),
        .a(adder_if.a),
        .b(adder_if.b),
        .result(adder_if.result)
    );

    always #5 adder_if.clk = ~adder_if.clk;

    initial begin
        adder_if.clk = 1;
    end

    initial begin
        env = new(adder_if);    // 이 떄, 인스턴스가 실제 만들어지며, inf정보가 env에 들어간다.
        env.run();
    end

endmodule