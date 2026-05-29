`timescale 1ps/1ps

module multiplier32FP_tb;

    reg         clk;
    reg         rst_n;
    reg  [31:0] a_i, b_i;
    reg         start_i;
    wire [31:0] product_o;
    wire        done_o;
    wire        nan_o, infinit_o, overflow_o, underflow_o;

    // ----- DUT ---------------------------------------------------------------
    multiplier32FP dut (
        .clk(clk), .rst_n(rst_n),
        .a_i(a_i), .b_i(b_i),
        .start_i(start_i),
        .product_o(product_o), .done_o(done_o),
        .nan_o(nan_o), .infinit_o(infinit_o),
        .overflow_o(overflow_o), .underflow_o(underflow_o)
    );

    // ----- Clock 10 MHz (T=100ns -> half-period=50ns) -----------------------
    initial clk = 1'b0;
    always  #1000 clk = ~clk;

    // ----- Reset ------------------------------------------------------------
    initial begin
        rst_n = 1'b1;
        #100  rst_n = 1'b0;
        #2000 rst_n = 1'b1; // Mantém o reset baixo por um ciclo completo (100ns)
    end

    // ----- Vector storage (máx 256 vetores) ----------------------------------
    reg [31:0] va[0:255];
    reg [31:0] vb[0:255];
    integer    nv; 
    integer    fd, sr;
    reg [31:0] ta, tb;

    initial begin : read_vectors
        nv = 0;
        fd = $fopen("vetor.txt","r");
        if (fd == 0) begin 
            $display("ERRO: vetor.txt não encontrado. Nossos vetores não serão aplicados.");
        end else begin
            while (!$feof(fd)) begin
                sr = $fscanf(fd," %h %h", ta, tb);
                if (sr == 2) begin
                    va[nv] = ta; vb[nv] = tb; nv = nv + 1;
                end
            end
            $fclose(fd);
            $display("[TB] %0d vetores lidos.", nv);
        end
    end

    // ----- Tarefa: aplica um par de operandos e captura resultado ------------
    task run_one;
        input [31:0] opa, opb;
        input integer idx;
        begin
            a_i = opa;
            b_i = opb;
            @(posedge clk); #1;
            start_i = 1'b1;
            @(posedge clk); #1;
            start_i = 1'b0;
            @(posedge clk); #1;
            $display(" %3d  %08h  %08h  | %08h  |  %b    %b    %b    %b",
                     idx, opa, opb, product_o,
                     nan_o, infinit_o, overflow_o, underflow_o);
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

        // Aguarda a liberação do reset (sobe em 105ns) + margem de estabilização
        @(posedge rst_n);
        @(posedge clk); #1;   

        if (nv > 0) begin
            $display("\n Vec   A_i        B_i        | Product    | NaN Inf OVF UDF");
            $display("%s", {68{"-"}});

            for (i = 0; i < nv; i = i + 1)
                run_one(va[i], vb[i], i);

            $display("%s", {68{"-"}});
            $display("[TB] Todos os %0d vetores foram aplicados.", nv);
        end
        
        $display("[TB] Fim dos testes. O clock de 10 MHz continuará batendo infinitamente.");
    end

endmodule
