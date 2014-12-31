-- 0.1  MSE		20.09.2012 - First version

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	

entity scope is
port( 
	clk			: in std_logic;
	trigger		: in std_logic;
	probes		: in std_logic_vector(79 downto 0);
	arm			: in std_logic;
	
	read_clk		: in std_logic;
	read_address: in std_logic_vector(10 downto 0);
	read_data	: out std_logic_vector(80 downto 0);
	ready			: out std_logic);
end entity scope;
	
architecture rtl of scope is

constant TRIGGER_POS:	natural := 128;

signal read_abs, read_pos, write_pos, trig_pos:	unsigned(10 downto 0);
signal ready_int:			std_logic;

signal trigger_int:		std_logic;
signal trigger_buf:		std_logic;

signal ready_buf: std_logic;

signal mem_wea: std_logic_vector(0 downto 0);
signal mem_dina, mem_doutb: std_logic_vector(80 downto 0);

component scope_mem
	port(
	  clka: in  std_logic; 
	  wea: in  std_logic_vector(0 downto 0); 
	  addra: in  std_logic_vector(10 downto 0); 
	  dina: in  std_logic_vector(80 downto 0); 
	  clkb: in  std_logic; 
	  addrb: in  std_logic_vector(10 downto 0); 
	  doutb: out  std_logic_vector(80 downto 0));
end component scope_mem;

begin

capture_proc: process(clk, arm)
	variable triggered: std_logic;
	variable pre_trigger_ready: std_logic;
begin
	if arm = '0' then
		write_pos <= (others => '0');
		trig_pos <= (others => '0');
		read_pos <= (others => '0');
		triggered := '0';
		ready_int <= '0';
		trigger_buf <= '0';
		pre_trigger_ready := '0';
	elsif rising_edge(clk) then
		if ready_int = '0' then
		
			trigger_buf <= trigger;
			
			if trigger = '1' and trigger_buf = '0' then
				triggered := '1';
			end if;
				
			if pre_trigger_ready = '0' then
				-- fill up pre trigger buffer
				write_pos <= write_pos + 1;
				if write_pos+1 = to_unsigned(TRIGGER_POS,write_pos'LENGTH) then
					pre_trigger_ready := '1';
				end if;
			elsif triggered = '1' then
				-- increase write pos only
				write_pos <= write_pos + 1;
				
				if write_pos+1 = read_pos then
					ready_int <= '1';
				end if;
			else
				-- increase both
				write_pos <= write_pos + 1;
				read_pos <= read_pos + 1;
				
			end if; -- triggered
		end if; -- ready
	end if; -- clk
end process capture_proc;

read_abs <= read_pos + unsigned(read_address);

ready_sync: process(read_clk, arm)
begin
	if arm = '0' then
		ready <= '0';
		ready_buf <= '0';
	elsif rising_edge(read_clk) then
		ready_buf <= ready_int;
		ready <= ready_buf;
	end if;
end process ready_sync;

mem_wea(0) <= not ready_int;
mem_dina(80) <= trigger;
mem_dina(79 downto 0) <= probes;

scope_mem_inst: scope_mem
	port map(
		clka => clk, 
		wea => mem_wea, 
		addra => std_logic_vector(write_pos),
		dina => mem_dina,
		clkb => read_clk,
		addrb => std_logic_vector(read_abs), 
		doutb => mem_doutb);

read_data <= mem_doutb;

end architecture rtl;