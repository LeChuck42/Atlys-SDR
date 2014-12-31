----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:07:01 09/24/2013 
-- Design Name: 
-- Module Name:    uart_tx - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
	port(
		reset:		in std_logic;
		clk:			in std_logic; -- baudrate * 8
		par_data:	in std_logic_vector(7 downto 0);
		start_tx:	in std_logic;
		
		busy:			out std_logic;
		full:			out std_logic;
		ser_data:	out std_logic);
end uart_tx;

architecture Behavioral of uart_tx is
	signal clk_div:	unsigned(2 downto 0);
	signal tx_state:	unsigned(3 downto 0);
	signal data_buf, data_next:	std_logic_vector(7 downto 0);
	signal full_int: std_logic;
	constant TX_STATE_IDLE: unsigned(3 downto 0) := to_unsigned(0,4);
	constant TX_STATE_START: unsigned(3 downto 0) := to_unsigned(1,4);
	constant TX_STATE_STOP: unsigned(3 downto 0) := to_unsigned(9,4);
	
begin
		
	tx_fsm:	process (reset, clk)
	begin
		if reset = '1' then
			ser_data <= '1';
			clk_div <= (others => '0');
			data_buf <= (others => '0');
			tx_state <= TX_STATE_IDLE;
			full_int <= '0';
		elsif rising_edge(clk) then
			if start_tx = '1' or tx_state /= TX_STATE_IDLE then
				if start_tx = '1' and tx_state /= TX_STATE_IDLE and full_int = '0' then
					data_next <= par_data;
					full_int <= '1';
				end if;
				clk_div <= clk_div + 1;
				if clk_div = to_unsigned(0,3) then
					if tx_state = TX_STATE_IDLE then
						-- transmit start bit
						data_buf <= par_data;
						ser_data <= '0';
					elsif tx_state = TX_STATE_STOP then
						-- transmit stop bit
						ser_data <= '1';
					else
						-- transmit data
						ser_data <= data_buf(0);
						data_buf <= "0" & data_buf(7 downto 1);
					end if;
					
					if tx_state = TX_STATE_STOP+1 then
						if full_int = '1' then
						   -- seamlessly transmit next frame
							tx_state <= TX_STATE_START;
							ser_data <= '0';
							full_int <= '0';
							data_buf <= data_next;
						elsif start_tx = '1' then
							-- seamlessly transmit new frame
							tx_state <= TX_STATE_START;
							ser_data <= '0';
							full_int <= '0';
							data_buf <= par_data;
						else
							tx_state <= TX_STATE_IDLE;
							ser_data <= '1';
						end if;
						
					else
						tx_state <= tx_state + 1;
					end if;
				end if;
			else
				clk_div <= (others => '0');
			end if;
		end if;
	end process tx_fsm;
	
	busy <= '0' when tx_state = to_unsigned(0,4) and start_tx = '0' else '1';
	full <= full_int;
end Behavioral;

