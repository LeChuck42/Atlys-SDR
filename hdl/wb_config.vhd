library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_config is
	generic (
		DATA_WIDTH         : integer := 32;
		ADDR_WIDTH         : integer := 3);
	port (
		CLK                : in  std_logic;
		RST                : in  std_logic;
		
		-- Whishbone Interface
		WB_ADR_I           : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        WB_DAT_I           : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        WB_SEL_I           : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
        WB_WE_I            : in  std_logic;
        WB_CYC_I           : in  std_logic;
        WB_STB_I           : in  std_logic;
        WB_CTI_I           : in  std_logic_vector(2 downto 0);
        WB_BTE_I           : in  std_logic_vector(1 downto 0);
        WB_DAT_O           : out std_logic_vector(DATA_WIDTH-1 downto 0);
        WB_ACK_O           : out std_logic;
        WB_ERR_O           : out std_logic;
        WB_RTY_O           : out std_logic;
        
        -- Data Interface
        DATA_OUTPUT        : out std_logic_vector((2**ADDR_WIDTH)*DATA_WIDTH-1 downto 0);
        DATA_INPUT         : in  std_logic_vector((2**ADDR_WIDTH)*DATA_WIDTH-1 downto 0);
        DATA_WE            : in  std_logic_vector((2**ADDR_WIDTH)-1 downto 0));
end entity wb_config;

architecture rtl of wb_config is
	signal data_reg: std_logic_vector((2**ADDR_WIDTH)*DATA_WIDTH-1 downto 0);
begin
	
	mem_proc: process (CLK, RST)
	begin
		if RST = '1' then
			data_reg <= (others => '0');
			WB_DAT_O <= (others => '0');
			WB_ACK_O <= '0';
		elsif rising_edge(CLK) then
			WB_ACK_O <= '0';
			
			for reg in 0 to 2**ADDR_WIDTH-1 loop
			
				if DATA_WE(reg) = '1' then
					data_reg(reg*DATA_WIDTH+DATA_WIDTH-1 downto reg*DATA_WIDTH) <= DATA_INPUT(reg*DATA_WIDTH+DATA_WIDTH-1 downto reg*DATA_WIDTH);
				end if;
				
				if unsigned(WB_ADR_I) = reg then
					WB_DAT_O <= data_reg(reg*DATA_WIDTH+DATA_WIDTH-1 downto reg*DATA_WIDTH);
					if WB_CYC_I = '1' and WB_STB_I = '1' then
						if WB_WE_I = '1' then
							data_reg(reg*DATA_WIDTH + DATA_WIDTH-1 downto reg*DATA_WIDTH) <= WB_DAT_I;
						end if;
						WB_ACK_O <= '1';
					end if;
				end if;
			end loop;
		end if;
	end process;
	
	WB_ERR_O <= '0';
	WB_RTY_O <= '0';
	DATA_OUTPUT <= data_reg;
	
end architecture rtl;
