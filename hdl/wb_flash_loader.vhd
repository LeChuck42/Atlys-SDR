library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_flash_loader is
	generic (
		DUMMY_CYCLES:    natural := 8;
		READ_OFFSET:     std_logic_vector(23 downto 0) := x"800000";
		WRITE_OFFSET:    std_logic_vector(31 downto 0) := x"00000000";
		SIZE:            natural := 20;
		SIMULATION:      string := "FALSE" ); -- copy 1 MiB
	port (
		CLK      : in std_logic;
		RESET    : in std_logic;
		
		SPI_CLK  : out std_logic;
		SPI_CSN  : out std_logic;
		SPI_IO   : inout std_logic_vector(3 downto 0);
		
		DONE     : out std_logic;
		
		-- Wishbone master
		WB_ADR_O : out std_logic_vector(31 downto 0);
		WB_DAT_I : in  std_logic_vector(31 downto 0);
		WB_DAT_O : out std_logic_vector(31 downto 0);
		WB_WE_O  : out std_logic;
		WB_SEL_O : out std_logic_vector(3 downto 0);
		WB_STB_O : out std_logic;
		WB_ACK_I : in  std_logic;
		WB_CYC_O : out std_logic;
		WB_CTI_O : out std_logic_vector(2 downto 0);
		WB_BTE_O : out std_logic_vector(1 downto 0);
		WB_RTY_I : in  std_logic;
		WB_ERR_I : in  std_logic);
end entity wb_flash_loader;

architecture rtl of wb_flash_loader is
	type flash_state_t is (COMMAND, DUMMY, READ_DATA, WRITING, FINISHED);
	signal flash_state:     flash_state_t;
	signal word_cnt:        unsigned(SIZE-3 downto 0);
	signal trx_cnt:         unsigned(4 downto 0);
	signal cmd_buf:         std_logic_vector(31 downto 0);
	signal data_buf:        std_logic_vector(27 downto 0);
	signal clk_div:         std_logic;
	signal wb_wr_cyc:       std_logic;
begin
	WB_WE_O  <= '1';
	WB_SEL_O <= "1111";
	WB_CYC_O <= wb_wr_cyc;
	WB_STB_O <= wb_wr_cyc;
	WB_CTI_O <= "000";
	WB_BTE_O <= "00";
	WB_ADR_O <= std_logic_vector(unsigned(WRITE_OFFSET) + unsigned(std_logic_vector(word_cnt) & "00"));
	
	SPI_IO(0) <= cmd_buf(cmd_buf'LEFT) when flash_state = COMMAND else 'Z';
	SPI_IO(1) <= 'Z';
	SPI_IO(2) <= 'Z';
	SPI_IO(3) <= 'Z';
	
	SPI_CSN <= '0' when flash_state /= FINISHED and RESET = '0' else '1';
	
	SPI_CLK <= clk_div when flash_state /= FINISHED and flash_state /= WRITING and RESET = '0' else '0';
	
	DONE <= '1' when flash_state = FINISHED else '0';
	
	flash_fsm: process(CLK, RESET)
	begin
		if RESET = '1' then
			if SIMULATION = "FALSE" then
				flash_state <= COMMAND;
			else
				flash_state <= FINISHED;
			end if;
			word_cnt <= to_unsigned(0, word_cnt'LENGTH);
			trx_cnt <= to_unsigned(0, trx_cnt'LENGTH);
			cmd_buf  <= x"6B" & READ_OFFSET; -- QOFR + 3 ADDR BYTES
			data_buf <= (others => '0');
			clk_div <= '0';
			wb_wr_cyc <= '0';
		elsif rising_edge(CLK) then
			
			if wb_wr_cyc = '1' and WB_ACK_I = '1' then
				wb_wr_cyc <= '0';
			end if;
			
			clk_div <= not clk_div;
			
			if clk_div = '1' then
				case (flash_state) is
					
					when COMMAND =>
						cmd_buf <= cmd_buf(30 downto 0) & cmd_buf(31);
						if trx_cnt = to_unsigned(31, trx_cnt'LENGTH) then
							flash_state <= DUMMY;
							trx_cnt <= to_unsigned(0, trx_cnt'LENGTH);
						else
							trx_cnt <= trx_cnt + 1;
						end if;
						
					when DUMMY =>
						-- bus turnaround
						if trx_cnt = to_unsigned(DUMMY_CYCLES-1, trx_cnt'LENGTH) then
							flash_state <= READ_DATA;
							trx_cnt <= to_unsigned(0, trx_cnt'LENGTH);
						else
							trx_cnt <= trx_cnt + 1;
						end if;
						
					when READ_DATA =>
						if trx_cnt = to_unsigned(7, trx_cnt'LENGTH) then
							trx_cnt <= to_unsigned(0, trx_cnt'LENGTH);
							WB_DAT_O <= data_buf & SPI_IO;
							wb_wr_cyc <= '1';
							flash_state <= WRITING;
						else -- if trx_cnt
							data_buf <= data_buf(23 downto 0) & SPI_IO;
							trx_cnt <= trx_cnt + 1;
						end if;
						
					when WRITING =>
						if wb_wr_cyc = '0' then
							word_cnt <= word_cnt + 1;
							if word_cnt = (word_cnt'RANGE => '1') then
								-- this was the last transfer
								flash_state <= FINISHED;
							else
								-- continue reading
								flash_state <= READ_DATA;
							end if;
						end if;
					
					when FINISHED =>
						flash_state <= FINISHED;
						
				end case;
			end if;
		end if;
	end process;
	
end architecture rtl;