library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IFetch is
	port(
	-- Icache interface
			if_adr			: out std_logic_vector(31 downto 0);
			if_adr_valid	: out std_logic;
			ic_inst			: in std_logic_vector(31 downto 0);
			ic_inst_valid  : in std_logic;

	-- Decode interface
			dec2if_empty	: in std_logic;
			if_pop			: out std_logic;
			dec_pc			: in std_logic_vector(31 downto 0);

			if_ir				: out std_logic_vector(31 downto 0);
			if2dec_empty	: out std_logic;
			dec_pop			: in std_logic;

	-- global interface
			ic_stall			: in std_logic;
			ck					: in std_logic;
			reset_n			: in std_logic;
			vdd				: in bit;
			vss				: in bit);
end IFetch;

----------------------------------------------------------------------

architecture Behavior of IFetch is

--component fifo
--	generic(WIDTH: positive);
--	port(
--		din		: in std_logic_vector(WIDTH-1 downto 0);
--		dout	: out std_logic_vector(WIDTH-1 downto 0);
--
--		-- commands
--		push	: in std_logic;
--		pop		: in std_logic;
--
--		-- flags
--		full	: out std_logic;
--		empty	: out std_logic;
--
--		reset_n	: in std_logic;
--		ck		   : in std_logic;
--		vdd		: in bit;
--		vss		: in bit
--	);
--end component;

--signal if2dec_push	: std_logic;
  signal if2dec_full	: std_logic;

begin

--	if2dec : fifo
--	generic map (WIDTH => 32)
--	port map (	din		=> ic_inst,
--				dout	=> if_ir,
--
--				push	=> if2dec_push,
--				pop		=> dec_pop,
--
--				empty	=> if2dec_empty,
--	    		full	=> if2dec_full,
--
--				reset_n	=> reset_n,
--				ck		=> ck,
--				vdd		=> vdd,
--				vss		=> vss);


	if_adr_valid <= '1' when dec2if_empty='0' else '0';
	if_pop <= '1' when dec2if_empty='0' and ic_stall='0' and if2dec_full='0' else '0';
	
	if2dec_empty <= not ic_inst_valid;
	if2dec_full <= '1' when ic_inst_valid='1' and dec_pop='0' else '0';
	
	--if2dec_push <= '1' when dec2if_empty='0' and ic_stall='0' and if2dec_full='0' else '0';
	
	if_adr <= dec_pc;
	if_ir  <= ic_inst;
end Behavior;
