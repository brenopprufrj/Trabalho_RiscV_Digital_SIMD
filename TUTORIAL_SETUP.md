# Tutorial de Setup - CPU RISC-V Vetorial no Digital

> **CIRCUITO PRÉ-MONTADO**: O arquivo `Circuito.dig` já contém o circuito completo montado com CPU vetorial, memórias e conexões. Para utilizá-lo:
> 1. Execute `compile_vhdl.bat` (Windows) ou `compile_vhdl.sh` (Linux/macOS) para compilar os módulos VHDL
> 2. Configure o Digital conforme a **Seção 3** (caminho do GHDL no Edit → Settings)
> 3. Abra `Circuito.dig` no Digital
> 4. Clique duas vezes no componente `riscv_cpu_vector` e configure:
>    - Aba **Basic**: Altere o **Code file** para o caminho absoluto do `riscv_cpu_vector.vhd` no seu computador
>    - Aba **Options**: Configure o **GHDL Options** com `--std=08 --ieee=synopsys --workdir="CAMINHO_DA_PASTA"`
>
> As instruções abaixo são para quem deseja reconstruir o circuito do zero.

---

## 1. Pré-requisitos

- **Digital Simulator**: https://github.com/hneemann/Digital
- **GHDL**: https://github.com/ghdl/ghdl/releases

> **IMPORTANTE**: O GHDL deve estar nas variáveis de ambiente (PATH) do sistema.

---

## 2. Compilar Componentes

Os componentes VHDL devem ser pré-compilados antes de usar no Digital. O script compila tanto os módulos escalares quanto os vetoriais.

**Windows:**
```cmd
compile_vhdl.bat
```

**Linux/macOS:**
```bash
chmod +x compile_vhdl.sh
./compile_vhdl.sh
```

### Módulos Compilados

| Módulo | Descrição |
|--------|-----------|
| `alu.vhd` | ALU escalar |
| `register_file.vhd` | Banco de registradores escalares |
| `vector_alu.vhd` | ALU vetorial (4 lanes) |
| `vector_register_file.vhd` | Banco de registradores vetoriais (128 bits) |
| `vector_forwarding_unit.vhd` | Forwarding vetorial |
| `vector_pipeline_regs.vhd` | Registradores de pipeline vetoriais |
| `riscv_cpu_vector.vhd` | Top-level com extensão vetorial |

---

## 3. Configurar o Digital

1. Abra o Digital → **Edit → Settings**
2. Na aba **Advanced**, configure:
   - **GHDL**: Caminho do executável (ou deixe vazio se GHDL estiver no PATH)

---

## 4. Adicionar a CPU Vetorial no Circuito

1. **Components → Misc. → External File**
2. Configure na aba **Basic**:

| Campo | Valor |
|-------|-------|
| Application type | GHDL |
| Label | riscv_cpu_vector |
| Code file | Selecione `riscv_cpu_vector.vhd` |
| Inputs | `clk_i,reset_i,load_enable_i,imem_data_i:32,dmem_rdata_i:32,reg_sel_i:5,vreg_sel_i:5` |
| Outputs | `imem_addr_o:32,dmem_addr_o:32,dmem_wdata_o:32,dmem_we_o,pc_debug_o:32,instr_debug_o:32,alu_result_debug_o:32,reg_debug_o:32,stage_if_pc_o:32,stage_id_pc_o:32,stage_ex_pc_o:32,hazard_stall_o,hazard_flush_o,vreg_debug_lane0_o:32,vreg_debug_lane1_o:32,vreg_debug_lane2_o:32,vreg_debug_lane3_o:32,valu_result_lane0_o:32,valu_result_lane1_o:32,valu_result_lane2_o:32,valu_result_lane3_o:32` |

3. Na aba **Options**, configure o campo **GHDL Options**:
   ```
   --std=08 --ieee=synopsys --workdir="CAMINHO_DA_PASTA_DO_PROJETO"
   ```
   
   Substitua `CAMINHO_DA_PASTA_DO_PROJETO` pelo caminho completo onde estão os arquivos VHDL.

---

## 5. Conectar Memórias

O RISC-V usa **endereçamento de bytes**, mas as memórias do Digital usam **endereçamento de palavras**. É necessário usar um **Splitter** para converter os endereços.

### Configurando o Splitter

1. **Components → Wires → Splitter**
2. Configure:
   - **Input Bits**: 32
   - **Output Splitting**: Separe em 3 partes

### Exemplo para memória de 256 palavras (8 bits de endereço):

```
Splitter: 32 bits → [2, 8, 22]
  - Saída 0: bits 0-1 (descartar - alinhamento de bytes)
  - Saída 1: bits 2-9 (usar como endereço da memória)
  - Saída 2: bits 10-31 (descartar - não usado)
```

### Memória de Instruções (ROM)
```
imem_addr_o (32 bits) → Splitter → Saída 1 (8 bits) → ROM Address
ROM Data → imem_data_i
```

### Memória de Dados (RAM)
```
dmem_addr_o (32 bits) → Splitter → Saída 1 (8 bits) → RAM Address
dmem_wdata_o → RAM Data In
dmem_we_o → RAM Write Enable
RAM Data Out → dmem_rdata_i
```

### Tabela de Bits por Tamanho de Memória

| Palavras | Bits de Endereço | Splitter Config |
|----------|------------------|-----------------|
| 64       | 6                | [2, 6, 24]      |
| 256      | 8                | [2, 8, 22]      |
| 1024     | 10               | [2, 10, 20]     |
| 4096     | 12               | [2, 12, 18]     |

---

## 6. Sinais de Debug Vetorial

### Novos Sinais de Entrada

| Sinal | Bits | Descrição |
|-------|------|-----------|
| `vreg_sel_i` | 5 | Seleção do registrador vetorial para debug (0-31) |

### Novos Sinais de Saída

| Sinal | Bits | Descrição |
|-------|------|-----------|
| `vreg_debug_lane0_o` | 32 | Lane 0 (bits 31:0) do vreg selecionado |
| `vreg_debug_lane1_o` | 32 | Lane 1 (bits 63:32) do vreg selecionado |
| `vreg_debug_lane2_o` | 32 | Lane 2 (bits 95:64) do vreg selecionado |
| `vreg_debug_lane3_o` | 32 | Lane 3 (bits 127:96) do vreg selecionado |
| `valu_result_lane*_o` | 32 | Resultado da VALU por lane |

> **Nota:** As saídas vetoriais já estão divididas em 4 lanes de 32 bits para compatibilidade com o limite de 64 bits do Splitter do Digital.

---

## 7. Procedimento de Execução

1. Ative `load_enable_i = 1`
2. Carregue o programa na ROM
3. Aplique `reset_i = 1` por alguns ciclos
4. Desative `reset_i = 0`
5. Desative `load_enable_i = 0`
6. A CPU executará a partir do endereço 0x00000000

---

## 8. Exemplo de Programa Vetorial

Programa de teste para a ROM (formato hexadecimal):

```hex
0050208B   # vaddi v1, v0, 5    (v1 = [5, 5, 5, 5])
0030210B   # vaddi v2, v0, 3    (v2 = [3, 3, 3, 3])
0020818B   # vadd  v3, v1, v2   (v3 = [8, 8, 8, 8])
4020820B   # vsub  v4, v1, v2   (v4 = [2, 2, 2, 2])
0020B28B   # vslli v5, v1, 2    (v5 = [20, 20, 20, 20])
00000013   # nop
```

**Para carregar no Digital:**
1. Clique com o botão direito na ROM
2. Selecione **Edit content**
3. Cole os valores hexadecimais (um por linha, sem os comentários)

### Verificação

1. Configure `vreg_sel_i = 1` para observar v1
2. Execute alguns ciclos
3. Verifique se `vreg_debug_lane*_o` mostra `0x00000005` em cada lane
4. Configure `vreg_sel_i = 3` para observar v3
5. Verifique se mostra `0x00000008` (resultado de 5+3)

---

## 9. Sinais de Debug Escalares (Mantidos)

| Sinal | Descrição |
|-------|-----------|
| `pc_debug_o` | Valor atual do PC |
| `instr_debug_o` | Instrução no estágio ID |
| `alu_result_debug_o` | Resultado da ALU escalar |
| `reg_debug_o` | Valor do registrador escalar selecionado |
| `stage_if/id/ex_pc_o` | PC em cada estágio |
| `hazard_stall_o` | Indica stall |
| `hazard_flush_o` | Indica flush |

Use `reg_sel_i` (0-31) para selecionar qual registrador escalar observar em `reg_debug_o`.

---

## 10. Solução de Problemas

### Erro: "GHDL not found"
- Verifique se o GHDL está instalado e no PATH
- Reinicie o Digital após instalar o GHDL

### Erro: Entidades não encontradas
- Certifique-se de que todos os arquivos VHDL foram compilados
- Execute `compile_vhdl.bat` ou `compile_vhdl.sh` novamente

### Saídas não mudam
- Verifique se o clock está funcionando
- Verifique se `load_enable_i = 0` e `reset_i = 0`
- Verifique se a memória de instruções está carregada

### Registradores vetoriais mostram valores incorretos
- Verifique se as instruções usam o opcode correto (`0x0B` ou `0x2B`)
- Verifique se `vreg_sel_i` está configurado para o registrador desejado

---

## 11. Referências

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- [Digital Simulator](https://github.com/hneemann/Digital)
- [GHDL](https://github.com/ghdl/ghdl)
- [REFERENCIA_INSTRUCOES_VETORIAIS.md](REFERENCIA_INSTRUCOES_VETORIAIS.md) - Documentação completa das instruções vetoriais
