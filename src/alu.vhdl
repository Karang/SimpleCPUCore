library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Alu is
    port ( op1			: in std_logic_vector(31 downto 0);
           op2			: in std_logic_vector(31 downto 0);
           cin			: in std_logic;

           cmd_add		: in std_logic;
           cmd_and		: in std_logic;
           cmd_or		: in std_logic;
           cmd_xor		: in std_logic;

           res			: out std_logic_vector(31 downto 0);
           cout			: out std_logic;
           z			: out std_logic;
           n			: out std_logic;
           v			: out std_logic;
			  
		   vdd			: in bit;
		   vss			: in bit);
end Alu;

architecture dataflow of Alu is
	signal cy_vec  : std_logic_vector(32 downto 0);
	signal out_add : std_logic_vector(32 downto 0);
	signal out_and : std_logic_vector(31 downto 0);
	signal out_or  : std_logic_vector(31 downto 0);
	signal out_xor : std_logic_vector(31 downto 0);
begin

	cy_vec  <= (32 downto 1 => '0') & cin;
	out_add <= std_logic_vector(
		signed('0' & op1) + signed('0' & op2) + signed(cy_vec)
	);
	out_and <= op1 and op2;
	out_or  <= op1 or  op2;
	out_xor <= op1 xor op2;
	
	res <= out_add(31 downto 0) when cmd_add = '1' else
		   out_and				when cmd_and = '1' else
		   out_or				when cmd_or  = '1' else
		   out_xor				when cmd_xor = '1' else
		   op2;
		   
	z <= '1' when out_add(31 downto 0) = x"00000000" else '0';
	cout <= out_add(32);
	n <= out_add(31);
	
	v <= ((not op1(31)) and (not op2(31)) and      out_add(31)) or
		  (    op1(31)  and      op2(31)  and (not out_add(31)));
	
end dataflow;


