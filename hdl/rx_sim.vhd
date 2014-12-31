----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:13:12 10/30/2014 
-- Design Name: 
-- Module Name:    rx_sim - sim 
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

entity rx_sim is
	port (
		MUXCLK: in std_logic;
		MUXIN: in std_logic;
		MUXOUT: out std_logic);
end rx_sim;

architecture sim of rx_sim is
signal tx_mux_d: std_logic_vector(7 downto 0);
signal rx_mux_alignwd: std_logic;
signal mux_reset: std_logic;
signal rx_mux_buf: std_logic_vector(7 downto 0);
signal rx_mux_q: std_logic_vector(7 downto 0);
signal rx_mux_sclk: std_logic;
signal sync_mon_valid, sync_mon_expect, sync_mon_out: std_logic;
signal sync_delay: std_logic;
signal sync_pattern: std_logic_vector(7 downto 0);
signal mux_synced: std_logic;
signal tx_mux_reg: std_logic_vector(7 downto 0);
begin

	reset_proc: process
	begin
		mux_reset <= '1';
		wait for 100 ns;
		mux_reset <= '0';
		wait;
	end process;

	rx_sim_proc: process
		variable cnt: integer range 0 to 7;
		variable slipped: std_logic;
	begin
		cnt := 0;
		slipped := '0';
		rx_mux_buf <= (others => '0');
		rx_mux_q <= (others => '0');
		loop
			wait on MUXCLK;
			rx_mux_sclk <= '0';
			rx_mux_buf(cnt) <= MUXIN;
			if cnt < 7 then
				if rx_mux_alignwd = '0' or slipped = '1' then
					cnt := cnt + 1;
				else
					slipped := '1';
				end if;
			else
				slipped := '0';
				cnt := 0;
				rx_mux_q <= MUXIN & rx_mux_buf(6 downto 0) after 1ns;
				rx_mux_sclk <= '1';
			end if;
		end loop;
	end process;

	tx_mux_reg <= sync_mon_out & "0000000";
	tx_mux_d <= tx_mux_reg when mux_synced = '1' else sync_pattern;
	
	tx_sim_proc: process(MUXCLK, mux_reset)
		variable cnt: integer range 0 to 7;
		variable tx_mux_buf: std_logic_vector(7 downto 0);
	begin
		if mux_reset = '1' then
			cnt := 0;
			MUXOUT <= '0';
		else
			if cnt = 0 then
				tx_mux_buf := tx_mux_d;
			end if;
			MUXOUT <= tx_mux_buf(cnt) after 1 ns;
			if cnt < 7 then
				cnt := cnt + 1;
			else
				cnt := 0;
			end if;
		end if;
	end process;
		
	mux_sync_func: process(mux_reset, rx_mux_sclk)
	begin
		if mux_reset = '1' then
			rx_mux_alignwd <= '0';
			mux_synced <= '0';
			sync_pattern <= x"01";	
			sync_delay <= '1';
			sync_mon_out <= '0';
			sync_mon_valid <= '0';
			sync_mon_expect <= '0';
		elsif rising_edge(rx_mux_sclk) then
			sync_delay <= rx_mux_alignwd;
			rx_mux_alignwd <= '0';
			sync_mon_out <= not sync_mon_out;
			if mux_synced = '1' then
				if sync_mon_valid = '1' then
					if sync_mon_expect = rx_mux_q(7) then
						sync_mon_expect <= not sync_mon_expect;
					else
						mux_synced <= '0';
						sync_delay <= '1';
						sync_mon_valid <= '0';
					end if;
				elsif rx_mux_q /= x"81" then
					sync_mon_valid <= '1';
					sync_mon_expect <= not rx_mux_q(7);
				end if;
			elsif rx_mux_alignwd = '0' and sync_delay = '0' then
				-- not synced
				if rx_mux_q /= x"81" and rx_mux_q /= x"01" then
					-- no sync pattern -> shift inputs
					sync_pattern <= x"01";
					rx_mux_alignwd <= '1';
				else
					-- sync pattern recognized, wait for master
					sync_pattern <= x"81";
					if rx_mux_q = x"81" and sync_pattern = x"81" then
						mux_synced <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
end sim;

