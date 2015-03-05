library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_flash_if is
	generic (
		FLASH_ADR_WIDTH: natural := 22;
		DUMMY_CYCLES:    natural := 10);
	port (
	    CLK      : in std_logic;
		CLK_INV  : in std_logic;
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
	type flash_state_t is (INIT, ADDRESS, XIP_CONFIRM, DUMMY, READ_DATA, RESTART);
	signal flash_state:     flash_state_t;
	signal addr_buf:        std_logic_vector(23 downto 0);
	signal burst_start:     std_logic_vector(23 downto 0);
	signal trx_cnt:         unsigned (5 downto 0);
	signal burst_cnt:       unsigned (3 downto 0);
	signal flash_init_data: std_logic_vector(59 downto 0);
	signal flash_init_cs:   std_logic_vector(59 downto 0);
	signal flash_command:   std_logic_vector(7 downto 0)
	signal data_buf:        std_logic_vector(27 downto 0);
	signal burst_wrap:      std_logic;
	signal addr_clipped:    std_logic_vector(23 downto 0);
	signal start_transfer:  std_logic;
	signal ack_int:         std_logic_vector(2 downto 0);
	signal pause:           std_logic;
	signal sync_state:      std_logic;
begin

	WB_RTY_O <= '0';
	WB_ERR_O  <= '1' when WB_WE_I = '1' and WB_CYC_I = '1' and WB_STB_I = '1' else '0'; -- read only
	
	WB_ACK_O <= '1' when start_transfer = '1' and (ack_int(2) = '1' or 
		(pause = '1' and addr_buf(FLASH_ADR_WIDTH downto 2) = WB_ADR_I(FLASH_ADR_WIDTH downto 2))) else '0';
	
	SPI_IO(0) <= flash_init_data(flash_init_data'LEFT) when flash_state = INIT else
	             addr_buf(20)                          when flash_state = ADDRESS else
	             '0'                                   when flash_state = XIP_CONFIRM else 'Z';
	
	SPI_IO(1) <= addr_buf(21) when flash_state = ADDRESS else 'Z';
	SPI_IO(2) <= addr_buf(22) when flash_state = ADDRESS else 'Z';
	SPI_IO(3) <= addr_buf(23) when flash_state = ADDRESS else 'Z';
		
	SPI_CSN <= flash_init_cs(flash_init_cs'LEFT) when flash_state = INIT else
		'0' when flash_state /= RESTART else '1';
	
	SPI_CLK <= CLK_INV when (flash_state /= RESTART and pause = '0') else 'Z'; -- todo: check for fast alternative
	
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
			if WB_CYC_I = '1' and WB_STB_I = '1' and WB_WE_I = '0' then
				start_transfer <= '1' after 1 ns;
			else
				start_transfer <= '0' after 1 ns;
			end if;
		end if;
	end process;
	
	flash_fsm: process(CLK, RESET)
	begin
		if RESET = '1' then
			flash_state <= INIT;
			trx_cnt <= to_unsigned(flash_init_data'LENGTH, trx_cnt'LENGTH);
			burst_cnt <= (others => '0');
			burst_start <= (others => '0');
			ack_int <= (others => '0');
			-- INIT COMMANDS:  WREN          WRVCR   DATA               WREN          WRVECR  DATA               QIOR
			flash_init_data <= x"06" & "0" & x"81" & "11110000" & "0" & x"06" & "0" & x"61" & "01011111" & "0" & x"EB";
			flash_init_cs   <= x"FF" & "0" & x"FF" & "11111111" & "0" & x"FF" & "0" & x"FF" & "11111111" & "0" & x"FF";
			data_buf <= (others => '0');
			WB_DAT_O <= (others => '0');
			pause <= '0';
			sync_state <= '0';
			addr_buf <= x"000100";
		elsif rising_edge(CLK) then
			if start_transfer = '1' then
				sync_state <= not sync_state;
			else
				sync_state <= '0';
			end if;
			
			ack_int <= ack_int(1 downto 0) & '0';
			pause <= '0';
			case (flash_state) is
				
				when INIT =>
					-- shift out sequence to setup flash in XIP/QIOR mode
					flash_init_data <= flash_init_data(flash_init_data'LEFT-1 downto 0) & flash_init_data(flash_init_data'LEFT); -- rol
					flash_init_cs   <= flash_init_cs  (flash_init_cs'LEFT  -1 downto 0) & flash_init_cs  (flash_init_cs'LEFT  ); -- rol
					burst_cnt <= (others => '0');
					burst_start <= (others => '0');
					
					if trx_cnt = to_unsigned(0,trx_cnt'LENGTH) then
						flash_state <= ADDRESS;
						trx_cnt <= to_unsigned(5,3);
					else
						trx_cnt <= trx_cnt - 1;
					end if;
				
				when ADDRESS =>
					addr_buf <= addr_buf(19 downto 0) & addr_buf(23 downto 20); -- 4 byte rol
					if trx_cnt = to_unsigned(0,trx_cnt'LENGTH) then
						flash_state <= XIP_CONFIRM;
						trx_cnt <= to_unsigned(DUMMY_CYCLES-1, trx_cnt'LENGTH);
					else
						trx_cnt <= trx_cnt - 1;
					end if;
					
				when XIP_CONFIRM =>
					flash_state <= DUMMY;
					trx_cnt <= trx_cnt - 1;
					
				when DUMMY =>
					-- bus turnaround
					if trx_cnt = to_unsigned(0,trx_cnt'LENGTH) then
						flash_state <= READ_DATA;
						trx_cnt <= to_unsigned(7,trx_cnt'LENGTH);
						burst_start(FLASH_ADR_WIDTH downto 2) <= WB_ADR_I(FLASH_ADR_WIDTH downto 2);
					else
						trx_cnt <= trx_cnt - 1;
					end if;
					
				when READ_DATA =>
					if trx_cnt = to_unsigned(0,trx_cnt'LENGTH) then
						if pause = '0' then
							WB_DAT_O <= data_buf & SPI_IO;
						end if;
						if start_transfer = '1' then
							if burst_cnt = 0 then
								burst_start(FLASH_ADR_WIDTH downto 2) <= WB_ADR_I(FLASH_ADR_WIDTH downto 2);
							end if;
							if pause = '0' or ( pause = '1' and addr_buf(FLASH_ADR_WIDTH downto 2) = WB_ADR_I(FLASH_ADR_WIDTH downto 2)) then
								--data_buf <= data_buf(23 downto 0) & SPI_IO;
								trx_cnt <= to_unsigned(7,trx_cnt'LENGTH);
								--synchronize ack signal
								if sync_state = '0' then
									ack_int <= "110";
								elsif pause = '1' then
									ack_int <= "100"; 
								else
									ack_int <= "011";
								end if;
								addr_buf <= std_logic_vector(unsigned(addr_buf) + 4);
								
								if WB_CTI_I = "010" then
									-- incrementing address burst cycle
									burst_cnt <= burst_cnt + 1;
									
									if burst_wrap = '1' then
										addr_buf <= addr_clipped;
										flash_state <= RESTART;
										trx_cnt <= to_unsigned(0,trx_cnt'LENGTH);
										trx_cnt(0) <= not sync_state;
									end if;
								elsif WB_CTI_I = "111" then
									burst_cnt <= (others => '0');
								end if;
							else -- if addr_buf
								-- we (pre)read the wrong address -> restart with correct one
								addr_buf <= (others => '0');
								addr_buf(FLASH_ADR_WIDTH downto 2) <= WB_ADR_I(FLASH_ADR_WIDTH downto 2);
								flash_state <= RESTART;
								trx_cnt <= to_unsigned(0,trx_cnt'LENGTH);
								trx_cnt(0) <= sync_state; -- we need one additional clock cycle to stay in sync
							end if; -- if addr_buf
						else -- if start_transfer
							-- pre read finished, pause until next request
							burst_start(FLASH_ADR_WIDTH downto 2) <= addr_buf(FLASH_ADR_WIDTH downto 2);
							pause <= '1';
						end if;
					elsif pause = '0' then -- if trx_cnt
						-- TODO: also check address here, so pre-reads my be aborted if they got the wrong address
						data_buf <= data_buf(23 downto 0) & SPI_IO;
						trx_cnt <= trx_cnt - 1;
					end if;
					
				when RESTART =>
					if trx_cnt = to_unsigned(0,trx_cnt'LENGTH) then
						flash_state <= ADDRESS;
						trx_cnt <= to_unsigned(5,trx_cnt'LENGTH);
					else
						trx_cnt <= trx_cnt - 1;
					end if;
			end case;
		end if;
	end process;
	
end architecture rtl;