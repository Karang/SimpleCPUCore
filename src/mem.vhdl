library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Mem is
	port(
	-- Exe interface
			exe2mem_empty	: in std_logic;
			mem_pop			: out std_logic;
			exe_mem_adr		: in std_logic_vector(31 downto 0);
			exe_mem_data	: in std_logic_vector(31 downto 0);
			exe_mem_dest	: in std_logic_vector(3 downto 0);

			exe_mem_lw		: in std_logic;
			exe_mem_lb		: in std_logic;
			exe_mem_sw		: in std_logic;
			exe_mem_sb		: in std_logic;

	-- Mem WB
			mem_res			: out std_logic_vector(31 downto 0);
			mem_dest			: out std_logic_vector(3 downto 0);
			mem_wb			: out std_logic;
			
	-- Dcache interface
			mem_adr			: out std_logic_vector(31 downto 0);
			mem_stw			: out std_logic;
			mem_stb			: out std_logic;
			mem_load			: out std_logic;

			mem_data			: out std_logic_vector(31 downto 0);
			dc_data			: in std_logic_vector(31 downto 0);
			dc_stall			: in std_logic;

	-- global interface
			ic_stall			: in std_logic;
			vdd				: in bit;
			vss				: in bit);
end Mem;

----------------------------------------------------------------------

architecture Behavior of Mem is
	signal lb_data : std_logic_vector(31 downto 0);
begin

	with exe_mem_adr(1 downto 0) select
		lb_data <=	x"000000" & dc_data(31 downto 24)	when "11",
						x"000000" & dc_data(23 downto 16)	when "10",
						x"000000" & dc_data(15 downto 8)		when "01",
						x"000000" & dc_data(7 downto 0)		when others;

	mem_res	<= lb_data when exe_mem_lb='1' else dc_data;
	mem_dest <= exe_mem_dest;
	mem_wb   <= '1' when (exe_mem_lw='1' or exe_mem_lb='1') and
					exe2mem_empty='0' and dc_stall='0' else '0';
			
	mem_adr <= exe_mem_adr(31 downto 2) & "00" when exe_mem_lw='1' or exe_mem_lb='1' else
			     exe_mem_adr;

	mem_stw  <= '1' when exe2mem_empty='0' and exe_mem_sw='1' else '0';
	mem_stb  <= '1' when exe2mem_empty='0' and exe_mem_sb='1' else '0';
	mem_load <= '1' when exe2mem_empty='0' and (exe_mem_lw='1' or exe_mem_lb='1') else '0';

	mem_data <= exe_mem_data;

	mem_pop <= '1' when exe2mem_empty='0' and dc_stall='0' and ic_stall='0' else '0';
end Behavior;
