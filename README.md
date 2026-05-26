# Multiplicador em Ponto Flutuante de 32 bits (IEEE 754)

## Casos Especiais Tratados

1. **Positivo/Negativo Infinito (`infinit_o`):** O expoente contém o padrão reservado `11111111`, a fração (mantissa) contém somente zeros e o bit de sinal é `0` ou `1`.
2. **Not a Number (`nan_o`):** O expoente contém o padrão reservado `11111111` e a fração (mantissa) é diferente de zero. Ambos os operandos são testados, a multiplicação não é realizada e a flag vai para `'1'`. Neste caso, o valor na saída é `0x00000000`.
3. **Zero Sujo (Números Denormalizados):** Permite representar números no intervalo entre 0 e o primeiro número representável na forma normalizada (1,0 x 2⁻¹²⁶). O expoente é `00000000` e a fração contém a magnitude real (sem o "1 escondido"). Isso permite atingir valores muito menores sacrificando bits da mantissa.
4. **Arredondamento (*Round toward zero*):** O arredondamento é feito em direção a zero, onde os bits excedentes são simplesmente desprezados (truncados).
5. **Overflow (`overflow_o`):** Ocorre quando o expoente resultante excede o valor máximo permitido para um número normalizado. A flag é ativada e o valor na saída é forçado para `0x7FFFFFFF`.
6. **Underflow (`underflow_o`):** Ocorre quando a operação retorna um valor com magnitude menor que 1,0 x 2⁻¹⁴⁹ (menor número não zero do padrão de precisão simples). Neste caso, a flag é ativada e o valor na saída é forçado para `0x00000000`.

---

## 🛠️ Entidade de Topo (Top Level)

O arquivo de topo do projeto deve ser nomeado como `multiplier32FP.v` . Abaixo está a declaração da entidade:

```verilog
module multiplier32FP (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire        start_i,
    output wire [31:0] product_o,
    output wire        done_o,
    output wire        nan_o,
    output wire        infinit_o,
    output wire        overflow_o,
    output wire        underflow_o
);
