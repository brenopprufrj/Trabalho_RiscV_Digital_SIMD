# Instruções Vetoriais RISC-V - Referência

Documentação das instruções vetoriais implementadas na extensão da CPU RISC-V.

---

## Visão Geral

A extensão vetorial implementa operações SIMD com:
- **32 registradores vetoriais** (`v0`-`v31`)
- **128 bits por registrador** (4 lanes × 32 bits)
- **`v0` é gravável** (diferente de `x0` escalar)

---

## Opcodes

| Nome | Opcode (binário) | Opcode (hex) | Uso |
|------|------------------|--------------|-----|
| `custom-0` | `0001011` | `0x0B` | Instruções vetoriais R-type e I-type |
| `custom-1` | `0101011` | `0x2B` | VAUIPC (U-type) |

---

## Instruções R-type

Formato: `funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]`

| Instrução | funct7 | funct3 | Operação | Descrição |
|-----------|--------|--------|----------|-----------|
| `vadd vd, vs1, vs2` | `0000000` | `000` | `vd = vs1 + vs2` | Soma vetorial |
| `vsub vd, vs1, vs2` | `0100000` | `000` | `vd = vs1 - vs2` | Subtração vetorial |
| `vsll vd, vs1, vs2` | `0000000` | `001` | `vd = vs1 << vs2[4:0]` | Shift left lógico |
| `vsrl vd, vs1, vs2` | `0000000` | `101` | `vd = vs1 >> vs2[4:0]` | Shift right lógico |

---

## Instruções I-type

Formato: `imm[11:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]`

| Instrução | funct3 | Operação | Descrição |
|-----------|--------|----------|-----------|
| `vaddi vd, vs1, imm` | `010` | `vd = vs1 + imm` | Soma com imediato |
| `vslli vd, vs1, shamt` | `011` | `vd = vs1 << shamt` | Shift left com imediato |
| `vsrli vd, vs1, shamt` | `111` | `vd = vs1 >> shamt` | Shift right com imediato |

> **Nota:** Para `vslli` e `vsrli`, o imediato usa apenas os 5 bits menos significativos (shamt).

---

## VAUIPC (U-type)

Formato: `imm[31:12] | rd[4:0] | opcode[6:0]`

| Instrução | Opcode | Operação | Descrição |
|-----------|--------|----------|-----------|
| `vauipc vd, imm` | `0101011` | `vd = PC + (imm << 12)` | Add upper immediate to PC |

---

## Códigos de Controle da VALU

| Código | Binário | Operação |
|--------|---------|----------|
| `0` | `0000` | ADD |
| `1` | `0001` | SUB |
| `5` | `0101` | SLL |
| `6` | `0110` | SRL |

---

## Exemplos de Codificação

### vaddi v1, v0, 5
```
imm[11:0]    = 000000000101 (5)
rs1[4:0]     = 00000 (v0)
funct3[2:0]  = 010
rd[4:0]      = 00001 (v1)
opcode[6:0]  = 0001011

Binário: 0000 0000 0101 0000 0010 0000 1000 1011
Hex:     0x0050208B
```

### vadd v3, v1, v2
```
funct7[6:0]  = 0000000
rs2[4:0]     = 00010 (v2)
rs1[4:0]     = 00001 (v1)
funct3[2:0]  = 000
rd[4:0]      = 00011 (v3)
opcode[6:0]  = 0001011

Binário: 0000 0000 0010 0000 1000 0001 1000 1011
Hex:     0x0020818B
```

### vsub v4, v1, v2
```
funct7[6:0]  = 0100000
rs2[4:0]     = 00010 (v2)
rs1[4:0]     = 00001 (v1)
funct3[2:0]  = 000
rd[4:0]      = 00100 (v4)
opcode[6:0]  = 0001011

Binário: 0100 0000 0010 0000 1000 0010 0000 1011
Hex:     0x4020820B
```

---

## Assembler

Use o script `vector_assembler.py` para gerar código hexadecimal:

```bash
python vector_assembler.py programa.asm
```

Exemplo de programa (`programa.asm`):
```asm
vaddi v1, v0, 5    # v1 = [5, 5, 5, 5]
vaddi v2, v0, 3    # v2 = [3, 3, 3, 3]
vadd  v3, v1, v2   # v3 = [8, 8, 8, 8]
vsub  v4, v1, v2   # v4 = [2, 2, 2, 2]
vslli v5, v1, 2    # v5 = [20, 20, 20, 20]
nop
```

Saída para Digital ROM:
```
50208b,30210b,20818b,4020820b,20b28b,13
```
