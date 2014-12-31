----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:58:01 09/24/2013 
-- Design Name: 
-- Module Name:    uart_scope - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	

entity uart_scope is
	port (
		reset: in std_logic;
		rxd: in std_logic;
		txd: out std_logic;
		baud_clk: in std_logic;
		
		probes: in std_logic_vector(79 downto 0);
		probe_clk: in std_logic;
		armed: out std_logic;
		triggered: out std_logic);
end uart_scope;

architecture Behavioral of uart_scope is
	signal rx_data, tx_data: std_logic_vector(7 downto 0);
	signal rx_valid, tx_busy, start_tx: std_logic;
	signal scope_address: unsigned(10 downto 0);
	signal scope_data: std_logic_vector(80 downto 0);
	signal scope_ready, scope_trigger, scope_arm: std_logic;
	signal scope_arm_buf, scope_arm_sync: std_logic;
	type SCOPE_STATE_TYPE is (
		SCOPE_STATE_IDLE,
		SCOPE_STATE_SET_RISING_TRIGGER,
		SCOPE_STATE_SET_FALLING_TRIGGER,
		SCOPE_STATE_SET_HIGH_TRIGGER,
		SCOPE_STATE_SET_LOW_TRIGGER,
		SCOPE_STATE_ARMED,
		SCOPE_STATE_READY,
		SCOPE_STATE_SENDING);
	signal scope_state: SCOPE_STATE_TYPE;
	signal probe_buf, sample_buf: std_logic_vector(79 downto 0);
	signal trigger_mask_rising, trigger_mask_falling, trigger_mask_high, trigger_mask_low: std_logic_vector(79 downto 0);
	signal trigger_mask_rising_buf, trigger_mask_falling_buf, trigger_mask_high_buf, trigger_mask_low_buf: std_logic_vector(79 downto 0);
	signal trigger_mask_rising_sync, trigger_mask_falling_sync, trigger_mask_high_sync, trigger_mask_low_sync: std_logic_vector(79 downto 0);
	component uart_rx
		port(
			reset:		in std_logic;
			clk:			in std_logic; -- baudrate * 8
			ser_data:	in std_logic; -- async data
			
			par_data:	out std_logic_vector(7 downto 0);
			valid:		out std_logic;
			error:		out std_logic);
	end component uart_rx;

	component uart_tx is
		port(
			reset:		in std_logic;
			clk:			in std_logic; -- baudrate * 8
			par_data:	in std_logic_vector(7 downto 0);
			start_tx:	in std_logic;
			
			busy:			out std_logic;
			full:			out std_logic;
			ser_data:	out std_logic);
	end component uart_tx;

	component scope is
	port( 
		clk			: in std_logic;
		trigger		: in std_logic;
		probes		: in std_logic_vector(79 downto 0);
		arm			: in std_logic;
		
		read_clk		: in std_logic;
		read_address: in std_logic_vector(10 downto 0);
		read_data	: out std_logic_vector(80 downto 0);
		ready			: out std_logic);
	end component scope;
begin

	scope_tx: uart_tx port map (
		reset => reset,
		clk => baud_clk,
		par_data => tx_data,
		start_tx => start_tx,
			
		busy => open,
		full => tx_busy,
		ser_data => txd);
		
	scope_rx: uart_rx port map (
		reset => reset,
		clk => baud_clk,
		ser_data => rxd,
		par_data => rx_data,
		valid => rx_valid,
		error => open);

	mac_scope: scope port map (
		clk => probe_clk,
		trigger => scope_trigger,
		probes => probes,
		arm => scope_arm_sync,
		
		read_clk => baud_clk,
		read_address => std_logic_vector(scope_address),
		read_data => scope_data,
		ready => scope_ready);

	scope_fsm: process (baud_clk, reset)
	variable cnt: unsigned(3 downto 0);
	begin
		if reset = '1' then
			scope_state <= SCOPE_STATE_IDLE;
			tx_data <= (others => '0');
			cnt := (others => '0');
			scope_address <= (others => '0');
			sample_buf <= (others => '0');
			trigger_mask_rising <= (others => '0');
			trigger_mask_falling <= (others => '0');
			trigger_mask_high <= (others => '0');
			trigger_mask_low <= (others => '0');
			scope_arm <= '0';
			start_tx <= '0';
			
		elsif rising_edge(baud_clk) then
			start_tx <= '0';
			if scope_state = SCOPE_STATE_IDLE then
				cnt := (others => '0');
				if rx_valid = '1' then
					tx_data <= rx_data;
					scope_arm <= '0';
					if rx_data = x"52" then -- "R"
						scope_state <= SCOPE_STATE_SET_RISING_TRIGGER;
						start_tx <= '1';
					elsif rx_data = x"46" then -- "F"
						scope_state <= SCOPE_STATE_SET_FALLING_TRIGGER;
						start_tx <= '1';
					elsif rx_data = x"48" then -- "H"
						scope_state <= SCOPE_STATE_SET_HIGH_TRIGGER;
						start_tx <= '1';
					elsif rx_data = x"4C" then -- "L"
						scope_state <= SCOPE_STATE_SET_LOW_TRIGGER;
						start_tx <= '1';
					elsif rx_data = x"41" then -- "A"
						scope_state <= SCOPE_STATE_ARMED;
						start_tx <= '1';
					else
						tx_data <= x"3F";  -- "?"
						start_tx <= '1';
					end if;
				end if;
				
			elsif scope_state = SCOPE_STATE_SET_RISING_TRIGGER then
				if rx_valid = '1' then
					tx_data <= rx_data;
					start_tx <= '1';
					trigger_mask_rising <= trigger_mask_rising(71 downto 0) & rx_data;
					if cnt = to_unsigned(9, 4) then
						scope_state <= SCOPE_STATE_IDLE;
					else
						cnt := cnt + 1;
					end if;
				end if;
			
			elsif scope_state = SCOPE_STATE_SET_FALLING_TRIGGER then
				if rx_valid = '1' then
					tx_data <= rx_data;
					start_tx <= '1';
					trigger_mask_falling <= trigger_mask_falling(71 downto 0) & rx_data;
					if cnt = to_unsigned(9, 4) then
						scope_state <= SCOPE_STATE_IDLE;
					else
						cnt := cnt + 1;
					end if;
				end if;
			
			elsif scope_state = SCOPE_STATE_SET_HIGH_TRIGGER then
				if rx_valid = '1' then
					tx_data <= rx_data;
					start_tx <= '1';
					trigger_mask_high <= trigger_mask_high(71 downto 0) & rx_data;
					if cnt = to_unsigned(9, 4) then
						scope_state <= SCOPE_STATE_IDLE;
					else
						cnt := cnt + 1;
					end if;
				end if;
			
			elsif scope_state = SCOPE_STATE_SET_LOW_TRIGGER then
				if rx_valid = '1' then
					tx_data <= rx_data;
					start_tx <= '1';
					trigger_mask_low <= trigger_mask_low(71 downto 0) & rx_data;
					if cnt = to_unsigned(9, 4) then
						scope_state <= SCOPE_STATE_IDLE;
					else
						cnt := cnt + 1;
					end if;
				end if;
			
			elsif scope_state = SCOPE_STATE_ARMED then
				scope_arm <= '1';
				if scope_ready = '1' then
					scope_state <= SCOPE_STATE_READY;
				elsif rx_valid = '1' then
					tx_data <= rx_data;
					start_tx <= '1';
					if rx_data = x"43" then -- "C"
						scope_arm <= '0';
						scope_state <= SCOPE_STATE_IDLE;
					else
						tx_data <= x"3F"; -- "?"
					end if;
				end if;
				
			elsif scope_state = SCOPE_STATE_READY then
				if tx_busy = '0' then
					if cnt = to_unsigned(0, 4) then
						-- buffer sample
						sample_buf <= scope_data(79 downto 0);
						-- send trigger flag
						if scope_data(80) = '1' then
							tx_data <= x"31"; -- "1"
						else
							tx_data <= x"30"; -- "0"
						end if;
						start_tx <= '1';
						scope_state <= SCOPE_STATE_SENDING;
						cnt := cnt + 1;
					else
						-- send data
						tx_data <= sample_buf(79 downto 72);
						sample_buf <= sample_buf(71 downto 0) & x"00";
						start_tx <= '1';
						if cnt = to_unsigned(10, 4) then
							if scope_address = (scope_address'RANGE => '1') then
								-- transfer finished
								scope_state <= SCOPE_STATE_IDLE;
							else
								-- next frame
								scope_state <= SCOPE_STATE_SENDING;
							end if;
							cnt := (others => '0');
							scope_address <= scope_address + 1;
						else
							cnt := cnt + 1;
							scope_state <= SCOPE_STATE_SENDING;
						end if;
					end if;
				end if;
			elsif scope_state = SCOPE_STATE_SENDING then
				start_tx <= '0';
				if tx_busy = '0' then
					scope_state <= SCOPE_STATE_READY;
				end if;
			else
				scope_state <= SCOPE_STATE_IDLE;
			end if;
		end if;
	end process scope_fsm;
	
	probe_clk_sync: process (probe_clk, reset)
	begin
		if reset = '1' then
			trigger_mask_rising_buf <= (others => '0');
			trigger_mask_falling_buf <= (others => '0');
			trigger_mask_high_buf <= (others => '0');
			trigger_mask_low_buf <= (others => '0');
			
			trigger_mask_rising_sync <= (others => '0');
			trigger_mask_falling_sync <= (others => '0');
			trigger_mask_high_sync <= (others => '0');
			trigger_mask_low_sync <= (others => '0');
			
			scope_arm_buf <= '0';
			scope_arm_sync <= '0';
		elsif rising_edge(probe_clk) then
			trigger_mask_rising_buf <= trigger_mask_rising;
			trigger_mask_falling_buf <= trigger_mask_falling;
			trigger_mask_high_buf <= trigger_mask_high;
			trigger_mask_low_buf <= trigger_mask_low;
			
			trigger_mask_rising_sync <= trigger_mask_rising_buf;
			trigger_mask_falling_sync <= trigger_mask_falling_buf;
			trigger_mask_high_sync <= trigger_mask_high_buf;
			trigger_mask_low_sync <= trigger_mask_low_buf;
			
			scope_arm_buf <= scope_arm;
			scope_arm_sync <= scope_arm_buf;
		end if;
	end process probe_clk_sync;
	
	trigger_proc: process (probe_clk, reset)
	variable trigger_rising, trigger_falling, trigger_high, trigger_low: std_logic;
	begin
		if reset = '1' then
			probe_buf <= (others => '0');
			trigger_rising := '0';
			trigger_falling := '0';
		elsif rising_edge(probe_clk) then
			probe_buf <= probes;
			
			if (((probe_buf xor probes) and probes) and trigger_mask_rising_sync) = trigger_mask_rising_sync then
				trigger_rising := '1';
			else
				trigger_rising := '0';
			end if;
			
			if (((probe_buf xor probes) and not probes) and trigger_mask_falling_sync) = trigger_mask_falling_sync then
				trigger_falling := '1';
			else
				trigger_falling := '0';
			end if;
			
			if ( probes and trigger_mask_high_sync) = trigger_mask_high_sync then
				trigger_high := '1';
			else
				trigger_high := '0';
			end if;
			
			if ( (not probes) and trigger_mask_low_sync) = trigger_mask_low_sync then
				trigger_low := '1';
			else
				trigger_low := '0';
			end if;
			
			scope_trigger <= scope_arm_sync and trigger_rising and trigger_falling and trigger_high and trigger_low;
		end if;
	end process trigger_proc;
	
	triggered <= scope_trigger;
	armed <= scope_arm;
	
end Behavioral;

