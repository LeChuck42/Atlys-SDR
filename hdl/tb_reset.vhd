--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:53:36 12/09/2011
-- Design Name:   
-- Module Name:   C:/Users/Administrator/Desktop/Xilinx/atlys_ethernet_test_v1/atlys_ethernet_test_v1/tb_reset.vhd
-- Project Name:  atlys_ethernet_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: reset
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_reset IS
END tb_reset;
 
ARCHITECTURE behavior OF tb_reset IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT reset
    PORT(
         clk : IN  std_logic;
         pll_lock : IN  std_logic;
         rst_100 : OUT  std_logic;
         clk_150 : IN  std_logic;
         rst_150 : OUT  std_logic;
         ext_reset : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal pll_lock : std_logic := '0';
   signal clk_150 : std_logic := '0';
   signal ext_reset : std_logic := '0';

 	--Outputs
   signal rst_100 : std_logic;
   signal rst_150 : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant clk_150_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: reset PORT MAP (
          clk => clk,
          pll_lock => pll_lock,
          rst_100 => rst_100,
          clk_150 => clk_150,
          rst_150 => rst_150,
          ext_reset => ext_reset
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   clk_150_process :process
   begin
		clk_150 <= '0';
		wait for clk_150_period/2;
		clk_150 <= '1';
		wait for clk_150_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
