library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Reg is
	port(
	-- Write Port 1 prioritaire
		wdata1			: in std_logic_vector(31 downto 0);
		wadr1			: in std_logic_vector(3 downto 0);
		wen1			: in std_logic;

	-- Write Port 2 non prioritaire
		wdata2			: in std_logic_vector(31 downto 0);
		wadr2			: in std_logic_vector(3 downto 0);
		wen2			: in std_logic;

	-- Write CSPR Port
		wcry			: in std_logic;
		wzero			: in std_logic;
		wneg			: in std_logic;
		wovr			: in std_logic;
		cspr_wb			: in std_logic;
		
	-- Read Port 1 32 bits
		rdata1			: out std_logic_vector(31 downto 0);
		radr1			: in std_logic_vector(3 downto 0);
		rvalid1			: out std_logic;

	-- Read Port 2 32 bits
		rdata2			: out std_logic_vector(31 downto 0);
		radr2			: in std_logic_vector(3 downto 0);
		rvalid2			: out std_logic;

	-- Read Port 3 5 bits (for shift)
		rdata3			: out std_logic_vector(31 downto 0);
		radr3			: in std_logic_vector(3 downto 0);
		rvalid3			: out std_logic;

	-- read CSPR Port
		cry				: out std_logic;
		zero			: out std_logic;
		neg				: out std_logic;
		ovr				: out std_logic;
		cznv			: out std_logic;
		vv				: out std_logic;
		
	-- Invalidate Port 
		inval_adr1		: in std_logic_vector(3 downto 0);
		inval1			: in std_logic;

		inval_adr2		: in std_logic_vector(3 downto 0);
		inval2			: in std_logic;

		inval_czn		: in std_logic;
		inval_ovr		: in std_logic;

	-- PC
		reg_pc			: out std_logic_vector(31 downto 0);
		reg_pcv			: out std_logic;
		inc_pc			: in std_logic;
		blink           : in std_logic;
	
	-- global interface
		ck				: in std_logic;
		reset_n			: in std_logic;
		vdd				: in bit;
		vss				: in bit);
end Reg;

architecture Behavior of Reg is
	signal r_valid  : std_logic_vector(15 downto 0);
	signal r_c		: std_logic;
	signal r_z		: std_logic;
	signal r_n		: std_logic;
	signal r_v		: std_logic;
	signal r_cznv	: std_logic;
	signal r_vv		: std_logic;

	signal r_pc		: std_logic_vector(31 downto 0);
	signal r_R14    : std_logic_vector(31 downto 0);
	signal r_R13    : std_logic_vector(31 downto 0);
	signal r_R12    : std_logic_vector(31 downto 0);
	signal r_R11    : std_logic_vector(31 downto 0);
	signal r_R10    : std_logic_vector(31 downto 0);
	signal r_R09    : std_logic_vector(31 downto 0);
	signal r_R08    : std_logic_vector(31 downto 0);
	signal r_R07    : std_logic_vector(31 downto 0);
	signal r_R06    : std_logic_vector(31 downto 0);
	signal r_R05    : std_logic_vector(31 downto 0);
	signal r_R04    : std_logic_vector(31 downto 0);
	signal r_R03    : std_logic_vector(31 downto 0);
	signal r_R02    : std_logic_vector(31 downto 0);
	signal r_R01    : std_logic_vector(31 downto 0);
	signal r_R00    : std_logic_vector(31 downto 0);

	signal pcp4     : std_logic_vector(31 downto 0);
begin

	pcp4 <= std_logic_vector(signed(r_pc) + 4);

	process (ck)
		variable inval_adr1_i : integer;
		variable inval_adr2_i : integer;
		variable w_adr1_i : integer;
		variable w_adr2_i : integer;
	begin
		if rising_edge(ck) then
			if reset_n='0' then
				r_valid <= x"FFFF";
				r_pc <= x"FFFFFFFC";
				r_cznv <= '1';
				r_vv <= '1';
			else
				-- R15 (PC)
				if wadr1=x"F" and wen1='1' and r_valid(15)='0' then
					r_pc  <= wdata1;
				elsif wadr2=x"F" and wen2='1' and r_valid(15)='0' then
					r_pc  <= wdata2;
				elsif inc_pc='1' then
					r_pc <= pcp4;
				end if;

				-- Validity bits
				
				-- R15_v
				if (inval_adr1=x"F" and inval1='1') or
				   (inval_adr2=x"F" and inval2='1') then r_valid(15) <= '0';
				elsif   (wadr1=x"F" and wen1='1') or
					    (wadr2=x"F" and wen2='1') then r_valid(15) <= '1';
				end if;
			
				-- R14_v
				if (inval_adr1=x"E" and inval1='1') or
				   (inval_adr2=x"E" and inval2='1') then r_valid(14) <= '0';
				elsif   (wadr1=x"E" and wen1='1') or
					    (wadr2=x"E" and wen2='1') then r_valid(14) <= '1';
				end if;
			
				-- R13_v
				if (inval_adr1=x"D" and inval1='1') or
				   (inval_adr2=x"D" and inval2='1') then r_valid(13) <= '0';
				elsif   (wadr1=x"D" and wen1='1') or
					    (wadr2=x"D" and wen2='1') then r_valid(13) <= '1';
				end if;
			
				-- R12_v
				if (inval_adr1=x"C" and inval1='1') or
				   (inval_adr2=x"C" and inval2='1') then r_valid(12) <= '0';
				elsif   (wadr1=x"C" and wen1='1') or
					    (wadr2=x"C" and wen2='1') then r_valid(12) <= '1';
				end if;
			
				-- R11_v
				if (inval_adr1=x"B" and inval1='1') or
				   (inval_adr2=x"B" and inval2='1') then r_valid(11) <= '0';
				elsif   (wadr1=x"B" and wen1='1') or
					    (wadr2=x"B" and wen2='1') then r_valid(11) <= '1';
				end if;
			
				-- R10_v
				if (inval_adr1=x"A" and inval1='1') or
				   (inval_adr2=x"A" and inval2='1') then r_valid(10) <= '0';
				elsif   (wadr1=x"A" and wen1='1') or
					    (wadr2=x"A" and wen2='1') then r_valid(10) <= '1';
				end if;
			
				-- R09_v
				if (inval_adr1=x"9" and inval1='1') or
				   (inval_adr2=x"9" and inval2='1') then r_valid(9) <= '0';
				elsif   (wadr1=x"9" and wen1='1') or
					    (wadr2=x"9" and wen2='1') then r_valid(9) <= '1';
				end if;
			
				-- R08_v
				if (inval_adr1=x"8" and inval1='1') or
				   (inval_adr2=x"8" and inval2='1') then r_valid(8) <= '0';
				elsif   (wadr1=x"8" and wen1='1') or
					    (wadr2=x"8" and wen2='1') then r_valid(8) <= '1';
				end if;
			
				-- R07_v
				if (inval_adr1=x"7" and inval1='1') or
				   (inval_adr2=x"7" and inval2='1') then r_valid(7) <= '0';
				elsif   (wadr1=x"7" and wen1='1') or
					    (wadr2=x"7" and wen2='1') then r_valid(7) <= '1';
				end if;
			
				-- R06_v
				if (inval_adr1=x"6" and inval1='1') or
				   (inval_adr2=x"6" and inval2='1') then r_valid(6) <= '0';
				elsif   (wadr1=x"6" and wen1='1') or
					    (wadr2=x"6" and wen2='1') then r_valid(6) <= '1';
				end if;
			
				-- R05_v
				if (inval_adr1=x"5" and inval1='1') or
				   (inval_adr2=x"5" and inval2='1') then r_valid(5) <= '0';
				elsif   (wadr1=x"5" and wen1='1') or
					    (wadr2=x"5" and wen2='1') then r_valid(5) <= '1';
				end if;
			
				-- R04_v
				if (inval_adr1=x"4" and inval1='1') or
				   (inval_adr2=x"4" and inval2='1') then r_valid(4) <= '0';
				elsif   (wadr1=x"4" and wen1='1') or
					    (wadr2=x"4" and wen2='1') then r_valid(4) <= '1';
				end if;
			
				-- R03_v
				if (inval_adr1=x"3" and inval1='1') or
				   (inval_adr2=x"3" and inval2='1') then r_valid(3) <= '0';
				elsif   (wadr1=x"3" and wen1='1') or
					    (wadr2=x"3" and wen2='1') then r_valid(3) <= '1';
				end if;
			
				-- R02_v
				if (inval_adr1=x"2" and inval1='1') or
				   (inval_adr2=x"2" and inval2='1') then r_valid(2) <= '0';
				elsif   (wadr1=x"2" and wen1='1') or
					    (wadr2=x"2" and wen2='1') then r_valid(2) <= '1';
				end if;
			
				-- R01_v
				if (inval_adr1=x"1" and inval1='1') or
				   (inval_adr2=x"1" and inval2='1') then r_valid(1) <= '0';
				elsif   (wadr1=x"1" and wen1='1') or
					    (wadr2=x"1" and wen2='1') then r_valid(1) <= '1';
				end if;
			
				-- R00_v
				if (inval_adr1=x"0" and inval1='1') or
				   (inval_adr2=x"0" and inval2='1') then r_valid(0) <= '0';
				elsif   (wadr1=x"0" and wen1='1') or
					    (wadr2=x"0" and wen2='1') then r_valid(0) <= '1';
				end if;

				if inval_czn='1' then
					r_cznv <= '0';
				end if;
			
				if inval_ovr='1' then
					r_vv   <= '0';
				end if;
			
				-- Write CSPR port
				if cspr_wb='1' then
					if r_cznv='0' then
						r_c <= wcry;
						r_z <= wzero;
						r_n <= wneg;
						r_cznv <= '1';
					end if;
					if r_vv='0' then
						r_v <= wovr;
						r_vv <= '1';
					end if;
				end if;
			end if;

			-- R14 (LR)
			if blink='1' then
				r_R14 <= r_pc;
			elsif wadr1=x"E" and wen1='1' and r_valid(14)='0' then
				r_R14 <= wdata1;
			elsif wadr2=x"E" and wen2='1' and r_valid(14)='0' then
				r_R14 <= wdata2;
			end if;

			-- R13 (SP)
			if wadr1=x"D" and wen1='1' and r_valid(13)='0' then
				r_R13 <= wdata1;
			elsif wadr2=x"D" and wen2='1' and r_valid(13)='0' then
				r_R13 <= wdata2;
			end if;

			-- R12
			if wadr1=x"C" and wen1='1' and r_valid(12)='0' then
				r_R12 <= wdata1;
			elsif wadr2=x"C" and wen2='1' and r_valid(12)='0' then
				r_R12 <= wdata2;
			end if;

			-- R11
			if wadr1=x"B" and wen1='1' and r_valid(11)='0' then
				r_R11 <= wdata1;
			elsif wadr2=x"B" and wen2='1' and r_valid(11)='0' then
				r_R11 <= wdata2;
			end if;

			-- R10
			if wadr1=x"A" and wen1='1' and r_valid(10)='0' then
				r_R10 <= wdata1;
			elsif wadr2=x"A" and wen2='1' and r_valid(10)='0' then
				r_R10 <= wdata2;
			end if;

			-- R09
			if wadr1=x"9" and wen1='1' and r_valid(9)='0' then
				r_R09 <= wdata1;
			elsif wadr2=x"9" and wen2='1' and r_valid(9)='0' then
				r_R09 <= wdata2;
			end if;

			-- R08
			if wadr1=x"8" and wen1='1' and r_valid(8)='0' then
				r_R08 <= wdata1;
			elsif wadr2=x"8" and wen2='1' and r_valid(8)='0' then
				r_R08 <= wdata2;
			end if;

			-- R07
			if wadr1=x"7" and wen1='1' and r_valid(7)='0' then
				r_R07 <= wdata1;
			elsif wadr2=x"7" and wen2='1' and r_valid(7)='0' then
				r_R07 <= wdata2;
			end if;

			-- R06
			if wadr1=x"6" and wen1='1' and r_valid(6)='0' then
				r_R06 <= wdata1;
			elsif wadr2=x"6" and wen2='1' and r_valid(6)='0' then
				r_R06 <= wdata2;
			end if;

			-- R05
			if wadr1=x"5" and wen1='1' and r_valid(5)='0' then
				r_R05 <= wdata1;
			elsif wadr2=x"5" and wen2='1' and r_valid(5)='0' then
				r_R05 <= wdata2;
			end if;

			-- R04
			if wadr1=x"4" and wen1='1' and r_valid(4)='0' then
				r_R04 <= wdata1;
			elsif wadr2=x"4" and wen2='1' and r_valid(4)='0' then
				r_R04 <= wdata2;
			end if;

			-- R03
			if wadr1=x"3" and wen1='1' and r_valid(3)='0' then
				r_R03 <= wdata1;
			elsif wadr2=x"3" and wen2='1' and r_valid(3)='0' then
				r_R03 <= wdata2;
			end if;

			-- R02
			if wadr1=x"2" and wen1='1' and r_valid(2)='0' then
				r_R02 <= wdata1;
			elsif wadr2=x"2" and wen2='1' and r_valid(2)='0' then
				r_R02 <= wdata2;
			end if;

			-- R01
			if wadr1=x"1" and wen1='1' and r_valid(1)='0' then
				r_R01 <= wdata1;
			elsif wadr2=x"1" and wen2='1' and r_valid(1)='0' then
				r_R01 <= wdata2;
			end if;

			-- R00
			if wadr1=x"0" and wen1='1' and r_valid(0)='0' then
				r_R00 <= wdata1;
			elsif wadr2=x"0" and wen2='1' and r_valid(0)='0' then
				r_R00 <= wdata2;
			end if;
		end if;
	end process;

	-- Read registers ports
	rvalid1 <= '1'         when radr1=wadr1 and wen1='1' else
			   '1'         when radr1=wadr2 and wen2='1' else
			   r_valid(0)  when radr1=x"0" else
			   r_valid(1)  when radr1=x"1" else
			   r_valid(2)  when radr1=x"2" else
			   r_valid(3)  when radr1=x"3" else
			   r_valid(4)  when radr1=x"4" else
			   r_valid(5)  when radr1=x"5" else
			   r_valid(6)  when radr1=x"6" else
			   r_valid(7)  when radr1=x"7" else
			   r_valid(8)  when radr1=x"8" else
			   r_valid(9)  when radr1=x"9" else
			   r_valid(10) when radr1=x"A" else
			   r_valid(11) when radr1=x"B" else
			   r_valid(12) when radr1=x"C" else
			   r_valid(13) when radr1=x"D" else
			   r_valid(14) when radr1=x"E" else
			   r_valid(15) when radr1=x"F" else
			   '1';
	rdata1  <= wdata1 when radr1=wadr1 and wen1='1' and r_valid(to_integer(unsigned(wadr1)))='0' else
			   wdata2 when radr1=wadr2 and wen2='1' and r_valid(to_integer(unsigned(wadr2)))='0' else
			   r_R00  when radr1=x"0" else
			   r_R01  when radr1=x"1" else
			   r_R02  when radr1=x"2" else
			   r_R03  when radr1=x"3" else
			   r_R04  when radr1=x"4" else
			   r_R05  when radr1=x"5" else
			   r_R06  when radr1=x"6" else
			   r_R07  when radr1=x"7" else
			   r_R08  when radr1=x"8" else
			   r_R09  when radr1=x"9" else
			   r_R10  when radr1=x"A" else
			   r_R11  when radr1=x"B" else
			   r_R12  when radr1=x"C" else
			   r_R13  when radr1=x"D" else
			   r_R14  when radr1=x"E" else
			   pcp4   when radr1=x"F" else
			   x"00000000";

	rvalid2 <= '1'         when radr2=wadr1 and wen1='1' else
			   '1'         when radr2=wadr2 and wen2='1' else
			   r_valid(0)  when radr2=x"0" else
			   r_valid(1)  when radr2=x"1" else
			   r_valid(2)  when radr2=x"2" else
			   r_valid(3)  when radr2=x"3" else
			   r_valid(4)  when radr2=x"4" else
			   r_valid(5)  when radr2=x"5" else
			   r_valid(6)  when radr2=x"6" else
			   r_valid(7)  when radr2=x"7" else
			   r_valid(8)  when radr2=x"8" else
			   r_valid(9)  when radr2=x"9" else
			   r_valid(10) when radr2=x"A" else
			   r_valid(11) when radr2=x"B" else
			   r_valid(12) when radr2=x"C" else
			   r_valid(13) when radr2=x"D" else
			   r_valid(14) when radr2=x"E" else
			   r_valid(15) when radr2=x"F" else
			   '1';
	rdata2  <= wdata1 when radr2=wadr1 and wen1='1' and r_valid(to_integer(unsigned(wadr1)))='0' else
			   wdata2 when radr2=wadr2 and wen2='1' and r_valid(to_integer(unsigned(wadr2)))='0' else
			   r_R00  when radr2=x"0" else
			   r_R01  when radr2=x"1" else
			   r_R02  when radr2=x"2" else
			   r_R03  when radr2=x"3" else
			   r_R04  when radr2=x"4" else
			   r_R05  when radr2=x"5" else
			   r_R06  when radr2=x"6" else
			   r_R07  when radr2=x"7" else
			   r_R08  when radr2=x"8" else
			   r_R09  when radr2=x"9" else
			   r_R10  when radr2=x"A" else
			   r_R11  when radr2=x"B" else
			   r_R12  when radr2=x"C" else
			   r_R13  when radr2=x"D" else
			   r_R14  when radr2=x"E" else
			   pcp4   when radr2=x"F" else
			   x"00000000";

	rvalid3 <= '1'         when radr3=wadr1 and wen1='1' else
			   '1'         when radr3=wadr2 and wen2='1' else
			   r_valid(0)  when radr3=x"0" else
			   r_valid(1)  when radr3=x"1" else
			   r_valid(2)  when radr3=x"2" else
			   r_valid(3)  when radr3=x"3" else
			   r_valid(4)  when radr3=x"4" else
			   r_valid(5)  when radr3=x"5" else
			   r_valid(6)  when radr3=x"6" else
			   r_valid(7)  when radr3=x"7" else
			   r_valid(8)  when radr3=x"8" else
			   r_valid(9)  when radr3=x"9" else
			   r_valid(10) when radr3=x"A" else
			   r_valid(11) when radr3=x"B" else
			   r_valid(12) when radr3=x"C" else
			   r_valid(13) when radr3=x"D" else
			   r_valid(14) when radr3=x"E" else
			   r_valid(15) when radr3=x"F" else
			   '1';
	rdata3  <= wdata1 when radr3=wadr1 and wen1='1' and r_valid(to_integer(unsigned(wadr1)))='0' else
			   wdata2 when radr3=wadr2 and wen2='1' and r_valid(to_integer(unsigned(wadr2)))='0' else
			   r_R00  when radr3=x"0" else
			   r_R01  when radr3=x"1" else
			   r_R02  when radr3=x"2" else
			   r_R03  when radr3=x"3" else
			   r_R04  when radr3=x"4" else
			   r_R05  when radr3=x"5" else
			   r_R06  when radr3=x"6" else
			   r_R07  when radr3=x"7" else
			   r_R08  when radr3=x"8" else
			   r_R09  when radr3=x"9" else
			   r_R10  when radr3=x"A" else
			   r_R11  when radr3=x"B" else
			   r_R12  when radr3=x"C" else
			   r_R13  when radr3=x"D" else
			   r_R14  when radr3=x"E" else
			   pcp4   when radr3=x"F" else
			   x"00000000";

	-- Read CSPR Port
	cznv <= '1' when cspr_wb='1' else
			r_cznv;
	cry  <= wcry  when cspr_wb='1' and r_cznv='0' else r_c;
	zero <= wzero when cspr_wb='1' and r_cznv='0' else r_z;
	neg	 <= wneg  when cspr_wb='1' and r_cznv='0' else r_n;

	vv   <= '1' when cspr_wb='1' else
			r_vv;
	ovr	 <= wovr when cspr_wb='1' and r_vv='0' else r_v;

	-- PC register
	reg_pcv <= '1' when (wadr1=x"F" and wen1='1') or (wadr2=x"F" and wen2='1') else
			   r_valid(15);
	reg_pc  <= wdata1 when wadr1=x"F" and wen1='1' and r_valid(15)='0' else
			   wdata2 when wadr2=x"F" and wen2='1' and r_valid(15)='0' else
			   pcp4;
end Behavior;
