-- =============================================================================
-- Vector ALU para CPU RISC-V com extensão vetorial
-- 4 lanes paralelas (SIMD) operando em elementos de 32 bits
-- Suporta: VADD, VSUB, VSLL, VSRL
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vector_alu is
    port (
        va_i        : in  std_logic_vector(127 downto 0);  -- Operando vetorial A
        vb_i        : in  std_logic_vector(127 downto 0);  -- Operando vetorial B
        valu_ctrl_i : in  std_logic_vector(3 downto 0);    -- Controle da operação
        vresult_o   : out std_logic_vector(127 downto 0);  -- Resultado vetorial
        -- Debug outputs para cada lane (para aferir estados internos)
        vcarry_o    : out std_logic_vector(3 downto 0);    -- Carry de cada lane
        voverflow_o : out std_logic_vector(3 downto 0)     -- Overflow de cada lane
    );
end entity vector_alu;

architecture rtl of vector_alu is

    -- Constantes para operações da ALU vetorial
    constant VALU_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant VALU_SUB  : std_logic_vector(3 downto 0) := "0001";
    constant VALU_SLL  : std_logic_vector(3 downto 0) := "0101";
    constant VALU_SRL  : std_logic_vector(3 downto 0) := "0110";

    -- Elementos individuais de cada lane (32 bits cada)
    signal a0, a1, a2, a3 : std_logic_vector(31 downto 0);
    signal b0, b1, b2, b3 : std_logic_vector(31 downto 0);
    signal r0, r1, r2, r3 : std_logic_vector(31 downto 0);
    
    -- Resultados de soma/subtração com carry (33 bits)
    signal add0, add1, add2, add3 : std_logic_vector(32 downto 0);
    signal sub0, sub1, sub2, sub3 : std_logic_vector(32 downto 0);
    
    -- Shift amounts para cada lane (5 bits cada)
    signal shamt0, shamt1, shamt2, shamt3 : natural range 0 to 31;
    
    -- Sinais internos de carry e overflow
    signal carry_internal    : std_logic_vector(3 downto 0);
    signal overflow_internal : std_logic_vector(3 downto 0);

begin

    -- Extração dos 4 elementos de 32 bits de cada vetor
    a0 <= va_i(31 downto 0);
    a1 <= va_i(63 downto 32);
    a2 <= va_i(95 downto 64);
    a3 <= va_i(127 downto 96);
    
    b0 <= vb_i(31 downto 0);
    b1 <= vb_i(63 downto 32);
    b2 <= vb_i(95 downto 64);
    b3 <= vb_i(127 downto 96);
    
    -- Shift amounts (5 bits menos significativos de cada elemento B)
    shamt0 <= to_integer(unsigned(b0(4 downto 0)));
    shamt1 <= to_integer(unsigned(b1(4 downto 0)));
    shamt2 <= to_integer(unsigned(b2(4 downto 0)));
    shamt3 <= to_integer(unsigned(b3(4 downto 0)));
    
    -- Cálculos de soma com carry para cada lane
    add0 <= std_logic_vector(unsigned('0' & a0) + unsigned('0' & b0));
    add1 <= std_logic_vector(unsigned('0' & a1) + unsigned('0' & b1));
    add2 <= std_logic_vector(unsigned('0' & a2) + unsigned('0' & b2));
    add3 <= std_logic_vector(unsigned('0' & a3) + unsigned('0' & b3));
    
    -- Cálculos de subtração com borrow para cada lane
    sub0 <= std_logic_vector(unsigned('0' & a0) - unsigned('0' & b0));
    sub1 <= std_logic_vector(unsigned('0' & a1) - unsigned('0' & b1));
    sub2 <= std_logic_vector(unsigned('0' & a2) - unsigned('0' & b2));
    sub3 <= std_logic_vector(unsigned('0' & a3) - unsigned('0' & b3));

    -- Processo principal da ALU vetorial - Lane 0
    P_LANE0 : process(a0, b0, valu_ctrl_i, add0, sub0, shamt0)
    begin
        case valu_ctrl_i is
            when VALU_ADD =>
                r0 <= add0(31 downto 0);
            when VALU_SUB =>
                r0 <= sub0(31 downto 0);
            when VALU_SLL =>
                r0 <= std_logic_vector(shift_left(unsigned(a0), shamt0));
            when VALU_SRL =>
                r0 <= std_logic_vector(shift_right(unsigned(a0), shamt0));
            when others =>
                r0 <= (others => '0');
        end case;
    end process P_LANE0;

    -- Processo principal da ALU vetorial - Lane 1
    P_LANE1 : process(a1, b1, valu_ctrl_i, add1, sub1, shamt1)
    begin
        case valu_ctrl_i is
            when VALU_ADD =>
                r1 <= add1(31 downto 0);
            when VALU_SUB =>
                r1 <= sub1(31 downto 0);
            when VALU_SLL =>
                r1 <= std_logic_vector(shift_left(unsigned(a1), shamt1));
            when VALU_SRL =>
                r1 <= std_logic_vector(shift_right(unsigned(a1), shamt1));
            when others =>
                r1 <= (others => '0');
        end case;
    end process P_LANE1;

    -- Processo principal da ALU vetorial - Lane 2
    P_LANE2 : process(a2, b2, valu_ctrl_i, add2, sub2, shamt2)
    begin
        case valu_ctrl_i is
            when VALU_ADD =>
                r2 <= add2(31 downto 0);
            when VALU_SUB =>
                r2 <= sub2(31 downto 0);
            when VALU_SLL =>
                r2 <= std_logic_vector(shift_left(unsigned(a2), shamt2));
            when VALU_SRL =>
                r2 <= std_logic_vector(shift_right(unsigned(a2), shamt2));
            when others =>
                r2 <= (others => '0');
        end case;
    end process P_LANE2;

    -- Processo principal da ALU vetorial - Lane 3
    P_LANE3 : process(a3, b3, valu_ctrl_i, add3, sub3, shamt3)
    begin
        case valu_ctrl_i is
            when VALU_ADD =>
                r3 <= add3(31 downto 0);
            when VALU_SUB =>
                r3 <= sub3(31 downto 0);
            when VALU_SLL =>
                r3 <= std_logic_vector(shift_left(unsigned(a3), shamt3));
            when VALU_SRL =>
                r3 <= std_logic_vector(shift_right(unsigned(a3), shamt3));
            when others =>
                r3 <= (others => '0');
        end case;
    end process P_LANE3;

    -- Concatenação do resultado vetorial
    vresult_o <= r3 & r2 & r1 & r0;
    
    -- Debug: carry de cada lane (da soma)
    carry_internal(0) <= add0(32) when valu_ctrl_i = VALU_ADD else '0';
    carry_internal(1) <= add1(32) when valu_ctrl_i = VALU_ADD else '0';
    carry_internal(2) <= add2(32) when valu_ctrl_i = VALU_ADD else '0';
    carry_internal(3) <= add3(32) when valu_ctrl_i = VALU_ADD else '0';
    vcarry_o <= carry_internal;
    
    -- Debug: overflow de cada lane (verifica mudança de sinal na soma)
    overflow_internal(0) <= (not a0(31) and not b0(31) and r0(31)) or
                            (a0(31) and b0(31) and not r0(31))
                            when valu_ctrl_i = VALU_ADD else '0';
    overflow_internal(1) <= (not a1(31) and not b1(31) and r1(31)) or
                            (a1(31) and b1(31) and not r1(31))
                            when valu_ctrl_i = VALU_ADD else '0';
    overflow_internal(2) <= (not a2(31) and not b2(31) and r2(31)) or
                            (a2(31) and b2(31) and not r2(31))
                            when valu_ctrl_i = VALU_ADD else '0';
    overflow_internal(3) <= (not a3(31) and not b3(31) and r3(31)) or
                            (a3(31) and b3(31) and not r3(31))
                            when valu_ctrl_i = VALU_ADD else '0';
    voverflow_o <= overflow_internal;

end architecture rtl;
