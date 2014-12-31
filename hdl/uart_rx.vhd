----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:33:50 09/24/2013 
-- Design Name: 
-- Module Name:    uart_rx - Behavioral 
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

entity uart_rx is
	port(
		reset:		in std_logic;
		clk:			in std_logic; -- baudrate * 8
		ser_data:	in std_logic; -- async data
		
		par_data:	out std_logic_vector(7 downto 0);
		valid:		out std_logic;
		error:		out std_logic);
		
end uart_rx;

architecture Behavioral of uart_rx is
	signal ser_data_buf, ser_data_sync: std_logic;
	signal rx_state: unsigned(3 downto 0);
	signal clk_div: unsigned(2 downto 0);
	signal data_buf: std_logic_vector(7 downto 0);
	constant RX_STATE_IDLE: unsigned(3 downto 0) := to_unsigned(0,4);
	constant RX_STATE_START: unsigned(3 downto 0) := to_unsigned(1,4);
	constant RX_STATE_STOP: unsigned(3 downto 0) := to_unsigned(10,4);
	constant RX_STATE_ERROR: unsigned(3 downto 0) := to_unsigned(15, 4);
begin
	sync_proc: process(reset, clk)
	begin
		if reset = '1' then
			ser_data_buf <= '1';
			ser_data_sync <= '1';
		elsif rising_edge(clk) then
			ser_data_buf <= ser_data;
			ser_data_sync <= ser_data_buf;
		end if;
	end process sync_proc;
	
	rx_fsm: process(reset, clk)
	begin
		if reset = '1' then
			rx_state <= RX_STATE_IDLE;
			clk_div <= (others => '0'); -- sample midpoint
			data_buf <= (others => '0');
			valid <= '0';
		elsif rising_edge(clk) then
			if ser_data_sync = '0' or rx_state /= RX_STATE_IDLE then
				clk_div <= clk_div + 1;
				
				if clk_div = to_unsigned(0,3) then
					if rx_state /= RX_STATE_ERROR then
						rx_state <= rx_state + 1;
					end if;
				end if;
				
				if clk_div = to_unsigned(3,4) then
					if rx_state = RX_STATE_START then
						-- startbit
						if ser_data_sync /= '0' then
							rx_state <= RX_STATE_ERROR;
						end if;
					elsif rx_state = RX_STATE_STOP then
						-- stopbit
						if ser_data_sync /= '1' then
							rx_state <= RX_STATE_ERROR;
						else
							valid <= '1';
							rx_state <= RX_STATE_IDLE;
						end if;
					elsif rx_state = RX_STATE_ERROR then
						if ser_data_sync = '1' then
							rx_state <= RX_STATE_IDLE;
						end if;
					else
						-- store bit, LSB transmitted first
						data_buf <= ser_data_sync & data_buf(7 downto 1);
					end if;
				end if;
			else
				clk_div <= (others => '0');
				valid <= '0';
			end if;
		end if;
	end process rx_fsm;
	
	par_data <= data_buf;
	error <= '1' when rx_state = RX_STATE_ERROR else '0';
end Behavioral;

