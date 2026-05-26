// =============================================================================
// tb_multiplier32FP.v  -  Testbench para multiplier32FP
// IEEE 754 SP Floating-Point Multiplier
// Lê vetores de "vetor.txt" e aplica conforme especificação:
//   clk  : 25 MHz  (T=40ns)
//   rst_n: 1 → 0 em 5ns → 1 em 10ns
//   start_i: primeiro em 15ns; seguintes: 2 ciclos após done_o
// Latência do pipeline: 2 ciclos de clock
// =============================================================================
`timescale 1ns/1ps

module tb_multiplier32FP;

    reg         clk;
    reg         rst_n;
    reg  [31:0] a_i, b_i;
    reg         start_i;
    wire [31:0] product_o;
    wire        done_o;
    wire        nan_o, infinit_o, overflow_o, underflow_o;

    // ----- DUT ---------------------------------------------------------------
    multiplier32FP #(.DATA_W(32), .EXP_W(8), .MAN_W(23)) dut (
        .clk(clk), .rst_n(rst_n),
        .a_i(a_i), .b_i(b_i),
        .start_i(start_i),
        .product_o(product_o), .done_o(done_o),
        .nan_o(nan_o), .infinit_o(infinit_o),
        .overflow_o(overflow_o), .underflow_o(underflow_o)
    );

    // ----- Clock 25 MHz (T=40ns) --------------------------------------------
    initial clk = 1'b0;
    always  #20 clk = ~clk;

    // ----- Reset per spec ----------------------------------------------------
    initial begin
        rst_n = 1'b1;
        #5  rst_n = 1'b0;
        #5  rst_n = 1'b1;
    end

    // ----- Vector storage (máx 256 vetores) ----------------------------------
    reg [31:0] va[0:255];
    reg [31:0] vb[0:255];
    integer    nv;   // número de vetores lidos
    integer    fd, sr;
    reg [31:0] ta, tb;

    initial begin : read_vectors
        integer k;
        nv = 0;
        fd = $fopen("vetor.txt","r");
        if (fd == 0) begin $display("ERRO: vetor.txt não encontrado"); $finish; end
        while (!$feof(fd)) begin
            sr = $fscanf(fd," %h %h", ta, tb);
            if (sr == 2) begin
                va[nv] = ta; vb[nv] = tb; nv = nv + 1;
            end
        end
        $fclose(fd);
        $display("[TB] %0d vetores lidos.", nv);
    end

    // ----- Tarefa: aplica um par de operandos e captura resultado ------------
    task run_one;
        input [31:0] opa, opb;
        input integer idx;
        begin
            // Apresenta operandos 1 ciclo antes de assert start_i
            a_i = opa;
            b_i = opb;
            // Pulsa start_i por 1 ciclo de clock
            @(posedge clk); #1;
            start_i = 1'b1;
            @(posedge clk); #1;
            start_i = 1'b0;
            // Pipeline tem 1 estágio após start: resultado sai no próximo posedge
            @(posedge clk); #1;
            // Agora done_o deve estar em alto e product_o válido
            $display(" %3d  %08h  %08h  | %08h  |  %b    %b    %b    %b",
                     idx, opa, opb, product_o,
                     nan_o, infinit_o, overflow_o, underflow_o);
            // Spec: próximo start_i deve vir 2 ciclos após done_o
            @(posedge clk); #1;
            @(posedge clk); #1;
        end
    endtask

    // ----- Estímulo principal ------------------------------------------------
    integer i;
    initial begin : stimulus
        a_i     = 32'd0;
        b_i     = 32'd0;
        start_i = 1'b0;

        // Aguarda reset e leitura dos vetores
        #25;   // reset finaliza em 10ns; esperamos até 25ns

        // Spec: primeiro start_i em 15ns — já estamos em 25ns (ok, dentro do
        // primeiro ciclo de operação válido)

        $display("\n Vec   A_i        B_i        | Product    | NaN Inf OVF UDF");
        $display("%s", {68{"-"}});

        for (i = 0; i < nv; i = i + 1)
            run_one(va[i], vb[i], i);

        $display("%s", {68{"-"}});
        $display("[TB] Simulação concluída. %0d vetores testados.", nv);
        $finish;
    end

    // ----- Waveform ----------------------------------------------------------
    initial begin
        $dumpfile("multiplier32FP.vcd");
        $dumpvars(0, tb_multiplier32FP);
    end

    // ----- Watchdog ----------------------------------------------------------
    initial begin
        #10_000_000;
        $display("[TB] TIMEOUT");
        $finish;
    end

endmodule
