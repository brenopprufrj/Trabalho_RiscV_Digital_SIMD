## Descrição:

	Estender o projeto original da nossa CPU RISC-V de 32 Bits para suportar o uso de instruções vetoriais. A nova CPU deve manter um pipeline com ao menos 5 estágios, e a implementação deve ser realizada usando blocos VHDL/Verilog no simulador Digital. As memórias de instruções e dados são distintas e entregam cada uma palavra por ciclo, além disso essas memórias devem ser modificadas para permitir carga de dados assíncrona (pode usar as memórias ROM e RAM do Digital). A CPU deve ser adaptada para não operar durante essa carga de dados (manter seu estado interno corrente), além de possuir um sinal de **reset**. Para esta tarefa apenas o pipeline de inteiros será implementado, especificamente as versões vetoriais das instruções a seguir devem ser suportadas:

* add, addi, auipc e sub  
* sll, slli, srl e srli

	Além das instruções acima listadas, que são baseadas na atividade prática AVX, essa CPU deve suportar o subconjunto da ISA RV32I da tarefa prática anterior. Essas novas instruções devem ser aderentes a proposta da arquitetura RISC-V, devendo constar no relatório final abordagem usada na codificação dessas novas instruções.

## Critérios de Avaliação:

	Serão avaliadas a corretude, aderência aos requisitos solicitados e qualidade do relatório descritivo. Os módulos VHDL/Verilog devem ser projetados para permitir que seus estados internos sejam aferidos, por exemplo, um somador pode exportar o seu cálculo de carry para depuração do circuito. Cada trio deve entregar um relatório descritivo do seu projeto, destacando as premissas adotadas e o projeto do circuito.