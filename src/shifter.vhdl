library ieee;
use ieee.std_logic_1164.all;

entity Shifter is
    port ( op2			: in std_logic_vector(31 downto 0);
		   shift 		: in std_logic_vector(4 downto 0);
		   cin			: in std_logic;

		   res			: out std_logic_vector(31 downto 0);
		   cout			: out std_logic;

           cmd_lsl		: in std_logic;
           cmd_lsr		: in std_logic;
           cmd_asr		: in std_logic;
           cmd_ror		: in std_logic;
		   cmd_rrx		: in std_logic;  

		   vdd			: in bit;
		   vss			: in bit);
end Shifter;

architecture dataflow of Shifter is
	signal out_lsl  : std_logic_vector(32 downto 0); -- Carry out is MSB
	signal out_lsr  : std_logic_vector(32 downto 0); -- Carry out is LSB
	signal out_rrx  : std_logic_vector(32 downto 0); -- Carry out is LSB
	signal fill 	: std_logic_vector(31 downto 0);
begin
	
	fill <= op2 		when cmd_ror = '1' else -- rrx
			x"FFFFFFFF"	when cmd_asr = '1' and op2(31)='1' else
			x"00000000";
	
	with shift select
	out_lsl <= cin & op2								when b"00000",
			   op2(31 downto 0) & fill(0  downto 0)		when b"00001",
			   op2(30 downto 0) & fill(1  downto 0) 	when b"00010",
			   op2(29 downto 0) & fill(2  downto 0) 	when b"00011",
			   op2(28 downto 0) & fill(3  downto 0) 	when b"00100",
			   op2(27 downto 0) & fill(4  downto 0) 	when b"00101",
			   op2(26 downto 0) & fill(5  downto 0) 	when b"00110",
			   op2(25 downto 0) & fill(6  downto 0) 	when b"00111",
			   op2(24 downto 0) & fill(7  downto 0) 	when b"01000",
			   op2(23 downto 0) & fill(8  downto 0) 	when b"01001",
			   op2(22 downto 0) & fill(9  downto 0) 	when b"01010",
			   op2(21 downto 0) & fill(10 downto 0) 	when b"01011",
			   op2(20 downto 0) & fill(11 downto 0) 	when b"01100",
			   op2(19 downto 0) & fill(12 downto 0) 	when b"01101",
			   op2(18 downto 0) & fill(13 downto 0) 	when b"01110",
			   op2(17 downto 0) & fill(14 downto 0)		when b"01111",
			   op2(16 downto 0) & fill(15 downto 0)		when b"10000",
			   op2(15 downto 0) & fill(16 downto 0)		when b"10001",
			   op2(14 downto 0) & fill(17 downto 0)		when b"10010",
			   op2(13 downto 0) & fill(18 downto 0)		when b"10011",
			   op2(12 downto 0) & fill(19 downto 0)		when b"10100",
			   op2(11 downto 0) & fill(20 downto 0)		when b"10101",
			   op2(10 downto 0) & fill(21 downto 0)		when b"10110",
			   op2(9  downto 0) & fill(22 downto 0)		when b"10111",
			   op2(8  downto 0) & fill(23 downto 0)		when b"11000",
			   op2(7  downto 0) & fill(24 downto 0)		when b"11001",
			   op2(6  downto 0) & fill(25 downto 0)		when b"11010",
			   op2(5  downto 0) & fill(26 downto 0)		when b"11011",
			   op2(4  downto 0) & fill(27 downto 0)		when b"11100",
			   op2(3  downto 0) & fill(28 downto 0)		when b"11101",
			   op2(2  downto 0) & fill(29 downto 0)		when b"11110",
			   op2(1  downto 0) & fill(30 downto 0)		when b"11111",
			   cin & op2								when others; 
	
	with shift select
	out_lsr <= op2 & cin								when b"00000",
			   fill(0  downto 0) & op2(31 downto 0)		when b"00001",
			   fill(1  downto 0) & op2(31 downto 1)		when b"00010",
			   fill(2  downto 0) & op2(31 downto 2)		when b"00011",
			   fill(3  downto 0) & op2(31 downto 3)		when b"00100",
			   fill(4  downto 0) & op2(31 downto 4)		when b"00101",
			   fill(5  downto 0) & op2(31 downto 5)		when b"00110",
			   fill(6  downto 0) & op2(31 downto 6)		when b"00111",
			   fill(7  downto 0) & op2(31 downto 7)		when b"01000",
			   fill(8  downto 0) & op2(31 downto 8)		when b"01001",
			   fill(9  downto 0) & op2(31 downto 9)		when b"01010",
			   fill(10 downto 0) & op2(31 downto 10)	when b"01011",
			   fill(11 downto 0) & op2(31 downto 11)	when b"01100",
			   fill(12 downto 0) & op2(31 downto 12)	when b"01101",
			   fill(13 downto 0) & op2(31 downto 13)	when b"01110",
			   fill(14 downto 0) & op2(31 downto 14)	when b"01111",
			   fill(15 downto 0) & op2(31 downto 15)	when b"10000",
			   fill(16 downto 0) & op2(31 downto 16)	when b"10001",
			   fill(17 downto 0) & op2(31 downto 17)	when b"10010",
			   fill(18 downto 0) & op2(31 downto 18)	when b"10011",
			   fill(19 downto 0) & op2(31 downto 19)	when b"10100",
			   fill(20 downto 0) & op2(31 downto 20)	when b"10101",
			   fill(21 downto 0) & op2(31 downto 21)	when b"10110",
			   fill(22 downto 0) & op2(31 downto 22)	when b"10111",
			   fill(23 downto 0) & op2(31 downto 23)	when b"11000",
			   fill(24 downto 0) & op2(31 downto 24)	when b"11001",
			   fill(25 downto 0) & op2(31 downto 25)	when b"11010",
			   fill(26 downto 0) & op2(31 downto 26)	when b"11011",
			   fill(27 downto 0) & op2(31 downto 27)	when b"11100",
			   fill(28 downto 0) & op2(31 downto 28)	when b"11101",
			   fill(29 downto 0) & op2(31 downto 29)	when b"11110",
			   fill(30 downto 0) & op2(31 downto 30)	when b"11111",
			   op2 & cin								when others;
	
	out_rrx <= cin & op2;
	
	cout <= out_lsl(32) when cmd_lsl = '1' else
		    out_lsr(0)  when cmd_lsr = '1' or
		    			     cmd_asr = '1' or
		    			     cmd_ror = '1' else
		    out_rrx(0)  when cmd_rrx = '1' else
		    cin;
	
	res <= out_lsl(31 downto 0) when cmd_lsl = '1' else
		   out_lsr(32 downto 1) when cmd_lsr = '1' or
									 cmd_asr = '1' or
									 cmd_ror = '1' else
		   out_rrx(32 downto 1) when cmd_rrx = '1' else
		   op2;

end dataflow;


