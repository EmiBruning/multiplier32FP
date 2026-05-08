# Multiplicador em Ponto Flutuante de 32 bits (IEEE 754)

## Descrição do Projeto
O objetivo deste projeto é desenvolver um multiplicador em ponto flutuante de 32 bits utilizando o padrão IEEE 754. O projeto conta com saída registrada e tem como meta a geração de um hardware que atinja a **máxima frequência de operação** possível.

1) positivo/negativo infinito (infinit_o): o expoente contém um padrão de bits reservado
11111111, a fração (mantissa) contém somente zeros, e o bit de sinal é 0 ou 1;
2) not a number (nan_o): o expoente contém um padrão de bits reservado 11111111, a
fração (mantissa) é diferente de zero, e o bit de sinal é 0 ou 1. Neste caso, ambos
operandos devem ser testados, a multiplicação não deve ser realizada e esta flag deve
ir para ‘1’. Neste caso, o valor na saída deve ser 0x00000000;
3) multiplicar números classificados como “zero sujo”. Uma representação chamada de
“zero sujo”, não-normalizada, permite representar números no intervalo entre 0 e o
primeiro número representável na forma normalizada (1,0 x 2-126). O bit de sinal pode
ser 0 ou 1 e o expoente contém o padrão de bits 00000000. A fração contém o padrão
de bits real para a magnitude do número, em vez da mantissa. Deste modo, não existe
nenhum 1 escondido neste formato. Números denormalizados, portanto, permitem que
os números em ponto flutuante atinjam valores muito menores, sacrificando a
quantidade de bits no significando;
4) arredondamento: round toward zero (arredonda em direção a zero): neste caso os bits
que estão a mais são desprezados.
5) overflow (overflow_o): ocorre quando o expoente resultante excede o valor máximo
permitido para este número normalizado. Neste caso, o valor na saída deve ser
0x7FFFFFFF;
6) underflow (underflow_o): devolve um número menor que o permitido normalizado. O
underflow ocorre quando uma operação é executada e retorna um valor que é menor
que o menor número não zero.
a. Sobre underflow: No padrão IEEE 754 precisão simples isto significa um valor
que tem a magnitude (valor absoluto) menor que 1,0 x 1-149 (número
denormalizado). Normalmente quando um número chega a este patamar de
magnitude ele é arredondado para zero, o que pode não fazer muita diferença
em uma adição, mas tem um grande efeito na multiplicação. Neste caso, o valor
na saída deve ser 0x00000000;

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
