-- =============================================================================
-- Vector Pipeline Registers para CPU RISC-V com extensão vetorial
-- Contém registradores de pipeline para dados vetoriais (128 bits)
-- Complementa os pipeline_regs.vhd escalares
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- =============================================================================
-- ID/EX Vector Pipeline Register
-- Armazena dados vetoriais e sinais de controle vetoriais do ID para EX
-- =============================================================================
entity id_ex_vreg is
    port (
        clk_i           : in  std_logic;
        reset_i         : in  std_logic;
        stall_i         : in  std_logic;
        flush_i         : in  std_logic;
        load_enable_i   : in  std_logic;
        -- Entradas de dados vetoriais do estágio ID
        vs1_data_i      : in  std_logic_vector(127 downto 0);
        vs2_data_i      : in  std_logic_vector(127 downto 0);
        -- Sinais de controle vetoriais
        is_vector_i     : in  std_logic;
        vreg_write_i    : in  std_logic;
        valu_ctrl_i     : in  std_logic_vector(3 downto 0);
        valu_src_i      : in  std_logic;
        vauipc_i        : in  std_logic;
        -- Saídas para estágio EX
        vs1_data_o      : out std_logic_vector(127 downto 0);
        vs2_data_o      : out std_logic_vector(127 downto 0);
        is_vector_o     : out std_logic;
        vreg_write_o    : out std_logic;
        valu_ctrl_o     : out std_logic_vector(3 downto 0);
        valu_src_o      : out std_logic;
        vauipc_o        : out std_logic
    );
end entity id_ex_vreg;

architecture rtl of id_ex_vreg is
    signal vs1_data_reg    : std_logic_vector(127 downto 0) := (others => '0');
    signal vs2_data_reg    : std_logic_vector(127 downto 0) := (others => '0');
    signal is_vector_reg   : std_logic := '0';
    signal vreg_write_reg  : std_logic := '0';
    signal valu_ctrl_reg   : std_logic_vector(3 downto 0) := (others => '0');
    signal valu_src_reg    : std_logic := '0';
    signal vauipc_reg      : std_logic := '0';
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            vs1_data_reg   <= (others => '0');
            vs2_data_reg   <= (others => '0');
            is_vector_reg  <= '0';
            vreg_write_reg <= '0';
            valu_ctrl_reg  <= (others => '0');
            valu_src_reg   <= '0';
            vauipc_reg     <= '0';
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then
                if flush_i = '1' then
                    vs1_data_reg   <= (others => '0');
                    vs2_data_reg   <= (others => '0');
                    is_vector_reg  <= '0';
                    vreg_write_reg <= '0';
                    valu_ctrl_reg  <= (others => '0');
                    valu_src_reg   <= '0';
                    vauipc_reg     <= '0';
                elsif stall_i = '0' then
                    vs1_data_reg   <= vs1_data_i;
                    vs2_data_reg   <= vs2_data_i;
                    is_vector_reg  <= is_vector_i;
                    vreg_write_reg <= vreg_write_i;
                    valu_ctrl_reg  <= valu_ctrl_i;
                    valu_src_reg   <= valu_src_i;
                    vauipc_reg     <= vauipc_i;
                end if;
            end if;
        end if;
    end process;

    vs1_data_o   <= vs1_data_reg;
    vs2_data_o   <= vs2_data_reg;
    is_vector_o  <= is_vector_reg;
    vreg_write_o <= vreg_write_reg;
    valu_ctrl_o  <= valu_ctrl_reg;
    valu_src_o   <= valu_src_reg;
    vauipc_o     <= vauipc_reg;
end architecture rtl;

-- =============================================================================
-- EX/MEM Vector Pipeline Register
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ex_mem_vreg is
    port (
        clk_i           : in  std_logic;
        reset_i         : in  std_logic;
        flush_i         : in  std_logic;
        load_enable_i   : in  std_logic;
        -- Entradas do estágio EX
        valu_result_i   : in  std_logic_vector(127 downto 0);
        vrd_addr_i      : in  std_logic_vector(4 downto 0);
        -- Sinais de controle vetoriais
        is_vector_i     : in  std_logic;
        vreg_write_i    : in  std_logic;
        -- Saídas para estágio MEM
        valu_result_o   : out std_logic_vector(127 downto 0);
        vrd_addr_o      : out std_logic_vector(4 downto 0);
        is_vector_o     : out std_logic;
        vreg_write_o    : out std_logic
    );
end entity ex_mem_vreg;

architecture rtl of ex_mem_vreg is
    signal valu_result_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal vrd_addr_reg    : std_logic_vector(4 downto 0) := (others => '0');
    signal is_vector_reg   : std_logic := '0';
    signal vreg_write_reg  : std_logic := '0';
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            valu_result_reg <= (others => '0');
            vrd_addr_reg    <= (others => '0');
            is_vector_reg   <= '0';
            vreg_write_reg  <= '0';
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then
                if flush_i = '1' then
                    valu_result_reg <= (others => '0');
                    vrd_addr_reg    <= (others => '0');
                    is_vector_reg   <= '0';
                    vreg_write_reg  <= '0';
                else
                    valu_result_reg <= valu_result_i;
                    vrd_addr_reg    <= vrd_addr_i;
                    is_vector_reg   <= is_vector_i;
                    vreg_write_reg  <= vreg_write_i;
                end if;
            end if;
        end if;
    end process;

    valu_result_o <= valu_result_reg;
    vrd_addr_o    <= vrd_addr_reg;
    is_vector_o   <= is_vector_reg;
    vreg_write_o  <= vreg_write_reg;
end architecture rtl;

-- =============================================================================
-- MEM/WB Vector Pipeline Register
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity mem_wb_vreg is
    port (
        clk_i           : in  std_logic;
        reset_i         : in  std_logic;
        load_enable_i   : in  std_logic;
        -- Entradas do estágio MEM
        valu_result_i   : in  std_logic_vector(127 downto 0);
        vrd_addr_i      : in  std_logic_vector(4 downto 0);
        -- Sinais de controle vetoriais
        vreg_write_i    : in  std_logic;
        -- Saídas para estágio WB
        valu_result_o   : out std_logic_vector(127 downto 0);
        vrd_addr_o      : out std_logic_vector(4 downto 0);
        vreg_write_o    : out std_logic
    );
end entity mem_wb_vreg;

architecture rtl of mem_wb_vreg is
    signal valu_result_reg : std_logic_vector(127 downto 0) := (others => '0');
    signal vrd_addr_reg    : std_logic_vector(4 downto 0) := (others => '0');
    signal vreg_write_reg  : std_logic := '0';
begin
    process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            valu_result_reg <= (others => '0');
            vrd_addr_reg    <= (others => '0');
            vreg_write_reg  <= '0';
        elsif rising_edge(clk_i) then
            if load_enable_i = '0' then
                valu_result_reg <= valu_result_i;
                vrd_addr_reg    <= vrd_addr_i;
                vreg_write_reg  <= vreg_write_i;
            end if;
        end if;
    end process;

    valu_result_o <= valu_result_reg;
    vrd_addr_o    <= vrd_addr_reg;
    vreg_write_o  <= vreg_write_reg;
end architecture rtl;
