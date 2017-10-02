library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decod is
	port(
	-- Exec  operands
		dec_op1			: out std_logic_vector(31 downto 0); -- first alu input
		dec_op2			: out std_logic_vector(31 downto 0); -- shifter input
		dec_exe_dest	: out std_logic_vector(3 downto 0); -- Rd destination
		dec_exe_wb		: out std_logic; -- Rd destination write back
		dec_flag_wb		: out std_logic; -- CSPR modifiy

	-- Decod to mem via exec
		dec_mem_data	: out std_logic_vector(31 downto 0); -- data to MEM
		dec_mem_dest	: out std_logic_vector(3 downto 0);
		dec_pre_index 	: out std_logic;

		dec_mem_lw		: out std_logic;
		dec_mem_lb		: out std_logic;
		dec_mem_sw		: out std_logic;
		dec_mem_sb		: out std_logic;

	-- Shifter command
		dec_shift_lsl	: out std_logic;
		dec_shift_lsr	: out std_logic;
		dec_shift_asr	: out std_logic;
		dec_shift_ror	: out std_logic;
		dec_shift_rrx	: out std_logic;
		dec_shift_val	: out std_logic_vector(4 downto 0);
		dec_cy			: out std_logic;

	-- Alu operand selection
		dec_comp_op1	: out std_logic;
		dec_comp_op2	: out std_logic;
		dec_alu_cy 		: out std_logic;

	-- Exec Synchro
		dec2exe_empty	: out std_logic;
		exe_pop			: in std_logic;

	-- Alu command
		dec_alu_add		: out std_logic;
		dec_alu_and		: out std_logic;
		dec_alu_or		: out std_logic;
		dec_alu_xor		: out std_logic;

	-- Exe Write Back to reg
		exe_res			: in std_logic_vector(31 downto 0);

		exe_c			: in std_logic;
		exe_v			: in std_logic;
		exe_n			: in std_logic;
		exe_z			: in std_logic;

		exe_dest		: in std_logic_vector(3 downto 0); -- Rd destination
		exe_wb			: in std_logic; -- Rd destination write back
		exe_flag_wb		: in std_logic; -- CSPR modifiy

	-- Ifetch interface
		dec_pc			: out std_logic_vector(31 downto 0) ;
		if_ir			: in std_logic_vector(31 downto 0) ;

	-- Ifetch synchro
		dec2if_empty	: out std_logic;
		if_pop			: in std_logic;

		if2dec_empty	: in std_logic;
		dec_pop			: out std_logic;

	-- Mem Write back to reg
		mem_res			: in std_logic_vector(31 downto 0);
		mem_dest		: in std_logic_vector(3 downto 0);
		mem_wb			: in std_logic;
			
	-- global interface
		ic_stall			: in std_logic;
		ck				   : in std_logic;
		reset_n			: in std_logic;
		vdd				: in bit;
		vss				: in bit);
end Decod;

architecture Behavior of Decod is
component Reg
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
		blink          : in std_logic;
	
	-- global interface
		ck				   : in std_logic;
		reset_n			: in std_logic;
		vdd				: in bit;
		vss				: in bit);
	end component;

	component Fifo
	generic ( WIDTH : positive );
	port (
		din			: in std_logic_vector(WIDTH-1 downto 0);
		dout		: out std_logic_vector(WIDTH-1 downto 0);

		push		: in std_logic;
		pop			: in std_logic;

		full		: out std_logic;
		empty		: out std_logic;

		reset_n		: in std_logic;
		ck			: in std_logic;
		vdd			: in bit;
		vss			: in bit);
	end component;

	signal cond		 : std_logic;
	signal condv	 : std_logic;
	signal operv    : std_logic;
	signal op1v     : std_logic;
	signal op2v     : std_logic;
	signal op3v     : std_logic;

	signal regop_t  : std_logic;
	signal mult_t   : std_logic;
	signal swap_t   : std_logic;
	signal trans_t  : std_logic;
	signal mtrans_t : std_logic;
	signal branch_t : std_logic;

	-- regop instructions
	signal and_i  : std_logic;
	signal eor_i  : std_logic;
	signal sub_i  : std_logic;
	signal rsb_i  : std_logic;
	signal add_i  : std_logic;
	signal adc_i  : std_logic;
	signal sbc_i  : std_logic;
	signal rsc_i  : std_logic;
	signal tst_i  : std_logic;
	signal teq_i  : std_logic;
	signal cmp_i  : std_logic;
	signal cmn_i  : std_logic;
	signal orr_i  : std_logic;
	signal mov_i  : std_logic;
	signal bic_i  : std_logic;
	signal mvn_i  : std_logic;

	-- mult instruction
	signal mul_i  : std_logic;
	signal mla_i  : std_logic;

	-- trans instruction
	signal ldr_i  : std_logic;
	signal str_i  : std_logic;
	signal ldrb_i : std_logic;
	signal strb_i : std_logic;

	-- mtrans instruction
	signal ldm_i  : std_logic;
	signal stm_i  : std_logic;

	-- branch instruction
	signal b_i    : std_logic;
	signal bl_i   : std_logic;

	-- Multiple transferts
	signal mtrans_shift      : std_logic;
	
	signal mtrans_mask_shift : std_logic_vector(15 downto 0);
	signal mtrans_adr_dec    : std_logic_vector(4 downto 0);
	signal mtrans_adr_offset : std_logic_vector(31 downto 0);
	signal mtrans_mask       : std_logic_vector(15 downto 0);
	signal mtrans_list       : std_logic_vector(15 downto 0);
	signal mtrans_rd         : std_logic_vector(3 downto 0);
	signal dec_mem_dest_r    : std_logic_vector(3 downto 0);

	-- RF read ports
	signal rdata1 : std_logic_vector(31 downto 0);
	signal radr1  : std_logic_vector(3 downto 0);
	signal rvalid1 : std_logic;

	signal rdata2 : std_logic_vector(31 downto 0);
	signal radr2  : std_logic_vector(3 downto 0);
	signal rvalid2 : std_logic;

	signal rdata3 : std_logic_vector(31 downto 0);
	signal radr3  : std_logic_vector(3 downto 0);
	signal rvalid3 : std_logic;

	-- Flags
	signal cry	: std_logic;
	signal zero	: std_logic;
	signal neg	: std_logic;
	signal ovr	: std_logic;
	signal reg_cznv : std_logic;
	signal reg_vv : std_logic;

	-- PC
	signal reg_pc  : std_logic_vector(31 downto 0);
	signal reg_pcv : std_logic;
	signal inc_pc  : std_logic;

	-- Exec operands
	signal op1      : std_logic_vector(31 downto 0);
	signal op2      : std_logic_vector(31 downto 0);
	signal alu_dest : std_logic_vector(3 downto 0);
	signal alu_wb   : std_logic;
	signal flag_wb  : std_logic;

	-- Decod to mem via exe
	signal mem_data  : std_logic_vector(31 downto 0);
	signal ld_dest   : std_logic_vector(3 downto 0);
	signal pre_index : std_logic;

	signal mem_lw    : std_logic;
	signal mem_lb    : std_logic;
	signal mem_sw    : std_logic;
	signal mem_sb    : std_logic;

	-- Shifter command
	signal shift_lsl : std_logic;
	signal shift_lsr : std_logic;
	signal shift_asr : std_logic;
	signal shift_ror : std_logic;
	signal shift_rrx : std_logic;
	signal shift_val : std_logic_vector(4 downto 0);
	signal cy        : std_logic;

	-- Alu operand selection
	signal comp_op1 : std_logic;
	signal comp_op2 : std_logic;
	signal alu_cy   : std_logic;

	-- Alu command
	signal alu_add  : std_logic;
	signal alu_and  : std_logic;
	signal alu_or   : std_logic;
	signal alu_xor  : std_logic;

	-- Register bank
	signal wdata1, wdata2 : std_logic_vector(31 downto 0);
	signal wadr1, wadr2, inval_adr1, inval_adr2 : std_logic_vector(3 downto 0);
	signal wen1, wen2, wcry, wzero, wneg, wovr, cspr_wb : std_logic;
	signal inval1, inval2, inval_ovr, inval_czn : std_logic;

	-- Fifos
	signal dec2if_push		: std_logic;
	signal dec2if_full		: std_logic;
	signal dec2exe_push		: std_logic;
	signal dec2exe_full		: std_logic;
	signal fifo_din 		: std_logic_vector(128 downto 0);
	signal fifo_dout		: std_logic_vector(128 downto 0);

	-- DECOD FSM
	type state_type is (FETCH, RUN, BRANCH, MTRANS);
	signal cur_state, next_state : state_type;
	signal debug_fsm : std_logic_vector(4 downto 0);
begin
	reg_bank: Reg
	port map(	wdata1 => wdata1,
				wadr1 => wadr1,
				wen1 => wen1,

				wdata2 => wdata2,
				wadr2 => wadr2,
				wen2 => wen2,

				wcry => wcry,
				wzero => wzero, 
				wneg => wneg,
				wovr => wovr,
				cspr_wb	=> cspr_wb,
		
				rdata1 => rdata1,
				radr1 => radr1,
				rvalid1	=> rvalid1,

				rdata2 => rdata2,
				radr2 => radr2,
				rvalid2	=> rvalid2,

				rdata3 => rdata3,
				radr3 => radr3,
				rvalid3	=> rvalid3,

				cry	=> cry,
				zero => zero,
				neg	=> neg,
				ovr	=> ovr,
				cznv => reg_cznv,
				vv => reg_vv,
		
				inval_adr1 => inval_adr1,
				inval1 => inval1,

				inval_adr2 => inval_adr2,
				inval2 => inval2,

				inval_czn => inval_czn,
				inval_ovr => inval_ovr,

				reg_pc => reg_pc,
				reg_pcv => reg_pcv,
				inc_pc => inc_pc,
				blink => bl_i,

				ck => ck,
				reset_n	=> reset_n,
				vdd	=> vdd,
				vss => vss);

	dec2exec : Fifo
	generic map (WIDTH => 129)
	port map (	din => fifo_din,
				dout => fifo_dout,

				push => dec2exe_push,
				full => dec2exe_full,

				pop => exe_pop,
				empty => dec2exe_empty,
				
				reset_n => reset_n,
				ck => ck,		
				vdd => vdd,
				vss => vss);

	dec2if : Fifo
	generic map (WIDTH => 32)
	port map (	din => reg_pc,
				dout => dec_pc,

				push => dec2if_push,
				full => dec2if_full,

				pop => if_pop,
				empty => dec2if_empty,
				
				reset_n => reset_n,
				ck => ck,		
				vdd => vdd,
				vss => vss);

	-- Execution condition
	cond <= '1' when (if_ir(31 downto 28) = x"0" and zero = '1') or
					 (if_ir(31 downto 28) = x"1" and zero = '0') or
					 (if_ir(31 downto 28) = x"2" and cry = '1') or
					 (if_ir(31 downto 28) = x"3" and cry = '0') or
					 (if_ir(31 downto 28) = x"4" and neg = '1') or
					 (if_ir(31 downto 28) = x"5" and neg = '0') or
					 (if_ir(31 downto 28) = x"6" and ovr = '1') or
					 (if_ir(31 downto 28) = x"7" and ovr = '0') or
					 (if_ir(31 downto 28) = x"8" and (cry = '1' and zero = '0')) or
					 (if_ir(31 downto 28) = x"9" and (cry = '0' or zero = '1')) or
					 (if_ir(31 downto 28) = x"A" and (neg = ovr)) or
					 (if_ir(31 downto 28) = x"B" and (not (neg = ovr))) or
					 (if_ir(31 downto 28) = x"C" and (zero = '0' and neg = ovr)) or
					 (if_ir(31 downto 28) = x"D" and (zero = '1' or not(neg = ovr))) or
					 (if_ir(31 downto 28) = x"E") else
					 '0';

	condv <= '1' when (if_ir(31 downto 28) = x"0" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"1" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"2" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"3" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"4" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"5" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"6" and reg_vv = '1') or
					  (if_ir(31 downto 28) = x"7" and reg_vv = '1') or
					  (if_ir(31 downto 28) = x"8" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"9" and reg_cznv = '1') or
					  (if_ir(31 downto 28) = x"A" and reg_cznv = '1' and reg_vv = '1') or
					  (if_ir(31 downto 28) = x"B" and reg_cznv = '1' and reg_vv = '1') or
					  (if_ir(31 downto 28) = x"C" and reg_cznv = '1' and reg_vv = '1') or
					  (if_ir(31 downto 28) = x"D" and reg_cznv = '1' and reg_vv = '1') or
					  (if_ir(31 downto 28) = x"E") else
					  '0';

	-- Decod instruction type
	regop_t  <= '1' when if_ir(27 downto 26) = b"00" and (not (mult_t = '1')) and (not (swap_t = '1')) else '0';
	mult_t   <= '1' when if_ir(27 downto 22) = b"000000" and if_ir(7 downto 4) = b"1001" else '0';
	swap_t   <= '1' when if_ir(27 downto 23) = b"00010" and if_ir(7 downto 4) = b"1001" else '0';
	trans_t  <= '1' when if_ir(27 downto 26) = b"01" else '0';
	mtrans_t <= '1' when if_ir(27 downto 25) = b"100" else '0';
	branch_t <= '1' when if_ir(27 downto 25) = b"101" else '0';

	-- Decod regop opcode
	and_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"0" else '0';
	eor_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"1" else '0';
	sub_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"2" else '0';
	rsb_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"3" else '0';
	add_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"4" else '0';
	adc_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"5" else '0';
	sbc_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"6" else '0';
	rsc_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"7" else '0';
	tst_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"8" else '0';
	teq_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"9" else '0';
	cmp_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"A" else '0';
	cmn_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"B" else '0';
	orr_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"C" else '0';
	mov_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"D" else '0';
	bic_i 	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"E" else '0';
	mvn_i	<= '1' when regop_t = '1' and if_ir(24 downto 21) = x"F" else '0';

	-- Decod mult opcode
	mul_i	<= '1' when mult_t = '1' and if_ir(21) = '0' else '0';
	mla_i	<= '1' when mult_t = '1' and if_ir(21) = '1' else '0';

	-- Decod trans opcode
	ldr_i 	<= '1' when trans_t = '1' and if_ir(20) = '1' and if_ir(22) = '0' else '0';
	str_i 	<= '1' when trans_t = '1' and if_ir(20) = '0' and if_ir(22) = '0' else '0';
	ldrb_i	<= '1' when trans_t = '1' and if_ir(20) = '1' and if_ir(22) = '1' else '0';
	strb_i	<= '1' when trans_t = '1' and if_ir(20) = '0' and if_ir(22) = '1' else '0';

	-- Decod mtrans opcode
	ldm_i	<= '1' when mtrans_t = '1' and if_ir(20) = '1' else '0';
	stm_i	<= '1' when mtrans_t = '1' and if_ir(20) = '0' else '0';

	-- Decod branch opcode
	b_i		<= '1' when branch_t = '1' and if_ir(24) = '0' else '0';
	bl_i	<= '1' when branch_t = '1' and if_ir(24) = '1' else '0';

	-- Decod operands
	radr1 <= if_ir(19 downto 16);
	
	radr2 <= mtrans_rd when mtrans_t='1' else
			 if_ir(3 downto 0) when regop_t='1' and if_ir(25)='0' else
			 if_ir(3 downto 0) when trans_t='1' and if_ir(25)='1' else
			 "0000";
	
	radr3 <= if_ir(15 downto 12) when trans_t='1' else
			   if_ir(11 downto 8);
	
	op1 <= exe_res when mtrans_shift='1' else
		   rdata1 when (regop_t='1' and mov_i='0' and mvn_i='0') or trans_t='1' or mtrans_t='1' else
		   reg_pc when branch_t='1' else
		   x"00000000";

	op2 <= x"00000004" when mtrans_t='1' and (mtrans_shift='1' or if_ir(23)='1') else
		   mtrans_adr_offset when mtrans_t='1' and if_ir(23)='0' else
		   x"FF" & if_ir(23 downto 0) when branch_t='1' and if_ir(23)='1' else
		   x"00" & if_ir(23 downto 0) when branch_t='1' else
		   x"000000" & if_ir(7 downto 0) when regop_t='1' and if_ir(25)='1' else
		   x"00000" & if_ir(11 downto 0) when trans_t='1' and if_ir(25)='0' else
		   rdata2 when regop_t='1' or trans_t='1' else
		   x"00000000";
	
	op1v <= '1' when mtrans_shift='1' or mtrans_t='1' else
			rvalid1 when (regop_t='1' and mov_i='0' and mvn_i='0') or trans_t='1' or mtrans_t='1' else
			reg_pcv when branch_t='1' else
	        '1';
	        
	op2v <= '1' when (regop_t='1' and if_ir(25)='1') or (trans_t='1' and if_ir(25)='0') else
			rvalid2 when regop_t='1' or trans_t='1' else
			'1';
			
	op3v <= rvalid3 when trans_t='1' and (str_i='1' or strb_i='1') else
			rvalid3 when regop_t='1' and if_ir(25)='0' and if_ir(4)='1' else
			'1';
	
	operv <= op1v and op2v and op3v;

	alu_dest <= "1111" when branch_t='1' else
				if_ir(15 downto 12) when regop_t = '1' else
				if_ir(19 downto 16) when trans_t = '1' or mtrans_t = '1' else
				"0000";
	alu_wb   <= '0' when mtrans_shift='1' else
				'0' when cond='0' and condv='1' else
				if_ir(21) when trans_t = '1' or mtrans_t = '1' else
				'1' when regop_t='1' and tst_i='0' and teq_i='0' and cmp_i='0' and cmn_i='0' else
				'1' when branch_t='1' else
                '0';
	flag_wb  <= '0' when cond='0' and condv='1' else
				if_ir(20) or tst_i or teq_i or cmp_i or cmn_i when regop_t = '1' else
				'0';

	-- Inval reg
	inval_adr1 <= if_ir(15 downto 12) when regop_t='1' else
				  if_ir(19 downto 16) when trans_t='1' or mtrans_t='1' else
				  "1111" when branch_t='1' else
				  "0000";
	inval1 <= '0' when dec2exe_push='0' else
			  '0' when cond='0' and condv='1' else
              '0' when mtrans_shift='1' else
			  if_ir(21) when trans_t = '1' or mtrans_t='1' else
			  '1' when regop_t='1' and tst_i='0' and teq_i='0' and cmp_i='0' and cmn_i='0' else
			  '1' when branch_t='1' else
			  '0';

	inval_adr2 <= ld_dest when trans_t = '1' or mtrans_t = '1' else
                  "0000";
	inval2 <= '0' when dec2exe_push='0' else
			  '0' when mtrans_shift='1' and (mtrans_mask_shift and mtrans_mask and mtrans_list)=x"0000" else
			  '1' when mem_lw='1' or mem_lb='1' else
			  '0';

	inval_czn <= if_ir(20) or tst_i or teq_i or cmp_i or cmn_i when regop_t='1' else '0';
	inval_ovr <= if_ir(20) or tst_i or teq_i or cmp_i or cmn_i when regop_t='1' else '0';

	-- Exe writeback
	wadr1 <= exe_dest when exe_wb='1' else
             "0000";
    
	wdata1 <= std_logic_vector(signed(exe_res) - 4) when exe_wb='1' and mtrans_shift='1' and if_ir(24 downto 23)="00" else
			  std_logic_vector(signed(exe_res) - 4 + signed(mtrans_adr_offset)) when exe_wb='1' and mtrans_shift='1' and if_ir(23)='1' else
			  exe_res when exe_wb='1' else
              x"00000000";
	wen1 <= '1' when exe_wb='1' and if2dec_empty='0' else
            '0';

	wcry  <= exe_c;
	wzero <= exe_z;
	wneg  <= exe_n;
	wovr  <= exe_v;
	cspr_wb <= exe_flag_wb;

	-- Mem writeback
	wadr2 <= mem_dest when mem_wb='1' else
			 "0000";
	wdata2 <= mem_res when mem_wb='1' else
			  x"00000000";
	wen2 <= '1' when mem_wb='1' and if2dec_empty='0' else
			'0';

	-- Decod mem params
	mem_data  <= rdata2 when mtrans_t='1' and stm_i='1' else
				 rdata3 when trans_t='1' and (str_i='1' or strb_i='1') else
	             op1;
	ld_dest   <= mtrans_rd when mtrans_t='1' else
				 if_ir(15 downto 12);
	pre_index <= '1' when mtrans_t='1' and if_ir(23)='0' else
				 if_ir(24);

	mem_lw <= ldr_i or ldm_i;
	mem_lb <= ldrb_i;
	mem_sw <= str_i or stm_i;
	mem_sb <= strb_i;
	
	-- Multiple transferts
	mtrans_list <= x"0000" when mtrans_t='0' else
	               if_ir(15 downto 0);
	
	mtrans_adr_dec <= "11111" when if_ir(24 downto 23)="00" else
					  "00000";
	
	mtrans_adr_offset <= x"000000" & "0" &
						 std_logic_vector(signed'("0000" & mtrans_list(15)) +
						                  signed'("0000" & mtrans_list(14)) +
										  signed'("0000" & mtrans_list(13)) +
										  signed'("0000" & mtrans_list(12)) +
										  signed'("0000" & mtrans_list(11)) +
										  signed'("0000" & mtrans_list(10)) +
										  signed'("0000" & mtrans_list(9))  +
										  signed'("0000" & mtrans_list(8))  +
										  signed'("0000" & mtrans_list(7))  +
										  signed'("0000" & mtrans_list(6))  +
										  signed'("0000" & mtrans_list(5))  +
										  signed'("0000" & mtrans_list(4))  +
										  signed'("0000" & mtrans_list(3))  +
										  signed'("0000" & mtrans_list(2))  +
										  signed'("0000" & mtrans_list(1))  +
										  signed'("0000" & mtrans_list(0))  +
										  signed(mtrans_adr_dec)) & "00";						 

	mtrans_mask_shift <= x"0000" when mtrans_t='0' else
						 mtrans_mask and mtrans_list;
						 
	mtrans_mask       <= x"0000" when mtrans_t='0' else
						 x"FFFF" when mtrans_shift='0' else
						 "1111111111111110" when dec_mem_dest_r=x"0" else
						 "1111111111111100" when dec_mem_dest_r=x"1" else
						 "1111111111111000" when dec_mem_dest_r=x"2" else
						 "1111111111110000" when dec_mem_dest_r=x"3" else
						 "1111111111100000" when dec_mem_dest_r=x"4" else
						 "1111111111000000" when dec_mem_dest_r=x"5" else
						 "1111111110000000" when dec_mem_dest_r=x"6" else
						 "1111111100000000" when dec_mem_dest_r=x"7" else
						 "1111111000000000" when dec_mem_dest_r=x"8" else
						 "1111110000000000" when dec_mem_dest_r=x"9" else
						 "1111100000000000" when dec_mem_dest_r=x"A" else
						 "1111000000000000" when dec_mem_dest_r=x"B" else
						 "1110000000000000" when dec_mem_dest_r=x"C" else
						 "1100000000000000" when dec_mem_dest_r=x"D" else
						 "1000000000000000" when dec_mem_dest_r=x"E" else
						 "0000000000000000" when dec_mem_dest_r=x"F" else
						 x"FFFF";
						 
	mtrans_rd         <= x"0" when mtrans_t='0' else
	                     x"0" when mtrans_mask_shift(0)= '1' else
	                     x"1" when mtrans_mask_shift(1)= '1' else
	                     x"2" when mtrans_mask_shift(2)= '1' else
	                     x"3" when mtrans_mask_shift(3)= '1' else
	                     x"4" when mtrans_mask_shift(4)= '1' else
	                     x"5" when mtrans_mask_shift(5)= '1' else
	                     x"6" when mtrans_mask_shift(6)= '1' else
	                     x"7" when mtrans_mask_shift(7)= '1' else
	                     x"8" when mtrans_mask_shift(8)= '1' else
	                     x"9" when mtrans_mask_shift(9)= '1' else
	                     x"A" when mtrans_mask_shift(10)='1' else
	                     x"B" when mtrans_mask_shift(11)='1' else
	                     x"C" when mtrans_mask_shift(12)='1' else
	                     x"D" when mtrans_mask_shift(13)='1' else
	                     x"E" when mtrans_mask_shift(14)='1' else
	                     x"F" when mtrans_mask_shift(15)='1' else
	                     x"0";

	-- Decod shifter
	shift_lsl <= '1' when if_ir(6 downto 5)="00" and regop_t='1' and if_ir(25)='0' else
				 '1' when if_ir(6 downto 5)="00" and trans_t='1' and if_ir(25)='1' else
				 '1' when branch_t='1' else
				 '0';
	shift_lsr <= '1' when if_ir(6 downto 5)="01" and regop_t='1' and if_ir(25)='0' else
				 '1' when if_ir(6 downto 5)="01" and trans_t='1' and if_ir(25)='1' else
				 '0';
	shift_asr <= '1' when if_ir(6 downto 5)="10" and regop_t='1' and if_ir(25)='0' else
				 '1' when if_ir(6 downto 5)="10" and trans_t='1' and if_ir(25)='1' else
				 '0';
	shift_ror <= '1' when if_ir(6 downto 5)="11" and regop_t='1' and if_ir(25)='0' and shift_rrx='0' else
				 '1' when if_ir(6 downto 5)="11" and trans_t='1' and if_ir(25)='1' and shift_rrx='0' else
				 '1' when regop_t='1' and if_ir(25)='1' else
				 '0';
	shift_rrx <= '1' when if_ir(6 downto 5)="11" and regop_t='1' and if_ir(25)='0' and shift_val="00000" else
				 '1' when if_ir(6 downto 5)="11" and trans_t='1' and if_ir(25)='1' and shift_val="00000" else
				 '0';
	
	shift_val <= "00010" when branch_t='1' else
				 if_ir(11 downto 7)     when trans_t='1' and if_ir(25)='1' else
				 if_ir(11 downto 8)&'0' when regop_t='1' and if_ir(25)='1' else
				 if_ir(11 downto 7)     when regop_t='1' and if_ir(25)='0' and if_ir(4)='0' else
				 rdata3(4 downto 0)     when regop_t='1' and if_ir(25)='0' and if_ir(4)='1' else
				 "00000";
	cy <= cry;

	-- Decod alu operand selection
	comp_op1 <= rsb_i or rsc_i;
	comp_op2 <= '0' when mtrans_shift='1' else
				'1' when (trans_t='1' or mtrans_t='1') and if_ir(23)='0' else 
				sub_i or sbc_i or cmp_i or bic_i or mvn_i;
	alu_cy   <= '0' when mtrans_shift='1' else
				'1' when sub_i='1' or rsb_i='1' or cmp_i='1' else
				'1' when (trans_t='1' or mtrans_t='1') and if_ir(23)='0' else
				cry when adc_i='1' or sbc_i='1' or rsc_i='1' else
				'0';

	-- Decod alu command
	alu_add <= add_i or sub_i or rsb_i or adc_i or sbc_i or rsc_i or cmp_i or
	           cmn_i or branch_t or trans_t or mtrans_t;
	alu_and <= and_i or tst_i or bic_i;
	alu_or  <= orr_i;
	alu_xor <= eor_i or teq_i;

	-- Gestion des fifos
	fifo_din <= op1 & op2 & alu_dest & alu_wb & flag_wb & mem_data & ld_dest & pre_index &
				mem_lw & mem_lb & mem_sw & mem_sb & shift_lsl & shift_lsr & shift_asr &
				shift_ror & shift_rrx & shift_val & cy & comp_op1 & comp_op2 & alu_cy &
				alu_add & alu_and & alu_or & alu_xor;

	dec_op1			<= fifo_dout(128 downto 97);
	dec_op2			<= fifo_dout(96 downto 65);
	dec_exe_dest	<= fifo_dout(64 downto 61);
	dec_exe_wb		<= fifo_dout(60);
	dec_flag_wb		<= fifo_dout(59);
	dec_mem_data	<= fifo_dout(58 downto 27);
	dec_mem_dest_r	<= fifo_dout(26 downto 23);
	dec_pre_index 	<= fifo_dout(22);
	dec_mem_lw		<= fifo_dout(21);
	dec_mem_lb		<= fifo_dout(20);
	dec_mem_sw		<= fifo_dout(19);
	dec_mem_sb		<= fifo_dout(18);
	dec_shift_lsl	<= fifo_dout(17);
	dec_shift_lsr	<= fifo_dout(16);
	dec_shift_asr	<= fifo_dout(15);
	dec_shift_ror	<= fifo_dout(14);
	dec_shift_rrx	<= fifo_dout(13);
	dec_shift_val	<= fifo_dout(12 downto 8);
	dec_cy			<= fifo_dout(7);
	dec_comp_op1	<= fifo_dout(6);
	dec_comp_op2	<= fifo_dout(5);
	dec_alu_cy 		<= fifo_dout(4);
	dec_alu_add		<= fifo_dout(3);
	dec_alu_and		<= fifo_dout(2);
	dec_alu_or		<= fifo_dout(1);
	dec_alu_xor		<= fifo_dout(0);

	dec_mem_dest <= dec_mem_dest_r;
	inc_pc <= dec2if_push;

	-- FSM
	process(ck)
	begin
		if rising_edge(ck) then
			if reset_n = '0' then
				cur_state <= RUN;
			else
				cur_state <= next_state;
			end if;
		end if;
	end process;
	
	process(cur_state, dec2if_full, cond, condv, operv, dec2exe_full, if2dec_empty, reg_pcv, bl_i,
			branch_t, and_i, eor_i, sub_i, rsb_i, add_i, adc_i, sbc_i, rsc_i, orr_i, mov_i, bic_i,
			mvn_i, ldr_i, ldrb_i, ldm_i, stm_i, if_ir, mtrans_rd, mtrans_mask_shift, mtrans_mask,
			dec_mem_dest_r)
	begin
		next_state <= cur_state;
		
		case cur_state is
			when FETCH =>
				dec2if_push  <= (not dec2if_full) and reg_pcv and (not ic_stall);
				dec_pop      <= '0';
				dec2exe_push <= '0';
				mtrans_shift <= '0';
				
				if if2dec_empty='0' and dec2if_full='0' and reg_pcv='1' and ic_stall='0' then
					next_state <= RUN;
				end if;
				
				debug_fsm <= "00001";
			when RUN =>
				dec2if_push  <= (not dec2if_full) and reg_pcv and operv and (not ic_stall);
				dec_pop      <= (not if2dec_empty) and (not dec2exe_full) and operv and condv and (not ic_stall);
				dec2exe_push <= (not if2dec_empty) and (not dec2exe_full) and operv and condv and cond and (not ic_stall);
				mtrans_shift <= '0';
				
				if dec2if_full='1' and if2dec_empty='1' and ic_stall='0' then
					next_state <= FETCH;
				elsif dec2exe_full='0' and if2dec_empty='0' and ic_stall='0' then
					if operv='1' and cond='1' and condv='1' and reg_pcv='1' then
						if (branch_t = '1' or
						   ((and_i='1' or eor_i='1' or sub_i='1' or rsb_i='1' or
						     add_i='1' or adc_i='1' or sbc_i='1' or rsc_i='1' or
						     orr_i='1' or mov_i='1' or bic_i='1' or mvn_i='1' or
						     ldr_i='1' or ldrb_i='1') and if_ir(15 downto 12)=x"F"))
						then
							next_state  <= BRANCH;
							dec2if_push <= '0';
							dec_pop     <= '1';
						elsif ldm_i='1' or stm_i='1' then
							next_state  <= MTRANS;
							dec2if_push <= '0';
							dec_pop     <= '0';
						end if;
					end if;
				end if;
				
				debug_fsm <= "00010";
			when BRANCH =>
				dec2if_push  <= (not dec2if_full) and reg_pcv and (not ic_stall);
				dec_pop      <= (not ic_stall); --1
				dec2exe_push <= '0';
				mtrans_shift <= '0';
			
				if if2dec_empty='0' and dec2exe_full='0' and ic_stall='0' then
					if reg_pcv='1' then
						next_state <= RUN;
					else
						next_state <= FETCH;
					end if;
				end if;
				
				debug_fsm <= "00011";
			when MTRANS =>
				dec2if_push  <= '0';
				dec_pop      <= '0';
				dec2exe_push <= (not ic_stall);--'1';
				mtrans_shift <= '1';

				if (mtrans_mask_shift and mtrans_mask)=x"0000" and ic_stall='0' then
					dec2if_push  <= '1';
					dec_pop      <= '1';
					dec2exe_push <= '0';
				
					if ldm_i='1' and dec_mem_dest_r=x"F" then
						next_state <= BRANCH;
						dec2if_push <= '0';
						dec_pop     <= '1';
					else
						next_state <= RUN;
					end if;
				end if;
				
				debug_fsm <= "00100";
		end case;
	end process;
end Behavior;
