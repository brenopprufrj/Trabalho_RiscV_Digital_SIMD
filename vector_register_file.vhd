-- =============================================================================
-- Vector Register File para CPU RISC-V com extensão vetorial
-- 32 registradores vetoriais de 128 bits cada (4 x 32 bits por registrador)
-- 2 portas de leitura, 1 porta de escrita
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vector_register_file is
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        we_i         : in  std_logic;                       -- Write Enable
        -- Endereços (5 bits para 32 registradores)
        vs1_addr_i   : in  std_logic_vector(4 downto 0);    -- Endereço fonte 1
        vs2_addr_i   : in  std_logic_vector(4 downto 0);    -- Endereço fonte 2
        vd_addr_i    : in  std_logic_vector(4 downto 0);    -- Endereço destino
        -- Dados (128 bits = 4 elementos de 32 bits)
        vd_data_i    : in  std_logic_vector(127 downto 0);  -- Dados para escrita
        vs1_data_o   : out std_logic_vector(127 downto 0);  -- Dados lidos de vs1
        vs2_data_o   : out std_logic_vector(127 downto 0);  -- Dados lidos de vs2
        -- Debug outputs (para aferir estados internos)
        vreg_debug_o : out std_logic_vector(127 downto 0);  -- Registrador selecionado
        vreg_sel_i   : in  std_logic_vector(4 downto 0)     -- Seleção para debug
    );
end entity vector_register_file;

architecture rtl of vector_register_file is

    -- Tipo para o banco de registradores vetoriais
    type vreg_array_t is array (0 to 31) of std_logic_vector(127 downto 0);
    
    -- Banco de registradores vetoriais
    signal vregisters : vreg_array_t := (others => (others => '0'));

begin

    -- Processo de escrita (síncrono)
    P_WRITE : process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            -- Reset: todos os registradores vetoriais para zero
            vregisters <= (others => (others => '0'));
        elsif rising_edge(clk_i) then
            if we_i = '1' then
                -- Escreve no registrador destino (v0 pode ser escrito, diferente de x0)
                vregisters(to_integer(unsigned(vd_addr_i))) <= vd_data_i;
            end if;
        end if;
    end process P_WRITE;

    -- Leitura assíncrona de vs1 COM INTERNAL FORWARDING
    -- Se estamos escrevendo no mesmo registrador que estamos lendo, retorna o dado sendo escrito
    vs1_data_o <= vd_data_i when (we_i = '1' and vs1_addr_i = vd_addr_i)
                  else vregisters(to_integer(unsigned(vs1_addr_i)));

    -- Leitura assíncrona de vs2 COM INTERNAL FORWARDING
    vs2_data_o <= vd_data_i when (we_i = '1' and vs2_addr_i = vd_addr_i)
                  else vregisters(to_integer(unsigned(vs2_addr_i)));

    -- Saída de debug: permite ler qualquer registrador vetorial para depuração
    vreg_debug_o <= vregisters(to_integer(unsigned(vreg_sel_i)));

end architecture rtl;

