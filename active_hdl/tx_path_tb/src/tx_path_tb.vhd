library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx_path_tb is

end entity tx_path_tb;

architecture sim of tx_path_tb is
	component packet_receiver is
		port (
			clk             : in  std_logic;
			reset           : in  std_logic;

			rd_flags_i      : in  std_logic_vector(3 downto 0);
			rd_data_i       : in  std_logic_vector(31 downto 0);
			rd_src_rdy_i    : in  std_logic;
			rd_dst_rdy_o    : out std_logic;

			data_out_dac    : out std_logic;
			data_out_cpu    : out std_logic;

			data_out        : out std_logic_vector(31 downto 0);

			packet_loss     : out std_logic;

			my_mac          : in  std_logic_vector(47 downto 0);
			my_ip           : in  std_logic_vector(31 downto 0));
	end component;

	signal clk              : std_logic;
	signal reset            : std_logic;
	signal rd_flags_i       : std_logic_vector(3 downto 0);
	signal rd_data_i        : std_logic_vector(31 downto 0);
	signal rd_src_rdy_i     : std_logic;
	signal rd_dst_rdy_o     : std_logic;
	signal data_out_dac     : std_logic;
	signal data_out_cpu     : std_logic;
	signal data_out         : std_logic_vector(31 downto 0);
	signal packet_loss      : std_logic;
	signal my_mac           : std_logic_vector(47 downto 0);
	signal my_ip            : std_logic_vector(31 downto 0);

begin

	uut: packet_receiver port map (
		clk             => clk,
		reset           => reset,
		rd_flags_i      => rd_flags_i,
		rd_data_i       => rd_data_i,
		rd_src_rdy_i    => rd_src_rdy_i,
		rd_dst_rdy_o    => rd_dst_rdy_o,
		data_out_dac    => data_out_dac,
		data_out_cpu    => data_out_cpu,
		data_out        => data_out,
		packet_loss     => packet_loss,
		my_mac          => my_mac,
		my_ip           => my_ip);

	clk_gen: process
	begin
		-- 125 MHz
		clk <= '0';
		wait for 4 ns;
		clk <= '1';
		wait for 4 ns;
	end process;
	
	rst_gen: process
	begin
		reset <= '1';
		wait until clk = '1';
		wait until clk = '1';
		reset <= '0';
		wait;
	end process;
	
	data_gen: process
		procedure mac_data32(data: std_logic_vector(31 downto 0)) is
		begin
			rd_src_rdy_i <= '1';
			rd_data_i <= data;
			loop
				wait until clk = '1';
				if rd_dst_rdy_o = '1' then
					exit;
				end if;
			end loop;
			rd_src_rdy_i <= '0';
		end procedure;

		procedure ip_header(
			src_mac: std_logic_vector(47 downto 0);
			dst_mac: std_logic_vector(47 downto 0);
			src_ip: std_logic_vector(31 downto 0);
			dst_ip: std_logic_vector(31 downto 0);
			src_port: std_logic_vector(15 downto 0);
			dst_port: std_logic_vector(15 downto 0);
			packet_count: integer;
			payload_length: integer) is
			
		variable checksum: unsigned(15 downto 0);
		variable header: std_logic_vector(319 downto 0);
		begin
			header := dst_mac & 
			          src_mac & 
			          x"08004500" &
			          std_logic_vector(to_unsigned(payload_length + 30, 16)) & x"aabb" &
			          x"00004011" &
			          x"0000" & -- checksum
			          src_ip &
			          dst_ip &
			          src_port &
			          dst_port &
			          std_logic_vector(to_unsigned(payload_length + 10, 16));
			checksum := (others => '0');
			for i in 19 downto 0 loop
				checksum := checksum + unsigned(header(i*16 + 15 downto i*16));
			end loop;
			checksum := not checksum;
			header(127 downto 112) := std_logic_vector(checksum);
			
			rd_flags_i(0) <= '1';
			for i in 9 downto 0 loop
				mac_data32(header(i*32 + 31 downto i*32));
				rd_flags_i(0) <= '0';
				wait until clk = '1';
			end loop;
			mac_data32(x"0000" & std_logic_vector(to_unsigned(packet_count, 16)));
		end procedure;
		
	begin
		rd_src_rdy_i <= '0';
		my_mac <= x"0037ffff3737";
		my_ip <= x"c0a80101";
		rd_flags_i <= (others => '0');
		rd_data_i <= (others => '0');
		wait for 100 ns;
		-- target 0
		wait until clk = '1';
		ip_header(x"0090f5de6431",
		          x"0037ffff3737",
		          x"c0a8012a",
		          x"c0a80101",
		          x"1230",
		          x"1230",
		          0,
		          16);
		          
		wait until clk = '1';
		mac_data32(x"12345678");
		wait until clk = '1';
		mac_data32(x"5500aa00");
		wait until clk = '1';
		mac_data32(x"ffffffff");
		wait until clk = '1';
		rd_flags_i(1) <= '1';
		mac_data32(x"00001111");
		rd_flags_i(1) <= '0';
		wait for 100 ns;
		-- wrong target mac
		wait until clk = '1';
		ip_header(x"0090f5de6431",
		          x"0037ffff3738",
		          x"c0a8012a",
		          x"c0a80101",
		          x"1230",
		          x"1230",
		          1,
		          16);
		          
		wait until clk = '1';
		mac_data32(x"12345678");
		wait until clk = '1';
		mac_data32(x"5500aa00");
		wait until clk = '1';
		mac_data32(x"ffffffff");
		wait until clk = '1';
		rd_flags_i(1) <= '1';
		mac_data32(x"00001111");
		rd_flags_i(1) <= '0';
		wait for 100 ns;
		-- target 1
		wait until clk = '1';
		ip_header(x"0090f5de6431",
		          x"0037ffff3737",
		          x"c0a8012a",
		          x"c0a80101",
		          x"1230",
		          x"1231",
		          0,
		          16);
		          
		wait until clk = '1';
		mac_data32(x"12345678");
		wait until clk = '1';
		mac_data32(x"5500aa00");
		wait until clk = '1';
		mac_data32(x"ffffffff");
		wait until clk = '1';
		rd_flags_i(1) <= '1';
		mac_data32(x"00001111");
		rd_flags_i(1) <= '0';
	
		wait for 100 ns;
		-- wrong target ip
		wait until clk = '1';
		ip_header(x"0090f5de6431",
		          x"0037ffff3737",
		          x"c0a8012a",
		          x"c0a80102",
		          x"1230",
		          x"1231",
		          1,
		          16);
		          
		wait until clk = '1';
		mac_data32(x"12345678");
		wait until clk = '1';
		mac_data32(x"5500aa00");
		wait until clk = '1';
		mac_data32(x"ffffffff");
		wait until clk = '1';
		rd_flags_i(1) <= '1';
		mac_data32(x"00001111");
		rd_flags_i(1) <= '0';
		
		wait for 100 ns;
		-- target 1
		wait until clk = '1';
		ip_header(x"0090f5de6431",
		          x"0037ffff3737",
		          x"c0a8012a",
		          x"c0a80101",
		          x"1230",
		          x"1231",
		          1,
		          16);
		          
		wait until clk = '1';
		mac_data32(x"12345678");
		wait until clk = '1';
		mac_data32(x"5500aa00");
		wait until clk = '1';
		mac_data32(x"ffffffff");
		wait until clk = '1';
		rd_flags_i(1) <= '1';
		mac_data32(x"00001111");
		rd_flags_i(1) <= '0';
		
		wait for 100 ns;
		-- wrong packet count
		wait until clk = '1';
		ip_header(x"0090f5de6431",
		          x"0037ffff3737",
		          x"c0a8012a",
		          x"c0a80101",
		          x"1230",
		          x"1231",
		          1,
		          16);
		          
		wait until clk = '1';
		mac_data32(x"12345678");
		wait until clk = '1';
		mac_data32(x"5500aa00");
		wait until clk = '1';
		mac_data32(x"ffffffff");
		wait until clk = '1';
		rd_flags_i(1) <= '1';
		mac_data32(x"00001111");
		rd_flags_i(1) <= '0';
		wait;
	end process; 
end architecture sim;
