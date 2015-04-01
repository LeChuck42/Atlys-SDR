-------------------------------------------------------------------------------
--
-- Title       : bidir_delay
-- Design      : 
-- Author      : 
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- File        : bidir_delay.vhd
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity bidir_delay is
	generic (
		Tab : time := 5 ns;
		Tba : time := 5 ns);
	port(
		a : inout STD_LOGIC;
		b : inout STD_LOGIC
	    );
end bidir_delay;
											 

architecture sim of bidir_delay is
signal dir_ab: std_logic;
begin
	
	atob: process(a, b, dir_ab)
	variable fixed_until: time;
	begin
		
		if dir_ab = '1' then
			b <= transport a after Tab;
			if not b'event then
				fixed_until := now + Tab;
			end if;
		elsif dir_ab = '0' then
			a <= transport b after Tba;
			if not a'event then
				fixed_until := now + Tba;
			end if;
		else
			a <= 'Z';
			b <= 'Z';
		end if;
		
		if now > fixed_until then
			if (b = 'Z' or b = 'U' or b = 'L' or b = 'H') and (a = '1' or a = '0') then
				dir_ab <= '1';
			elsif (a = 'Z' or a = 'U' or a = 'L' or a = 'H') and (b = '1' or b = '0') then
				dir_ab <= '0';
			end if;
		end if;
	end process;
	
end sim;
