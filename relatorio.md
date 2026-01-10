# Relatório Técnico - Extensão Vetorial da CPU RISC-V 32-bit

## 1. Resumo

Este relatório descreve a implementação da extensão vetorial para a CPU RISC-V de 32 bits (RV32I) com arquitetura de pipeline de 5 estágios, desenvolvida em VHDL para uso no simulador Digital. A extensão adiciona suporte a operações SIMD (Single Instruction, Multiple Data) com registradores de 128 bits (4 lanes × 32 bits).

---

## 2. Arquitetura Vetorial

### 2.1. Registradores Vetoriais

| Característica | Especificação |
|----------------|---------------|
| Quantidade | 32 registradores (`v0`-`v31`) |
| Largura | 128 bits (4 lanes × 32 bits) |
| `v0` | **Gravável** (diferente de `x0` escalar) |

### 2.2. Modelo SIMD

Cada instrução vetorial opera em paralelo sobre 4 elementos de 32 bits:

```
┌─────────────────────────────────────────────────────────────┐
│                  Registrador Vetorial (128 bits)            │
├──────────────┬──────────────┬──────────────┬───────────────┤
│   Lane 3     │    Lane 2    │    Lane 1    │    Lane 0     │
│ bits 127:96  │  bits 95:64  │  bits 63:32  │  bits 31:0    │
└──────────────┴──────────────┴──────────────┴───────────────┘
```

---

## 3. Instruções Vetoriais Implementadas

### 3.1. Opcodes Utilizados

A extensão utiliza os opcodes reservados `custom-0` e `custom-1` do RISC-V:

| Nome | Opcode (binário) | Opcode (hex) | Uso |
|------|------------------|--------------|-----|
| `custom-0` | `0001011` | `0x0B` | Instruções R-type e I-type vetoriais |
| `custom-1` | `0101011` | `0x2B` | VAUIPC (U-type vetorial) |

### 3.2. Instruções R-type (Registrador-Registrador)

Formato: `funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]`

| Instrução | funct7 | funct3 | Operação |
|-----------|--------|--------|----------|
| `vadd vd, vs1, vs2` | `0000000` | `000` | `vd[i] = vs1[i] + vs2[i]` |
| `vsub vd, vs1, vs2` | `0100000` | `000` | `vd[i] = vs1[i] - vs2[i]` |
| `vsll vd, vs1, vs2` | `0000000` | `001` | `vd[i] = vs1[i] << vs2[i][4:0]` |
| `vsrl vd, vs1, vs2` | `0000000` | `101` | `vd[i] = vs1[i] >> vs2[i][4:0]` |

### 3.3. Instruções I-type (Imediato)

Formato: `imm[11:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]`

| Instrução | funct3 | Operação |
|-----------|--------|----------|
| `vaddi vd, vs1, imm` | `010` | `vd[i] = vs1[i] + imm` |
| `vslli vd, vs1, shamt` | `011` | `vd[i] = vs1[i] << shamt` |
| `vsrli vd, vs1, shamt` | `111` | `vd[i] = vs1[i] >> shamt` |

> **Nota:** Para `vslli` e `vsrli`, usa-se apenas os 5 bits menos significativos do imediato (shamt).

### 3.4. Instrução U-type (VAUIPC)

Formato: `imm[31:12] | rd[4:0] | opcode[6:0]`

| Instrução | Opcode | Operação |
|-----------|--------|----------|
| `vauipc vd, imm` | `0101011` | `vd[i] = PC + (imm << 12)` |

---

## 4. Escolhas de Projeto

### 4.1. Codificação de Instruções

**Justificativa:** Utilizamos os opcodes `custom-0` (`0x0B`) e `custom-1` (`0x2B`) reservados pela especificação RISC-V para extensões personalizadas. Esta escolha:

- ✅ Mantém compatibilidade com RV32I base
- ✅ Evita conflitos com instruções padrão
- ✅ Permite fácil identificação no decodificador

**Diferenciação das operações:**
- `funct7[5]` diferencia `vadd` (`0`) de `vsub` (`1`)
- `funct3` diferencia operações de shift das aritméticas

### 4.2. Unidade Lógico-Aritmética Vetorial (VALU)

A VALU implementa 4 ALUs paralelas, uma para cada lane:

```
                    ┌─────────────────────────────────┐
                    │            VALU                 │
  Operando A (128)──┼──►┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐│
                    │   │ALU 3│ │ALU 2│ │ALU 1│ │ALU 0││
  Operando B (128)──┼──►└──┬──┘ └──┬──┘ └──┬──┘ └──┬──┘│
                    │      │       │       │       │   │
  Controle (4 bits)─┼──────┼───────┼───────┼───────┼───┤
                    │      ▼       ▼       ▼       ▼   │
                    │   ┌─────────────────────────────┐│
  Resultado (128)◄──┼───│        Resultado            ││
                    │   └─────────────────────────────┘│
                    └─────────────────────────────────┘
```

**Códigos de controle:**

| Código | Binário | Operação |
|--------|---------|----------|
| `0` | `0000` | ADD |
| `1` | `0001` | SUB |
| `5` | `0101` | SLL |
| `6` | `0110` | SRL |

### 4.3. Forwarding Vetorial

Para evitar hazards de dados nas operações vetoriais, implementamos uma **Vector Forwarding Unit** dedicada:

```vhdl
-- Fontes de forwarding
vec_fwd_a_sel: "00" = registrador, "01" = MEM, "10" = WB
vec_fwd_b_sel: "00" = registrador, "01" = MEM, "10" = WB
```

O forwarding vetorial opera em paralelo com o forwarding escalar, detectando dependências entre instruções vetoriais consecutivas.

### 4.4. Registro durante Escrita (Read-During-Write)

O banco de registradores vetoriais implementa **forwarding interno** para leituras durante escrita:

```vhdl
-- Se lendo e escrevendo no mesmo registrador simultaneamente,
-- retorna o valor sendo escrito (data_i) em vez do valor armazenado
if (rd1_addr_i = wd_addr_i and we_i = '1') then
    rd1_data_o <= data_i;  -- Forward do dado sendo escrito
else
    rd1_data_o <= regs(to_integer(unsigned(rd1_addr_i)));
end if;
```

Esta escolha elimina bolhas de pipeline quando uma instrução lê um registrador que está sendo escrito no mesmo ciclo.

### 4.5. Registradores de Pipeline Vetoriais

Adicionamos registradores de pipeline dedicados para dados vetoriais:

| Registrador | Dados Armazenados |
|-------------|-------------------|
| ID/EX | vs1_data (128), vs2_data (128), is_vector |
| EX/MEM | valu_result (128), vd_addr, v_reg_write |
| MEM/WB | valu_result (128), vd_addr, v_reg_write |

---

## 5. Estrutura de Arquivos

### 5.1. Módulos Vetoriais (Novos)

| Arquivo | Descrição |
|---------|-----------|
| `vector_alu.vhd` | ALU vetorial (4 lanes paralelas) |
| `vector_register_file.vhd` | Banco de 32 registradores vetoriais (128 bits) |
| `vector_forwarding_unit.vhd` | Forwarding para operandos vetoriais |
| `vector_pipeline_regs.vhd` | Registradores de pipeline vetoriais |
| `riscv_cpu_vector.vhd` | Top-level com extensão vetorial |

### 5.2. Módulos Modificados

| Arquivo | Modificações |
|---------|--------------|
| `instruction_decoder.vhd` | Decodificação de opcodes `custom-0/1` |
| `control_unit.vhd` | Sinais de controle vetoriais |
| `hazard_unit.vhd` | Detecção de hazards vetoriais |

---

## 6. Diagrama da Arquitetura

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                    RISC-V CPU com Extensão Vetorial                            │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  ┌────┐   ┌───────┐   ┌────┐   ┌───────┐   ┌────┐   ┌────────┐   ┌────┐       │
│  │ PC │──►│ IF/ID │──►│ ID │──►│ ID/EX │──►│ EX │──►│ EX/MEM │──►│MEM │       │
│  └────┘   └───────┘   └────┘   └───────┘   └────┘   └────────┘   └────┘       │
│     │                    │         │          │                     │          │
│     ▼                    ▼         ▼          ▼                     ▼          │
│  ┌─────┐            ┌────────┐ ┌──────┐   ┌─────┐               ┌────────┐     │
│  │IMEM │            │DECODER │ │REGFILE│  │ ALU │               │  DMEM  │     │
│  └─────┘            │CONTROL │ │(x0-31)│  └─────┘               └────────┘     │
│                     └────────┘ └──────┘                              │         │
│                          │         │          │         ┌────────┐   ▼         │
│                          │     ┌──────┐   ┌──────┐      │MEM/WB  │◄──┘         │
│                          │     │VREGFILE│ │ VALU │      └────────┘             │
│                          │     │(v0-31)│  │4-lane│           │                 │
│                          │     └──────┘   └──────┘           ▼                 │
│                          │         ▲          │          ┌────┐                │
│                          │         │          │          │ WB │                │
│                          ▼         │          ▼          └────┘                │
│                     ┌────────────────────────────────────────────────────┐     │
│                     │  HAZARD UNIT ◄──► FORWARDING UNIT                  │     │
│                     │                   (Escalar + Vetorial)             │     │
│                     └────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Interface de Debug Vetorial

Sinais de saída para observação dos registradores vetoriais:

| Sinal | Bits | Descrição |
|-------|------|-----------|
| `vreg_sel_i` | 5 | Seleção do registrador vetorial (entrada) |
| `vreg_debug_lane0_o` | 32 | Lane 0 (bits 31:0) do vreg selecionado |
| `vreg_debug_lane1_o` | 32 | Lane 1 (bits 63:32) do vreg selecionado |
| `vreg_debug_lane2_o` | 32 | Lane 2 (bits 95:64) do vreg selecionado |
| `vreg_debug_lane3_o` | 32 | Lane 3 (bits 127:96) do vreg selecionado |
| `valu_result_lane*_o` | 32 | Resultado da VALU por lane |

> **Nota:** As saídas estão divididas em 4 lanes de 32 bits devido à limitação de 64 bits do Splitter do Digital.

---

## 8. Conclusão

A extensão vetorial implementada atende aos requisitos da Tarefa 2:

- ✅ Suporte a versões vetoriais de `add`, `addi`, `auipc`, `sub`
- ✅ Suporte a versões vetoriais de `sll`, `slli`, `srl`, `srli`
- ✅ Mantém pipeline de 5 estágios
- ✅ Compatível com subset RV32I existente
- ✅ Codificação aderente à proposta RISC-V (opcodes `custom-0/1`)
- ✅ Sinais de debug para aferição de estados internos vetoriais
