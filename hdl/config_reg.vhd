----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:28:20 07/15/2014 
-- Design Name: 
-- Module Name:    config_reg - rtl 
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

entity config_reg is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           wr : in  STD_LOGIC;
           rd : in  STD_LOGIC;
           d : in  STD_LOGIC_VECTOR (31 downto 0);
           q : out  STD_LOGIC_VECTOR (31 downto 0));
end config_reg;

architecture rtl of config_reg is
	signal data: STD_LOGIC_VECTOR(31 downto 0);
begin
	q <= data when rd = '1' else (others => 'Z');
	
	data_reg: process (clk, reset)
	begin
		if reset = '1' then
			data <= (others => '0');
		elsif rising_edge(clk) then
			if wr = '1' then
				data <= d;
			end if;
		end if;
	end process data_reg;

end rtl;

