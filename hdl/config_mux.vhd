----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:48:32 07/15/2014 
-- Design Name: 
-- Module Name:    config_mux - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity config_mux is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  
           rx_ready : in  STD_LOGIC;
			  rx_data : in  STD_LOGIC_VECTOR (31 downto 0);
			  
           tx_full : in  STD_LOGIC;
           tx_wr : out  STD_LOGIC;
           tx_data : out  STD_LOGIC_VECTOR (31 downto 0);
			  
			  address : out STD_LOGIC_VECTOR (15 downto 0);
			  wr : out STD_LOGIC;
			  rd : out STD_LOGIC;
			  dout : out STD_LOGIC_VECTOR (31 downto 0);
			  din : in STD_LOGIC_VECTOR (31 downto 0));
end config_mux;

architecture rtl of config_mux is
	type state_t is (IDLE, ADDRESS, WR_DATA, RD_DATA);
	signal state : state_t;
begin
	
	dout <= rx_data;
	tx_data <= din;
	
	wr <= '1' when (state = WR_DATA) and (rx_ready = '1') else '0';
	
	rd <= '1' when (state = RD_DATA) else '0';
	tx_wr <= '1' when (state = RD_DATA) else '0';
	
	process (clk, reset)
	begin
		if reset = '1' then
			address <= (others => '0');
			state <= IDLE;
		elsif rising_edge(clk) then
			case (state) is
				when IDLE =>
					if rx_empty = '0' then
						state <= ADDRESS;
					end if;
				
				when ADDRESS =>
					if rx_empty = '0' then
						address <= rx_data(15 downto 0);
						
						if rx_data(31) = '1' then
							state <= WR_DATA;
						else
							state <= RD_DATA;
						end if;
					end if;
				
				--when WR_DATA =>
				--when RD_DATA =>
				when others =>
					state <= IDLE;
					
			end case;
		end if;
	end process;
					
end rtl;

