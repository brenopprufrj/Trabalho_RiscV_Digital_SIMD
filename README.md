# CPU RISC-V 32-bit Pipeline com Extensão Vetorial (RV32I + V)

## Descrição do Projeto

Implementação de uma CPU RISC-V de 32 bits com arquitetura de pipeline de 5 estágios e extensão vetorial SIMD, desenvolvida em VHDL para uso com o simulador Digital.

### Características

- **Arquitetura**: RISC-V RV32I (subset de inteiros) + Extensão Vetorial
- **Pipeline**: 5 estágios (IF, ID, EX, MEM, WB)
- **SIMD**: 4 lanes × 32 bits = 128 bits por registrador vetorial
- **Registradores Vetoriais**: 32 registradores (`v0`-`v31`)
- **Hazard Handling**: Detecção de hazards + data forwarding (escalar e vetorial)
- **Memórias**: Interfaces separadas para instruções (ROM) e dados (RAM)
- **Debug**: Múltiplas saídas para aferição de estados internos escalares e vetoriais

### Instruções Escalares Suportadas (RV32I)

| Tipo | Instruções |
|------|------------|
| **Aritméticas** | `add`, `addi`, `auipc`, `sub` |
| **Lógicas** | `and`, `andi`, `or`, `ori`, `xor`, `xori` |
| **Deslocamento** | `sll`, `slli`, `srl`, `srli` |
| **Memória** | `lw`, `lui`, `sw` |
| **Controle** | `jal`, `jalr`, `beq`, `bne` |

### Instruções Vetoriais Suportadas

| Tipo | Instruções | Descrição |
|------|------------|-----------|
| **Aritméticas** | `vadd`, `vaddi`, `vauipc`, `vsub` | Operações em 4 lanes paralelas |
| **Deslocamento** | `vsll`, `vslli`, `vsrl`, `vsrli` | Shift em 4 lanes paralelas |

> Consulte [REFERENCIA_INSTRUCOES_VETORIAIS.md](REFERENCIA_INSTRUCOES_VETORIAIS.md) para detalhes de codificação.

---

## Estrutura do Pipeline

```
┌────┐    ┌────┐    ┌────┐    ┌─────┐    ┌────┐
│ IF │───►│ ID │───►│ EX │───►│ MEM │───►│ WB │
└────┘    └────┘    └────┘    └─────┘    └────┘
   │         │         │          │         │
   ▼         ▼         ▼          ▼         ▼
 Fetch   Decode   Execute    Memory    Write
  PC     RegFile    ALU       R/W      Back
         VRegFile   VALU
```

---

## Arquivos do Projeto

### Módulos Escalares

| Arquivo | Descrição |
|---------|-----------|
| `alu.vhd` | Unidade Lógico-Aritmética escalar |
| `register_file.vhd` | Banco de 32 registradores escalares |
| `instruction_decoder.vhd` | Decodificador de instruções + gerador de imediatos |
| `control_unit.vhd` | Unidade de controle principal |
| `pipeline_regs.vhd` | Registradores de pipeline escalares |
| `hazard_unit.vhd` | Detecção de hazards de dados e controle |
| `forwarding_unit.vhd` | Data forwarding escalar |
| `branch_comparator.vhd` | Comparador para instruções de branch |
| `program_counter.vhd` | Contador de programa |
| `riscv_cpu.vhd` | Top-level escalar |

### Módulos Vetoriais

| Arquivo | Descrição |
|---------|-----------|
| `vector_alu.vhd` | ALU vetorial (4 lanes paralelas) |
| `vector_register_file.vhd` | Banco de 32 registradores vetoriais (128 bits) |
| `vector_forwarding_unit.vhd` | Data forwarding vetorial |
| `vector_pipeline_regs.vhd` | Registradores de pipeline vetoriais |
| `riscv_cpu_vector.vhd` | **Top-level com extensão vetorial** |

### Documentação

| Arquivo | Descrição |
|---------|-----------|
| `TUTORIAL_SETUP.md` | Instruções de configuração e uso no Digital |
| `REFERENCIA_INSTRUCOES.md` | Referência das instruções escalares RV32I |
| `REFERENCIA_INSTRUCOES_VETORIAIS.md` | Referência das instruções vetoriais |
| `relatorio.md` | Relatório técnico da implementação vetorial |

---

## Como Usar

Consulte o arquivo [TUTORIAL_SETUP.md](TUTORIAL_SETUP.md) para instruções detalhadas sobre:

1. Configuração do ambiente (GHDL + Digital)
2. Compilação dos módulos VHDL
3. Adição de componentes no Digital
4. Criação do circuito de teste
5. Carregamento de programas vetoriais
6. Uso dos sinais de debug escalares e vetoriais

---

## Exemplo de Programa Vetorial

```assembly
# Programa de teste vetorial
        vaddi v1, v0, 5      # v1 = [5, 5, 5, 5]
        vaddi v2, v0, 3      # v2 = [3, 3, 3, 3]
        vadd  v3, v1, v2     # v3 = [8, 8, 8, 8]
        vsub  v4, v1, v2     # v4 = [2, 2, 2, 2]
        vslli v5, v1, 2      # v5 = [20, 20, 20, 20]
```

Código hexadecimal correspondente:
```
0050208B
0030210B
0020818B
4020820B
0020B28B
```

---

## Requisitos do Sistema

- Simulador Digital (v0.30 ou superior)
- GHDL (qualquer versão recente)
- Sistema operacional: Windows, Linux ou macOS

---

## Referências

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- [Digital Simulator](https://github.com/hneemann/Digital)
- [GHDL](https://github.com/ghdl/ghdl)

---

## Autores

Desenvolvido para a disciplina de Arquitetura de Computadores.
