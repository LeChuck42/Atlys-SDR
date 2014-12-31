-- 0.1  MSE     27.07.2010 - First version
-- 0.2  MSE     27.08.2014 - Added wishbone interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_uart is
generic(
	clk_div_val : integer := 27);
	
port( 
	wb_clk_i    : in std_logic;
	wb_rst_i    : in std_logic;
	
	wb_dat_i    : in std_logic_vector(7 downto 0);
	wb_dat_o    : out std_logic_vector(7 downto 0);
	
	wb_adr_i    : in std_logic;
	
	wb_cyc_i    : in std_logic;
	wb_stb_i    : in std_logic;
	wb_we_i     : in std_logic;
	wb_cti_i    : in std_logic_vector(2 downto 0);
	wb_bte_i    : in std_logic_vector(1 downto 0);
	
	wb_ack_o    : out std_logic;
	wb_rty_o    : out std_logic;
	wb_err_o    : out std_logic;
	
	uart_out    : out std_logic;
	uart_in     : in std_logic;
	
	uart_int    : out std_logic);
end entity wb_uart;
	
architecture rtl of wb_uart is

	signal clk_div_cntr_16: unsigned(8 downto 0);
	signal clk_div_en_16:   std_logic;
	
	signal tx_bit_clk_cntr: unsigned(3 downto 0);
	signal rx_bit_clk_cntr: unsigned(3 downto 0);
	
	signal tx_fifo_re:      std_logic;
	signal tx_fifo_we:      std_logic;
	signal tx_fifo_q:       std_logic_vector(7 downto 0);
	signal tx_fifo_empty:   std_logic;
	signal tx_fifo_full:    std_logic;
	
	signal rx_fifo_re:      std_logic;
	signal rx_fifo_we:      std_logic;
	signal rx_fifo_q:       std_logic_vector(7 downto 0);
	signal rx_fifo_empty:   std_logic;
	signal rx_fifo_full:    std_logic;
	
	signal tx_shift_reg:    std_logic_vector(7 downto 0);
	signal rx_shift_reg:    std_logic_vector(7 downto 0);
	signal tx_state:        unsigned(3 downto 0);
	signal rx_state:        unsigned(3 downto 0);
	
	signal rx_err:          std_logic;
	signal rx_err_flag:     std_logic;
	
	signal cs_tx:           std_logic;
	signal cs_rx:           std_logic;
	signal cs_status:       std_logic;
	
	signal uart_status:     std_logic_vector(7 downto 0);
	signal data_read:       std_logic;
	
	component fifo_1024_8
	    port (
	        din:    in  std_logic_vector(7 downto 0);
	        clk:    in  std_logic;
	        wr_en:  in  std_logic;
	        rd_en:  in  std_logic;
	        rst:    in  std_logic;
	        dout:   out std_logic_vector(7 downto 0);
	        empty:  out std_logic;
	        full:   out std_logic);
	end component;

begin

	cs_tx       <= '1' when wb_cyc_i = '1' and wb_stb_i = '1' and wb_adr_i = '0' and wb_we_i = '1' else '0';
	cs_rx       <= '1' when wb_cyc_i = '1' and wb_stb_i = '1' and wb_adr_i = '0' and wb_we_i = '0' else '0';
	cs_status   <= '1' when wb_cyc_i = '1' and wb_stb_i = '1' and wb_adr_i = '1' and wb_we_i = '0' else '0';
	wb_err_o    <= '1' when wb_cyc_i = '1' and wb_stb_i = '1' and wb_adr_i = '1' and wb_we_i = '1' else '0';
	wb_rty_o <= '0';
	wb_ack_o <= '1' when tx_fifo_we = '1' or cs_status = '1' or (cs_rx = '1' and data_read = '0') else '0';
	
	uart_int <= '1' when data_read = '0' else '0';
	
	wb_dat_o <= rx_fifo_q when wb_adr_i = '0' else uart_status;
	
	tx_buf : fifo_1024_8
		port map (
			rst    => wb_rst_i,
			clk    => wb_clk_i,
			din    => wb_dat_i,
			wr_en  => tx_fifo_we,
			rd_en  => tx_fifo_re,
			dout   => tx_fifo_q,
			empty  => tx_fifo_empty,
			full   => tx_fifo_full);
	
	tx_fifo_we <= '1' when cs_tx = '1' and tx_fifo_full = '0' else '0';
	tx_fifo_re <= '1' when tx_fifo_empty = '0' and (tx_state = 0 or (tx_state = 12 and tx_bit_clk_cntr = x"E")) and clk_div_en_16 = '1' else '0';
	
	rx_buf : fifo_1024_8
		port map (
			rst    => wb_rst_i,
			clk    => wb_clk_i,
			din    => rx_shift_reg,
			wr_en  => rx_fifo_we,
			rd_en  => rx_fifo_re,
			dout   => rx_fifo_q,
			empty  => rx_fifo_empty,
			full   => rx_fifo_full);
	
	rx_fifo_we <= '1' when rx_state = 12 and rx_bit_clk_cntr = 10 and clk_div_en_16 = '1' else '0';
	
	clk_div_en_16 <= '1' when clk_div_cntr_16 = clk_div_val-1 else '0';
	
	proc_clk_div: process(wb_clk_i, wb_rst_i)
	begin
		if wb_rst_i = '1' then
			clk_div_cntr_16 <= (others => '0');
			uart_status <= (others => '0');
		elsif rising_edge(wb_clk_i) then
			clk_div_cntr_16 <= clk_div_cntr_16 + 1;
			if clk_div_en_16 = '1' then
				clk_div_cntr_16 <= (others => '0');
			end if;
			uart_status <= (0 => tx_fifo_full,
				1 => tx_fifo_empty,
				2 => rx_fifo_full,
				3 => rx_fifo_empty,
				4 => rx_err_flag,
				others => '0');
		end if;
	end process proc_clk_div;
	
	proc_serialize: process(wb_clk_i, wb_rst_i)
		variable parity: std_logic;
	begin
		if wb_rst_i = '1' then
			uart_out <= '1';
			tx_shift_reg <= (others => '0');
			tx_state <= (others => '0');
			parity := '0';
			tx_bit_clk_cntr <= (others => '0');
		elsif rising_edge(wb_clk_i) then
			if clk_div_en_16 = '1' then
				tx_bit_clk_cntr <= tx_bit_clk_cntr + 1;
				
				if tx_state = 0 then
					tx_bit_clk_cntr <= (others => '0');
					if tx_fifo_re = '1' then
						tx_state <= tx_state + 1;
					end if;
				elsif tx_state = 1 then
					tx_bit_clk_cntr <= (others => '0');
					tx_state <= tx_state + 1;
					-- START
					uart_out <= '0';
					parity := '0';
					tx_shift_reg <= tx_fifo_q;
				elsif tx_bit_clk_cntr = x"F" then
					tx_state <= tx_state + 1;
					if tx_state <= 9 then
						-- DATA (LSB first)
						uart_out <= tx_shift_reg(0);
						parity := parity xor tx_shift_reg(0);
						tx_shift_reg <= '0' & tx_shift_reg(7 downto 1);
					elsif tx_state = 10 then
						-- PARITY
						uart_out <= parity;
					elsif tx_state = 11 then
						-- STOP
						uart_out <= '1';
					end if;
				elsif tx_bit_clk_cntr = x"E" and tx_state = 12 then
					if tx_fifo_re = '1' then
						tx_state <= to_unsigned(1,tx_state'LENGTH);
					else
						tx_state <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process proc_serialize;
	
	proc_deserialize: process(wb_clk_i, wb_rst_i)
		variable parity: std_logic;
	begin
		if wb_rst_i = '1' then
			rx_shift_reg <= (others => '0');
			rx_state <= (others => '0');
			parity := '0';
			rx_bit_clk_cntr <= (others => '0');
			rx_err <= '0';
		elsif rising_edge(wb_clk_i) then
			if clk_div_en_16 = '1' then
				rx_bit_clk_cntr <= rx_bit_clk_cntr + 1;
				
				if rx_bit_clk_cntr = x"F" then
					rx_state <= rx_state + 1;
				end if;
				
				if rx_state = 0 then
					rx_bit_clk_cntr <= (others => '0');
					-- uart should be high at least once before we start receiving
					if uart_in = '1' then
						rx_state <= rx_state + 1;
					end if;
				elsif rx_state = 1 then
					parity := '0';
					rx_err <= '0';
					if uart_in = '0' then
						rx_state <= rx_state + 1;
					else
						rx_bit_clk_cntr <= (others => '0');
					end if;
				elsif rx_state = 2 then
					-- START
					if (rx_bit_clk_cntr = 7 or rx_bit_clk_cntr = 8 or rx_bit_clk_cntr = 9) and uart_in /= '0' then
						rx_err <= '1';
					end if;
				elsif rx_state <= 10 then
					-- DATA (LSB first)
					if rx_bit_clk_cntr = 7 then
						rx_shift_reg <= uart_in & rx_shift_reg(7 downto 1);
						parity := parity xor uart_in;
					elsif (rx_bit_clk_cntr = 8 or rx_bit_clk_cntr = 9) and rx_shift_reg(7) /= uart_in then
						rx_err <= '1';
					end if;
				elsif rx_state = 11 then
					-- PARITY
					if (rx_bit_clk_cntr = 7 or rx_bit_clk_cntr = 8 or rx_bit_clk_cntr = 9) and uart_in /= parity then
						rx_err <= '1';
					end if;
				elsif rx_state = 12 then
					-- STOP
					if (rx_bit_clk_cntr = 7 or rx_bit_clk_cntr = 8 or rx_bit_clk_cntr = 9) and uart_in /= '1' then
						rx_err <= '1';
					elsif rx_bit_clk_cntr = 10 then
						rx_state <= to_unsigned(1,rx_state'LENGTH);
					end if;
				end if;
			end if;
		end if;
	end process proc_deserialize;
	
	rx_mon: process(wb_clk_i, wb_rst_i)
	begin
		if wb_rst_i = '1' then
			rx_err_flag <= '0';
			data_read <= '1';
			rx_fifo_re <= '0';
		elsif rising_edge(wb_clk_i) then
			if rx_err = '1' and rx_fifo_we = '1' then
				rx_err_flag <= '1';
			elsif cs_status = '1' then
				rx_err_flag <= '0';
			end if;
			
			if rx_fifo_empty = '0' and (data_read = '1' or cs_rx = '1') then
				rx_fifo_re <= '1';
				data_read <= '0';
			else
				rx_fifo_re <= '0';
				if cs_rx = '1' then
					data_read <= '1';
				end if;
			end if;
		end if;
	end process;

end architecture rtl;