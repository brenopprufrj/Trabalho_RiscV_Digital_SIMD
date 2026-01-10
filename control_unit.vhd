-- =============================================================================
-- Control Unit para CPU RISC-V de 32 bits
-- Gera sinais de controle baseado no opcode, funct3 e funct7
-- Extensão vetorial: suporta instruções vetoriais
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
    port (
        opcode_i      : in  std_logic_vector(6 downto 0);
        funct3_i      : in  std_logic_vector(2 downto 0);
        funct7_i      : in  std_logic_vector(6 downto 0);
        -- Sinais de controle
        reg_write_o   : out std_logic;                     -- Habilita escrita no reg file
        mem_to_reg_o  : out std_logic;                     -- Seleciona dado da memória vs ALU
        mem_write_o   : out std_logic;                     -- Habilita escrita na memória
        mem_read_o    : out std_logic;                     -- Sinaliza leitura de memória
        alu_src_o     : out std_logic;                     -- Seleciona rs2 vs imediato
        alu_ctrl_o    : out std_logic_vector(3 downto 0);  -- Controle da ALU
        branch_o      : out std_logic;                     -- Instrução de branch
        jump_o        : out std_logic;                     -- Instrução de jump (jal/jalr)
        auipc_o       : out std_logic;                     -- Instrução AUIPC
        jalr_o        : out std_logic;                     -- JALR (endereço base é rs1)
        lui_o         : out std_logic;                     -- LUI (load upper immediate)
        -- Sinais de controle vetoriais
        is_vector_o   : out std_logic;                     -- Instrução vetorial
        vreg_write_o  : out std_logic;                     -- Escrita em registrador vetorial
        valu_ctrl_o   : out std_logic_vector(3 downto 0);  -- Controle da ALU vetorial
        valu_src_o    : out std_logic;                     -- Seleção vs2 vs imediato
        vauipc_o      : out std_logic                      -- Instrução VAUIPC
    );
end entity control_unit;

architecture rtl of control_unit is

    -- Constantes de opcode (RV32I)
    constant OP_R_TYPE   : std_logic_vector(6 downto 0) := "0110011";
    constant OP_I_TYPE   : std_logic_vector(6 downto 0) := "0010011";
    constant OP_LOAD     : std_logic_vector(6 downto 0) := "0000011";
    constant OP_STORE    : std_logic_vector(6 downto 0) := "0100011";
    constant OP_BRANCH   : std_logic_vector(6 downto 0) := "1100011";
    constant OP_JAL      : std_logic_vector(6 downto 0) := "1101111";
    constant OP_JALR     : std_logic_vector(6 downto 0) := "1100111";
    constant OP_LUI      : std_logic_vector(6 downto 0) := "0110111";
    constant OP_AUIPC    : std_logic_vector(6 downto 0) := "0010111";
    
    -- Opcodes vetoriais
    constant OP_VECTOR   : std_logic_vector(6 downto 0) := "0001011";  -- custom-0
    constant OP_VAUIPC   : std_logic_vector(6 downto 0) := "0101011";  -- custom-1

    -- Constantes de operação ALU
    constant ALU_ADD    : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB    : std_logic_vector(3 downto 0) := "0001";
    constant ALU_AND    : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OR     : std_logic_vector(3 downto 0) := "0011";
    constant ALU_XOR    : std_logic_vector(3 downto 0) := "0100";
    constant ALU_SLL    : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SRL    : std_logic_vector(3 downto 0) := "0110";
    constant ALU_PASS_B : std_logic_vector(3 downto 0) := "0111";

    -- Sinais internos para controle da ALU
    signal alu_ctrl_r_type : std_logic_vector(3 downto 0);
    signal alu_ctrl_i_type : std_logic_vector(3 downto 0);
    
    -- Sinais internos para controle da ALU vetorial
    signal valu_ctrl_r_type : std_logic_vector(3 downto 0);
    signal valu_ctrl_i_type : std_logic_vector(3 downto 0);

begin

    -- Decodificação do controle da ALU para instruções R-type
    P_ALU_CTRL_R : process(funct3_i, funct7_i)
    begin
        case funct3_i is
            when "000" =>  -- ADD ou SUB
                if funct7_i = "0100000" then
                    alu_ctrl_r_type <= ALU_SUB;
                else
                    alu_ctrl_r_type <= ALU_ADD;
                end if;
            when "111" =>  -- AND
                alu_ctrl_r_type <= ALU_AND;
            when "110" =>  -- OR
                alu_ctrl_r_type <= ALU_OR;
            when "100" =>  -- XOR
                alu_ctrl_r_type <= ALU_XOR;
            when "001" =>  -- SLL
                alu_ctrl_r_type <= ALU_SLL;
            when "101" =>  -- SRL (assume funct7 = 0000000)
                alu_ctrl_r_type <= ALU_SRL;
            when others =>
                alu_ctrl_r_type <= ALU_ADD;
        end case;
    end process P_ALU_CTRL_R;

    -- Decodificação do controle da ALU para instruções I-type
    P_ALU_CTRL_I : process(funct3_i)
    begin
        case funct3_i is
            when "000" =>  -- ADDI
                alu_ctrl_i_type <= ALU_ADD;
            when "111" =>  -- ANDI
                alu_ctrl_i_type <= ALU_AND;
            when "110" =>  -- ORI
                alu_ctrl_i_type <= ALU_OR;
            when "100" =>  -- XORI
                alu_ctrl_i_type <= ALU_XOR;
            when "001" =>  -- SLLI
                alu_ctrl_i_type <= ALU_SLL;
            when "101" =>  -- SRLI
                alu_ctrl_i_type <= ALU_SRL;
            when others =>
                alu_ctrl_i_type <= ALU_ADD;
        end case;
    end process P_ALU_CTRL_I;
    
    -- Decodificação do controle da ALU vetorial para instruções R-type vetoriais
    P_VALU_CTRL_R : process(funct3_i, funct7_i)
    begin
        case funct3_i is
            when "000" =>  -- VADD ou VSUB
                if funct7_i = "0100000" then
                    valu_ctrl_r_type <= ALU_SUB;
                else
                    valu_ctrl_r_type <= ALU_ADD;
                end if;
            when "001" =>  -- VSLL
                valu_ctrl_r_type <= ALU_SLL;
            when "101" =>  -- VSRL
                valu_ctrl_r_type <= ALU_SRL;
            when others =>
                valu_ctrl_r_type <= ALU_ADD;
        end case;
    end process P_VALU_CTRL_R;
    
    -- Decodificação do controle da ALU vetorial para instruções I-type vetoriais
    P_VALU_CTRL_I : process(funct3_i)
    begin
        case funct3_i is
            when "010" =>  -- VADDI
                valu_ctrl_i_type <= ALU_ADD;
            when "011" =>  -- VSLLI
                valu_ctrl_i_type <= ALU_SLL;
            when "111" =>  -- VSRLI
                valu_ctrl_i_type <= ALU_SRL;
            when others =>
                valu_ctrl_i_type <= ALU_ADD;
        end case;
    end process P_VALU_CTRL_I;

    -- Processo principal de geração de sinais de controle
    P_CONTROL : process(opcode_i, funct3_i, alu_ctrl_r_type, alu_ctrl_i_type, valu_ctrl_r_type, valu_ctrl_i_type)
    begin
        -- Valores padrão (NOP)
        reg_write_o  <= '0';
        mem_to_reg_o <= '0';
        mem_write_o  <= '0';
        mem_read_o   <= '0';
        alu_src_o    <= '0';
        alu_ctrl_o   <= ALU_ADD;
        branch_o     <= '0';
        jump_o       <= '0';
        auipc_o      <= '0';
        jalr_o       <= '0';
        lui_o        <= '0';
        -- Valores padrão para sinais vetoriais
        is_vector_o  <= '0';
        vreg_write_o <= '0';
        valu_ctrl_o  <= ALU_ADD;
        valu_src_o   <= '0';
        vauipc_o     <= '0';

        case opcode_i is
            when OP_R_TYPE =>
                -- add, sub, and, or, xor, sll, srl
                reg_write_o <= '1';
                alu_src_o   <= '0';  -- Usa rs2
                alu_ctrl_o  <= alu_ctrl_r_type;

            when OP_I_TYPE =>
                -- addi, andi, ori, xori, slli, srli
                reg_write_o <= '1';
                alu_src_o   <= '1';  -- Usa imediato
                alu_ctrl_o  <= alu_ctrl_i_type;

            when OP_LOAD =>
                -- lw
                reg_write_o  <= '1';
                mem_to_reg_o <= '1';
                mem_read_o   <= '1';
                alu_src_o    <= '1';  -- Usa imediato para cálculo de endereço
                alu_ctrl_o   <= ALU_ADD;

            when OP_STORE =>
                -- sw
                mem_write_o <= '1';
                alu_src_o   <= '1';  -- Usa imediato para cálculo de endereço
                alu_ctrl_o  <= ALU_ADD;

            when OP_BRANCH =>
                -- beq, bne
                branch_o   <= '1';
                alu_src_o  <= '0';   -- Compara rs1 com rs2
                alu_ctrl_o <= ALU_SUB;  -- Para comparação

            when OP_JAL =>
                -- jal
                reg_write_o <= '1';
                jump_o      <= '1';
                alu_ctrl_o  <= ALU_ADD;

            when OP_JALR =>
                -- jalr
                reg_write_o <= '1';
                jump_o      <= '1';
                jalr_o      <= '1';
                alu_src_o   <= '1';  -- Usa imediato
                alu_ctrl_o  <= ALU_ADD;

            when OP_LUI =>
                -- lui
                reg_write_o <= '1';
                lui_o       <= '1';
                alu_src_o   <= '1';
                alu_ctrl_o  <= ALU_PASS_B;  -- Passa o imediato diretamente

            when OP_AUIPC =>
                -- auipc
                reg_write_o <= '1';
                auipc_o     <= '1';
                alu_src_o   <= '1';
                alu_ctrl_o  <= ALU_ADD;

            -- Instruções vetoriais (custom-0)
            when OP_VECTOR =>
                is_vector_o  <= '1';
                vreg_write_o <= '1';
                -- Verificar se é R-type ou I-type baseado em funct3
                case funct3_i is
                    when "000" | "001" | "101" =>  -- VADD, VSUB, VSLL, VSRL (R-type)
                        valu_src_o   <= '0';  -- Usa vs2
                        valu_ctrl_o  <= valu_ctrl_r_type;
                    when others =>  -- VADDI, VSLLI, VSRLI (I-type)
                        valu_src_o   <= '1';  -- Usa imediato
                        valu_ctrl_o  <= valu_ctrl_i_type;
                end case;
            
            -- VAUIPC (custom-1)
            when OP_VAUIPC =>
                is_vector_o  <= '1';
                vreg_write_o <= '1';
                vauipc_o     <= '1';
                valu_src_o   <= '1';  -- Usa imediato
                valu_ctrl_o  <= ALU_ADD;

            when others =>
                -- Instrução inválida: NOP
                null;
                
        end case;
    end process P_CONTROL;

end architecture rtl;
