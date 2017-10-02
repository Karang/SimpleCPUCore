library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.all;

entity ICache is
	port(
	-- Icache interface
		if_adr							: in  std_logic_vector(31 downto 0);
		if_adr_valid					: in  std_logic;
		ic_inst							: out std_logic_vector(31 downto 0);
		ic_inst_valid					: out std_logic;
		ic_stall							: out std_logic;
		dec_pop                    : in std_logic;
		
	-- Avalon-mm Master interface
		avm_icache_waitrequest 		: in  std_logic;
		avm_icache_readdatavalid	: in  std_logic;
		avm_icache_readdata 			: in  std_logic_vector(31 downto 0);
		avm_icache_read				: out std_logic;
		avm_icache_burstcount		: out std_logic_vector(3 downto 0);
		avm_icache_address			: out std_logic_vector(31 downto 0);
		
	-- global interface
		ck									: in std_logic;
		reset_n							: in std_logic;
		vdd								: in bit;
		vss								: in bit);
end ICache;

architecture behavioral of ICache is
	signal r_address 		: std_logic_vector(29 downto 0); -- cpu address without 2 lsb
	signal r_valid  		: std_logic;
	signal r_burstoffset : std_logic_vector(2 downto 0);
	
	-- tag and valid bit
	signal s_vtag_in     : std_logic_vector(20 downto 0); -- TAG_WIDTH + 1
	signal s_vtag_out    : std_logic_vector(20 downto 0); -- TAG_WIDTH + 1
	
	-- signals to the tag and data srams
	signal s_data_wren   : std_logic;
	signal s_data_rdaddr : std_logic_vector(9 downto 0); -- 10 bits address
	signal s_data_wraddr : std_logic_vector(9 downto 0); -- 10 bits address
	
	signal s_tag_wren    : std_logic;
	signal s_tag_rdaddr  : std_logic_vector(6 downto 0); -- 7 bits address log2(SET_COUNT) (128 sets = 4096/32)
	signal s_tag_wraddr  : std_logic_vector(6 downto 0); -- 7 bits address
	
	signal s_addr_stall  : std_logic;
	signal s_miss        : std_logic;
	
	type state_type is (S_READY, S_WAIT, S_READ, S_DELAY);
	signal state : state_type;
	
	-- SRAM component declaration
	component altsyncram
		generic(
			address_reg_b								: string;
			clock_enable_input_a						: string;
			clock_enable_input_b						: string;
			clock_enable_output_a					: string;
			clock_enable_output_b					: string;
			intended_device_family					: string;
			lpm_type										: string;
			numwords_a									: natural;
			numwords_b									: natural;
			operation_mode								: string;
			outdata_aclr_b								: string;
			outdata_reg_b								: string;
			power_up_uninitialized					: string;
			read_during_write_mode_mixed_ports	: string;
			widthad_a									: natural;
			widthad_b									: natural;
			width_a										: natural;
			width_b										: natural;
			width_byteena_a 							: natural
		);
		port (
			addressstall_b : in  std_logic;
			wren_a  			: in  std_logic;
			clock0  			: in  std_logic;
			clock1  			: in  std_logic;
			address_a		: in  std_logic_vector(widthad_a-1 downto 0);
			address_b 		: in  std_logic_vector(widthad_b-1 downto 0);
			q_b       		: out std_logic_vector(width_b-1 downto 0);
			data_a    		: in  std_logic_vector(width_a-1 downto 0)
		);
	end component;
begin
	s_miss   <= '0' when r_valid='0' or s_vtag_in=s_vtag_out else '1';
	
	ic_stall <= s_miss;
	ic_inst_valid <= r_valid;
	
	-- fixed burstcount : 8 words (32 bits each)
	avm_icache_burstcount <= x"8"; -- BLOCK_SIZE / 4 = 8 words
	avm_icache_address    <= r_address(29 downto 3) & (4 downto 0 => '0');
	
	-- signals to the data and tag srams
	s_addr_stall  <= s_miss or (not dec_pop and r_valid);
	s_data_rdaddr <= if_adr(11 downto 2);
	s_data_wraddr <= r_address(9 downto 3) & r_burstoffset;
	s_tag_rdaddr  <= if_adr(11 downto 5);
	s_tag_wraddr  <= r_address(9 downto 3);
	
	s_data_wren   <= avm_icache_readdatavalid;
	
	-- s_vtag_in and s_tag_wren
	process(r_address, r_burstoffset, avm_icache_readdatavalid)
	begin
		s_tag_wren <= '0';
		s_vtag_in  <= r_address(29 downto 10) & '1'; -- tag (20 bits) + valid bit
		
		if r_burstoffset = "111" and avm_icache_readdatavalid = '1' then
			s_tag_wren <= '1';--not r_address(3);--
		end if;
	end process;

	process(ck, reset_n)
	begin
		if reset_n='0' then
			r_burstoffset	<= "000";
			state 			<= S_READY;
			r_valid  	   <= '0';
		elsif rising_edge(ck) then
			r_valid <= if_adr_valid;
			
			case state is
				when S_READY =>
					if s_miss = '1' then
						if avm_icache_waitrequest = '1' then
							state <= S_WAIT;
						else
							state <= S_READ;
						end if;
					else
						if if_adr_valid = '1' then
							r_address <= if_adr(31 downto 2);
						end if;
					end if;
					r_burstoffset <= "000";
					
				when S_WAIT =>
					if avm_icache_waitrequest = '0' then
						state <= S_READ;
					end if;
					
				when S_READ =>
					if avm_icache_readdatavalid = '1' then
						r_burstoffset <= std_logic_vector(signed(r_burstoffset) + 1);
						
						if r_burstoffset = "111" then
							state <= S_DELAY;
						end if;
					end if;
					
				when S_DELAY =>
					state <= S_READY;
					
			end case;
			
		end if;
	end process;
	
	process (state, s_miss)
	begin
		case state is 
			when S_READY =>
				avm_icache_read <= s_miss;
			when S_WAIT =>
				avm_icache_read <= '1';
			when others =>
				avm_icache_read <= '0';
		end case;
	end process;
	
	data_sram_i : altsyncram
		generic map(
			address_reg_b 								=> "CLOCK1",
			clock_enable_input_a 					=> "BYPASS",
			clock_enable_input_b						=> "BYPASS",
			clock_enable_output_a 					=> "BYPASS",
			clock_enable_output_b 					=> "BYPASS",
			intended_device_family 					=> "Cyclone IV E",
			lpm_type 									=> "altsyncram",
			numwords_a 									=> 1024, --CACHE_SIZE/4,
			numwords_b 									=> 1024, --CACHE_SIZE/4,
			operation_mode 							=> "DUAL_PORT",
			outdata_aclr_b 							=> "NONE",
			outdata_reg_b 								=> "UNREGISTERED",
			power_up_uninitialized 					=> "FALSE",
			read_during_write_mode_mixed_ports 	=> "DONT_CARE",
			widthad_a 									=> 10, --C_DATA_WADDR_BITWIDTH, -- log2(CACHE_SIZE/4)
			widthad_b 									=> 10, --C_DATA_WADDR_BITWIDTH, -- log2(CACHE_SIZE/4)
			width_a 										=> 32,
			width_b 										=> 32,
			width_byteena_a 							=> 1
		)
		port map(
			addressstall_b => s_addr_stall,
			wren_a 			=> s_data_wren,
			clock0 			=> ck,
			clock1 			=> ck,
			address_a 		=> s_data_wraddr,
			address_b 		=> s_data_rdaddr,
			data_a 			=> avm_icache_readdata, -- write from avalon bus
			q_b 				=> ic_inst -- read to cpu ifetch
		);
		
	tag_sram_i : altsyncram
		generic map(
			address_reg_b 								=> "CLOCK1",
			clock_enable_input_a 					=> "BYPASS",
			clock_enable_input_b						=> "BYPASS",
			clock_enable_output_a 					=> "BYPASS",
			clock_enable_output_b 					=> "BYPASS",
			intended_device_family 					=> "Cyclone IV E",
			lpm_type 									=> "altsyncram",
			numwords_a 									=> 128, --C_SET_COUNT,
			numwords_b 									=> 128, --C_SET_COUNT,
			operation_mode 							=> "DUAL_PORT",
			outdata_aclr_b 							=> "NONE",
			outdata_reg_b 								=> "UNREGISTERED",
			power_up_uninitialized 					=> "FALSE",
			read_during_write_mode_mixed_ports 	=> "DONT_CARE",
			widthad_a 									=> 7, --C_INDEX_BITWIDTH, -- log2(C_SET_COUNT)
			widthad_b 									=> 7, --C_INDEX_BITWIDTH, -- log2(C_SET_COUNT)
			width_a 										=> 21, -- TAG_WIDTH + 1
			width_b 										=> 21, -- TAG_WIDTH + 1
			width_byteena_a 							=> 1
		)
		port map(
			addressstall_b => s_addr_stall,
			wren_a 			=> s_tag_wren,
			clock0 			=> ck,
			clock1 			=> ck,
			address_a 		=> s_tag_wraddr,
			address_b 		=> s_tag_rdaddr,
			data_a 			=> s_vtag_in, 
			q_b 				=> s_vtag_out
		);
		
end behavioral;