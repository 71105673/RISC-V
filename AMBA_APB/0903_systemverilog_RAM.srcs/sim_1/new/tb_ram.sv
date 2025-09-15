`timescale 1ns / 1ps

interface ram_intf (
    input bit clk
);  // clk를 매개변수로 넣을 수 있다 (global siganl)
    logic [7:0] addr;                       // Interface의 경우는 Logic으로 쓰는 것이 일반적(입력/출력 둘 다 가능)
    logic we;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface  //ram_intf

///////////////////////////////////////////////////////////////////////////

class transaction;
    rand logic [7:0] addr;
    rand logic       we;
    rand logic [7:0] wdata;
    logic      [7:0] rdata;

    task print(string name);  // Method
        $display("[%s] we=%d, addr=%h, wdata=%h, rdata=%h", name, we, addr,
                 wdata, rdata);
    endtask
endclass  //transaction

///////////////////////////////////////////////////////////////////////////

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;  // Handler 생성 -> 멤버변수
    event scb2gen_event;

    function new(
        mailbox#(transaction) gen2drv_mbox, event scb2gen_event
    );  // 초기화할 때, mailbox 내부의 값을 주겠다. -> 매개변수
        // 만약 this가 없이 이름이 똑같으면? -> 매개변수가 우선순위가 높다.
        this.gen2drv_mbox = gen2drv_mbox;   // 주소 값을 멤버변수 안에 넣겠다. (This로 멤버변수 표시
        this.scb2gen_event = scb2gen_event;
    endfunction

    task run(int loop);
        repeat (loop) begin
            tr = new();  // 인스턴스 만들어 연결
            if (!tr.randomize()) $error("Randomization Failed!");
            tr.print("GEN");
            gen2drv_mbox.put(tr);  // 포인터를 put해라(넣어라)
            //#20;
            @(scb2gen_event);
        end
    endtask
endclass  //generator

///////////////////////////////////////////////////////////////////////////

class driver;
    transaction tr;  // Handler
    mailbox #(transaction) gen2drv_mbox;  // mailbox 정보
    virtual ram_intf ram_if;                // 하드웨어인 interfact 연결하기 위해 virtual 선언
    event drv2mon_event;

    function new(mailbox#(transaction) gen2drv_mbox, virtual ram_intf ram_if,
                 event drv2mon_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_if = ram_if;
        this.drv2mon_event = drv2mon_event;
    endfunction

    task run();
        forever begin
            gen2drv_mbox.get(tr);  // mailbox에서 가져온 값과
            ram_if.addr = tr.addr;          // tr의 값을 인터페이스에 넣어준다
            ram_if.we = tr.we;
            if (tr.we)
                ram_if.wdata = tr.wdata;  // we가 1일 때, write 해준다.   
            //->drv2mon_event;                // Event Trigger
            tr.print("DRV");
            @(posedge ram_if.clk);          // clk이 발생하면? RAM에 값을 넣어준다.
            #1;
        end
    endtask
endclass  //driver

///////////////////////////////////////////////////////////////////////////

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_intf ram_if;
    event drv2mon_event;

    function new(mailbox#(transaction) mon2scb_mbox, virtual ram_intf ram_if,
                 event drv2mon_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_if = ram_if;
        this.drv2mon_event = drv2mon_event;
    endfunction

    task run();
        forever begin
            tr = new();
            //@(drv2mon_event);                       // Event를 기다림
            @(posedge ram_if.clk);
            #1;
            tr.addr  = ram_if.addr;  // s/w의 값을 h/w에 넣겟다
            tr.we    = ram_if.we;
            tr.wdata = ram_if.wdata;
            if (!tr.we) tr.rdata = ram_if.rdata;  // we이 0이어야 읽겠다!
            tr.print("MON");
            mon2scb_mbox.put(tr);
        end
    endtask
endclass  //monitor

///////////////////////////////////////////////////////////////////////////

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event scb2gen_event;
    int total_cnt, pass_cnt, fail_cnt;

    logic [7:0] ref_mem[0:2**8-1];
    logic [7:0] ref_rdata;

    function new(mailbox#(transaction) mon2scb_mbox, event scb2gen_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_event = scb2gen_event;
        this.total_cnt = 0;         // 매개변수랑 같은 이름은 없어서 this 없어도 된다
        this.pass_cnt = 0;
        this.fail_cnt = 0;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            total_cnt++;
            tr.print("SCB");
            if (tr.we) begin
                ref_mem[tr.addr] = tr.wdata;
            end else begin
                ref_rdata = ref_mem[tr.addr];
                if (ref_rdata === tr.rdata) begin
                    pass_cnt++;
                    $display(
                        "PASS! Matched Data! ref_rdata: %h == tr.rdata: %h",
                        ref_rdata, tr.rdata);
                end else begin
                    fail_cnt++;
                    $display(
                        "FAIL! Dismatched Data! ref_rdata: %h != tr.rdata: %h",
                        ref_rdata, tr.rdata);
                end
            end
            $display("");  // 줄 바꿈
            ->scb2gen_event;  // Event Trigger
        end
    endtask
endclass  //scoreboard

///////////////////////////////////////////////////////////////////////////

class environment;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    event                  drv2mon_event;
    event                  scb2gen_event;

    function new(virtual ram_intf ram_if);
        gen2drv_mbox = new();  // 인스턴스 생성
        mon2scb_mbox = new();
        gen          = new(gen2drv_mbox, scb2gen_event);
        drv          = new(gen2drv_mbox, ram_if, drv2mon_event);
        mon          = new(mon2scb_mbox, ram_if, drv2mon_event);
        scb          = new(mon2scb_mbox, scb2gen_event);
    endfunction  //new()

    task run(int loop);
        fork
            gen.run(loop);
            drv.run();
            mon.run();
            scb.run();
        join_any
        $display("Total : %d", scb.total_cnt);
        $display("Pass : %d", scb.pass_cnt);
        $display("Fail : %d", scb.fail_cnt);
        #50;
    endtask
endclass  //environment

///////////////////////////////////////////////////////////////////////////

module tb_ram ();
    bit clk;
    ram_intf ram_if (clk);
    environment env;

    ram DUT (
        .clk(clk),
        .addr(ram_if.addr),
        .we(ram_if.we),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1;
    end

    initial begin
        env = new(ram_if);
        env.run(1000);
        $finish;
    end
endmodule
