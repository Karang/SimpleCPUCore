library ieee;
use ieee.std_logic_1164.all;

entity Exec is
	port (
	-- Decode interface synchro
			dec2exe_empty	: in std_logic;
			exe_pop			: out std_logic;

	-- Decode interface operands
			dec_op1			: in std_logic_vector(31 downto 0); -- first alu in
			dec_op2			: in std_logic_vector(31 downto 0); -- shifter input
			dec_exe_dest	: in std_logic_vector(3 downto 0); -- Rd destination
			dec_exe_wb		: in std_logic; -- Rd destination write back
			dec_flag_wb		: in std_logic; -- CSPR modifiy
			dec_pre_index	: in std_logic;

	-- Decode to mem interface 
			dec_mem_data	: in std_logic_vector(31 downto 0); -- data to MEM W
			dec_mem_dest	: in std_logic_vector(3 downto 0); -- Dest MEM R

			dec_mem_lw		: in std_logic;
			dec_mem_lb		: in std_logic;
			dec_mem_sw		: in std_logic;
			dec_mem_sb		: in std_logic;

	-- Shifter command
			dec_shift_lsl	: in std_logic;
			dec_shift_lsr	: in std_logic;
			dec_shift_asr	: in std_logic;
			dec_shift_ror	: in std_logic;
			dec_shift_rrx	: in std_logic;
			dec_shift_val	: in std_logic_vector(4 downto 0);
			dec_cy			: in std_logic;

	-- Alu operand selection
			dec_comp_op1	: in std_logic;
			dec_comp_op2	: in std_logic;
			dec_alu_cy 		: in std_logic;

	-- Alu command
			dec_alu_add		: in std_logic;
			dec_alu_and		: in std_logic;
			dec_alu_or		: in std_logic;
			dec_alu_xor		: in std_logic;

	-- Exe bypass to decod
			exe_res			: out std_logic_vector(31 downto 0);

			exe_c			: out std_logic;
			exe_v			: out std_logic;
			exe_n			: out std_logic;
			exe_z			: out std_logic;

			exe_dest		: out std_logic_vector(3 downto 0); -- Rd dest
			exe_wb			: out std_logic; -- Rd destination write back
			exe_flag_wb		: out std_logic; -- CSPR modifiy

	-- Mem interface
			exe_mem_adr		: out std_logic_vector(31 downto 0); -- Alu res
			exe_mem_data	: out std_logic_vector(31 downto 0);
			exe_mem_dest	: out std_logic_vector(3 downto 0);

			exe_mem_lw		: out std_logic;
			exe_mem_lb		: out std_logic;
			exe_mem_sw		: out std_logic;
			exe_mem_sb		: out std_logic;

			exe2mem_empty	: out std_logic;
			mem_pop			: in std_logic;

	-- global interface
			ic_stall			: in std_logic;
			ck				   : in std_logic;
			reset_n			: in std_logic;
			vdd				: in bit;
			vss				: in bit);
end Exec;

architecture dataflow of Exec is
	-- Declaration ALU
	component alu
	port (
		op1			: in std_logic_vector(31 downto 0);
        op2			: in std_logic_vector(31 downto 0);
        cin			: in std_logic;

        cmd_add		: in std_logic;
        cmd_and		: in std_logic;
        cmd_or		: in std_logic;
        cmd_xor		: in std_logic;

        res			: out std_logic_vector(31 downto 0);
        cout		: out std_logic;
        z			: out std_logic;
        n			: out std_logic;
        v			: out std_logic;
			  
		vdd			: in bit;
		vss			: in bit);
	end component;

	-- Declaration Shifter
	component shifter
	port (
		op2			: in std_logic_vector(31 downto 0);
		shift 		: in std_logic_vector(4 downto 0);
		cin			: in std_logic;

		res			: out std_logic_vector(31 downto 0);
		cout		   : out std_logic;

      cmd_lsl		: in std_logic;
      cmd_lsr		: in std_logic;
      cmd_asr		: in std_logic;
      cmd_ror		: in std_logic;
		cmd_rrx		: in std_logic;  

		vdd			: in bit;
		vss			: in bit);
	end component;

	-- Declaration FIFO
	component fifo
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
	
	-- Gestion de la fifo
	signal exe_push 	: std_logic;
	signal exe_full 	: std_logic;
	signal fifo_din 	: std_logic_vector(71 downto 0);
	signal fifo_dout	: std_logic_vector(71 downto 0);

	-- Sorties du shifter
	signal shifter_op2 	: std_logic_vector(31 downto 0);
	signal shifter_cy  	: std_logic;

	-- Opérandes en sortie des multiplexeur de complémentarité
	signal comp_op1		: std_logic_vector(31 downto 0);
	signal comp_op2		: std_logic_vector(31 downto 0);

	-- Sortie de l'ALU
	signal alu_res 		: std_logic_vector(31 downto 0);
	signal alu_cy		: std_logic;
	
	signal mux_res		: std_logic_vector(31 downto 0);
begin
	
	-- Instanciation ALU
	alu_0: alu
	port map (	op1 => comp_op1,
				op2 => comp_op2,
				cin => dec_alu_cy,

				res => alu_res,
				cout => alu_cy,
				z => exe_z,
				n => exe_n,
				v => exe_v,
				
				cmd_add => dec_alu_add,
				cmd_and => dec_alu_and,
				cmd_or => dec_alu_or,
				cmd_xor => dec_alu_xor,

				vdd => vdd,
				vss => vss);

	-- Instanciation Shifter
	shifter_0: shifter
	port map (	op2 => dec_op2,
				shift => dec_shift_val,
				cin => dec_cy,

				res => shifter_op2,
				cout => shifter_cy,

				cmd_lsl => dec_shift_lsl,
				cmd_lsr => dec_shift_lsr,
				cmd_asr => dec_shift_asr,
				cmd_ror => dec_shift_ror,
				cmd_rrx => dec_shift_rrx, 

				vdd => vdd,
				vss => vss);

	-- Instanciation FIFO
	fifo_0: fifo
	generic map ( WIDTH => 72)
	port map (	din => fifo_din,
				dout => fifo_dout,

				push => exe_push,
				full => exe_full,

				pop => mem_pop,
				empty => exe2mem_empty,
				
				reset_n => reset_n,
				ck => ck,		
				vdd => vdd,
				vss => vss);
	
	-- Préparation des opérandes
	comp_op1 <= not dec_op1 when dec_comp_op1 = '1' else dec_op1;
	comp_op2 <= not shifter_op2 when dec_comp_op2 = '1' else shifter_op2;

	-- Sortie de l'ALU
	exe_res <= alu_res;
	exe_c   <= alu_cy when dec_alu_add='1' else
               shifter_cy;
	mux_res <= alu_res when dec_pre_index='1' else
               dec_op1;

	exe_dest	<= dec_exe_dest;
	exe_wb  	<= dec_exe_wb;
	exe_flag_wb <= dec_flag_wb;

	-- Gestion des fifos
	exe_pop  <= (not exe_full) and (not dec2exe_empty) and (not ic_stall);
	exe_push <= (not exe_full) and (not dec2exe_empty) and (dec_mem_sb or dec_mem_sw or dec_mem_lb or dec_mem_lw) and (not ic_stall);

	fifo_din <= dec_mem_sb &
				dec_mem_sw &
				dec_mem_lb &
				dec_mem_lw &
				dec_mem_dest &
				dec_mem_data &
				mux_res;
	
	exe_mem_sb		<= fifo_dout(71);
	exe_mem_sw		<= fifo_dout(70);
	exe_mem_lb		<= fifo_dout(69);
	exe_mem_lw		<= fifo_dout(68);
	exe_mem_dest	<= fifo_dout(67 downto 64);
	exe_mem_data	<= fifo_dout(63 downto 32);
	exe_mem_adr		<= fifo_dout(31 downto 0);
	
end dataflow;


