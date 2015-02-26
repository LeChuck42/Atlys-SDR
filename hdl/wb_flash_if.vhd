library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_flash_if is
	generic (
		FLASH_ADR_WIDTH: natural := 18;
		DUMMY_CYCLES:    natural := 4);
	port (
		CLK      : in std_logic;
		RESET    : in std_logic;
		
		SPI_CSN  : out std_logic;
		SPI_CLK  : out std_logic;
		SPI_IO   : inout std_logic_vector(3 downto 0);
		
		-- Wishbone slave
		WB_RST_I : in std_logic;
		WB_CLK_I : in std_logic;
		WB_ADR_I : in std_logic_vector(31 downto 0);
		WB_DAT_I : in std_logic_vector(31 downto 0);
		WB_DAT_O : out std_logic_vector(31 downto 0);
		WB_WE_I  : in std_logic;
		WB_SEL_I : in std_logic_vector(3 downto 0);
		WB_STB_I : in std_logic;
		WB_ACK_O : out std_logic;
		WB_CYC_I : in std_logic;
		WB_CTI_I : in std_logic_vector(2 downto 0);
		WB_BTE_I : in std_logic_vector(1 downto 0);
		WB_RTY_O : out std_logic;
		WB_ERR_O : out std_logic);
end entity wb_flash_if;

architecture rtl of wb_flash_if is
	type flash_state_t is (IDLE, COMMAND, ADDRESS, MODE, DUMMY, READ_DATA, RESTART);
	signal flash_state:     flash_state_t;
	signal addr_buf:        std_logic_vector(23 downto 0);
	signal burst_start:     std_logic_vector(23 downto 0);
	signal trx_cnt:         unsigned (2 downto 0);
	signal burst_cnt:       unsigned (3 downto 0);
	signal flash_command:   std_logic_vector(7 downto 0);
	signal flash_mode:      std_logic_vector(7 downto 0);
	signal data_buf:        std_logic_vector(27 downto 0);
	signal burst_wrap:      std_logic;
	signal addr_clipped:    std_logic_vector(23 downto 0);
	signal start_transfer:  std_logic;
	signal ack_int:         std_logic_vector(1 downto 0);
	signal pause:           std_logic;
begin

	WB_RTY_O <= '0';
	WB_ERR_O  <= '1' when WB_WE_I = '1' and WB_CYC_I = '1' and WB_STB_I = '1' else '0'; -- read only
	
	SPI_IO(0) <= flash_command(7) when flash_state = COMMAND else
		addr_buf(20) when flash_state = ADDRESS else
		flash_mode(4) when flash_state = MODE else 'Z';
	
	SPI_IO(1) <= addr_buf(21) when flash_state = ADDRESS else
		flash_mode(5) when flash_state = MODE else 'Z';
		
	SPI_IO(2) <= addr_buf(22) when flash_state = ADDRESS else
		flash_mode(6) when flash_state = MODE else 'Z';
		
	SPI_IO(3) <= addr_buf(23) when flash_state = ADDRESS else
		flash_mode(7) when flash_state = MODE else 'Z';
		
	SPI_CSN <= '0'     when (flash_state /= IDLE and flash_state /= RESTART) else '1';
	SPI_CLK <= not CLK when (flash_state /= IDLE and flash_state /= RESTART and pause = '0') else '0';
	
	burst_wrap_proc: process(burst_start, WB_BTE_I, burst_cnt)
	variable addr_burst:    unsigned(3 downto 0);
	begin
		addr_burst := unsigned(burst_start(5 downto 2)) + burst_cnt;
		case (WB_BTE_I) is
			when "00" => -- linear burst
				burst_wrap <= '0';
				addr_clipped <= (others => '-');
			when "01" => -- 4-beat wrap burst
				if addr_burst(1 downto 0) = "11" then
					burst_wrap <= '1';
				else
					burst_wrap <= '0';
				end if;
				addr_clipped <= burst_start(23 downto 4) & "0000";
			when "10" => -- 8-beat wrap burst
				if addr_burst(2 downto 0) = "111" then
					burst_wrap <= '1';
				else
					burst_wrap <= '0';
				end if;
				addr_clipped <= burst_start(23 downto 5) & "00000";
			when "11" => -- 16-beat wrap burst
				if addr_burst(3 downto 0) = "1111" then
					burst_wrap <= '1';
				else
					burst_wrap <= '0';
				end if;
				addr_clipped <= burst_start(23 downto 6) & "000000";
			when others =>
				burst_wrap <= '-';
				addr_clipped <= (others => '-');
		end case;
	end process;
	
	wb_buf: process(WB_CLK_I, WB_RST_I)
	begin
		if WB_RST_I = '1' then
			start_transfer <= '0';
		elsif rising_edge(WB_CLK_I) then
			-- read WB control signals synchronous to wb_clk to relax timing
			if WB_WE_I = '0' and WB_CYC_I = '1' and WB_STB_I = '1' and ack_int(1) = '0'  then
				start_transfer <= '1';
			else
				start_transfer <= '0';
			end if;
		end if;
	end process;
	
	flash_fsm: process(CLK, RESET)
	begin
		if RESET = '1' then
			flash_state <= IDLE;
			trx_cnt <= (others => '0');
			burst_cnt <= (others => '0');
			burst_start <= (others => '0');
			ack_int <= (others => '0');
			flash_command <= x"EB"; -- Quad I/O Read
			flash_mode <= x"A0";
			data_buf <= (others => '0');
			WB_DAT_O <= (others => '0');
			pause <= '0';
			
		elsif rising_edge(CLK) then
			ack_int <= ack_int(0) & '0';
			pause <= '0';
			case (flash_state) is
				when IDLE =>
					burst_cnt <= (others => '0');
					burst_start <= (others => '0');
					flash_command <= x"EB"; -- reset value
					trx_cnt <= to_unsigned(7,3);
					if start_transfer = '1' then
						flash_state <= COMMAND;
					end if;
				when COMMAND =>
					flash_command <= flash_command(6 downto 0) & flash_command(7); -- rol
					if trx_cnt = "000" then
						-- delayed read of address to relax timings
						addr_buf <= (others => '0');
						addr_buf(FLASH_ADR_WIDTH downto 2) <= WB_ADR_I(FLASH_ADR_WIDTH downto 2);
						flash_state <= ADDRESS;
						trx_cnt <= to_unsigned(5,3);
					else
						trx_cnt <= trx_cnt - 1;
					end if;
				when ADDRESS =>
					addr_buf <= addr_buf(19 downto 0) & addr_buf(23 downto 20); -- 4 byte rol
					if trx_cnt = "000" then
						flash_state <= MODE;
					else
						trx_cnt <= trx_cnt - 1;
					end if;
				when MODE =>
					flash_state <= DUMMY;
					trx_cnt <= to_unsigned(DUMMY_CYCLES, 3); -- 1 mode cycle + N dummy cycles
				when DUMMY =>
					-- bus turnaround
					trx_cnt <= trx_cnt - 1;
					if trx_cnt = "000" then
						flash_state <= READ_DATA;
						--trx_cnt <= to_unsigned(7,3);
					end if;
				when READ_DATA =>
					if trx_cnt = "000" then
						if pause = '0' then
							WB_DAT_O <= data_buf & SPI_IO;
						end if;
						if start_transfer = '1' and ack_int(1) /= '1' then
							if addr_buf(FLASH_ADR_WIDTH downto 2) = WB_ADR_I(FLASH_ADR_WIDTH downto 2) then
								data_buf <= data_buf(23 downto 0) & SPI_IO;
								trx_cnt <= trx_cnt - 1;
								--ack needs two cycles to be recognized by 50MHz domain
								ack_int <= "11";
								addr_buf <= std_logic_vector(unsigned(addr_buf) + 4);
								pause <= pause;
								if WB_CTI_I = "010" then
									-- incrementing address burst cycle
									burst_cnt <= burst_cnt + 1;
									if burst_cnt = 0 then
										burst_start(FLASH_ADR_WIDTH downto 2) <= WB_ADR_I(FLASH_ADR_WIDTH downto 2);
									elsif burst_wrap = '1' then
										addr_buf <= addr_clipped;
										flash_state <= RESTART;
										trx_cnt <= to_unsigned(0,3);
									end if;
								elsif WB_CTI_I = "111" then
									burst_cnt <= (others => '0');
								end if;
							else
								-- we (pre)read the wrong address -> restart with correct one
								addr_buf <= (others => '0');
								addr_buf(FLASH_ADR_WIDTH downto 2) <= WB_ADR_I(FLASH_ADR_WIDTH downto 2);
								flash_state <= RESTART;
								trx_cnt <= to_unsigned(1,3); -- we need one additional clock cycle to stay in sync
							end if;
						else
							pause <= '1';
						end if;
					elsif pause = '0' then
						-- TODO: also check address here, so pre-reads my be aborted if they got the wrong address
						data_buf <= data_buf(23 downto 0) & SPI_IO;
						trx_cnt <= trx_cnt - 1;
					end if;
				when RESTART =>
					if trx_cnt = "000" then
						flash_state <= ADDRESS;
						trx_cnt <= to_unsigned(5,3);
					else
						trx_cnt <= trx_cnt - 1;
					end if;
			end case;
		end if;
	end process;
	
	WB_ACK_O <= '1' when start_transfer = '1' and (ack_int(1) = '1' or (pause = '1' and addr_buf(FLASH_ADR_WIDTH downto 2) = WB_ADR_I(FLASH_ADR_WIDTH downto 2))) else '0';
end architecture rtl;