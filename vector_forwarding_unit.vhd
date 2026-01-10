-- =============================================================================
-- Vector Forwarding Unit para CPU RISC-V com extensão vetorial
-- Detecta dependências RAW e habilita forwarding para registradores vetoriais
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity vector_forwarding_unit is
    port (
        -- Endereços dos operandos no estágio EX
        vs1_ex_i         : in  std_logic_vector(4 downto 0);
        vs2_ex_i         : in  std_logic_vector(4 downto 0);
        is_vector_ex_i   : in  std_logic;  -- Instrução vetorial no EX
        
        -- Informações do estágio MEM
        vrd_mem_i        : in  std_logic_vector(4 downto 0);
        vreg_write_mem_i : in  std_logic;
        
        -- Informações do estágio WB
        vrd_wb_i         : in  std_logic_vector(4 downto 0);
        vreg_write_wb_i  : in  std_logic;
        
        -- Sinais de controle de forwarding
        -- 00: sem forwarding (usa valor do reg file)
        -- 01: forward do estágio MEM
        -- 10: forward do estágio WB
        vforward_a_o     : out std_logic_vector(1 downto 0);
        vforward_b_o     : out std_logic_vector(1 downto 0)
    );
end entity vector_forwarding_unit;

architecture rtl of vector_forwarding_unit is
begin

    -- Forwarding para vs1 (operando A)
    P_VFORWARD_A : process(vs1_ex_i, vrd_mem_i, vreg_write_mem_i, 
                           vrd_wb_i, vreg_write_wb_i, is_vector_ex_i)
    begin
        if is_vector_ex_i = '1' then
            if vreg_write_mem_i = '1' and vrd_mem_i = vs1_ex_i then
                -- Forward do estágio MEM (prioridade maior)
                vforward_a_o <= "01";
            elsif vreg_write_wb_i = '1' and vrd_wb_i = vs1_ex_i then
                -- Forward do estágio WB
                vforward_a_o <= "10";
            else
                -- Sem forwarding
                vforward_a_o <= "00";
            end if;
        else
            vforward_a_o <= "00";
        end if;
    end process P_VFORWARD_A;

    -- Forwarding para vs2 (operando B)
    P_VFORWARD_B : process(vs2_ex_i, vrd_mem_i, vreg_write_mem_i, 
                           vrd_wb_i, vreg_write_wb_i, is_vector_ex_i)
    begin
        if is_vector_ex_i = '1' then
            if vreg_write_mem_i = '1' and vrd_mem_i = vs2_ex_i then
                -- Forward do estágio MEM (prioridade maior)
                vforward_b_o <= "01";
            elsif vreg_write_wb_i = '1' and vrd_wb_i = vs2_ex_i then
                -- Forward do estágio WB
                vforward_b_o <= "10";
            else
                -- Sem forwarding
                vforward_b_o <= "00";
            end if;
        else
            vforward_b_o <= "00";
        end if;
    end process P_VFORWARD_B;

end architecture rtl;
