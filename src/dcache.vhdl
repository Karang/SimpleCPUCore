library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DCache is
	port(
	-- Dcache interface
		mem_adr						 : in  std_logic_vector(31 downto 0);
		mem_stw						 : in  std_logic;
		mem_stb						 : in  std_logic;
		mem_load						 : in  std_logic;
		mem_data						 : in  std_logic_vector(31 downto 0);
		dc_data						 : out std_logic_vector(31 downto 0);
		dc_stall						 : out std_logic;
		
	-- Avalon-mm Master interface
		avm_dcache_waitrequest   : in  std_logic;
		avm_dcache_readdatavalid : in  std_logic;
		avm_dcache_readdata 		 : in  std_logic_vector(31 downto 0);
		avm_dcache_read          : out std_logic;
		avm_dcache_writedata     : out std_logic_vector(31 downto 0);
		avm_dcache_write         : out std_logic;
		avm_dcache_byteen        : out std_logic_vector(3 downto 0);
		avm_dcache_burstcount    : out std_logic_vector(4 downto 0);
		avm_dcache_address 		 : out std_logic_vector(31 downto 0);
		
	-- global interface
		ck								 : in  std_logic;
		reset_n						 : in  std_logic;
		vdd							 : in  bit;
		vss							 : in  bit);
end DCache;

architecture behavioral of DCache is
	function get_byteen(adr : std_logic_vector) return std_logic_vector is
	begin
		case adr(1 downto 0) is
			when "00"   => return "0001";
			when "01"   => return "0010";
			when "10"   => return "0100";
			when others => return "1000";
		end case;
	end;
	
	signal r_data_valid : std_logic;
	signal r_wait_request : std_logic;
	signal r_data : std_logic_vector(31 downto 0);
begin
	avm_dcache_burstcount <= "00001";

	-- Avalon master
	avm_dcache_address <= mem_adr(31 downto 2) & "00";
	process (reset_n, ck, avm_dcache_waitrequest, avm_dcache_readdatavalid, mem_load, mem_stb, mem_stw, mem_data, mem_adr)
	begin
		if reset_n='0' then
			avm_dcache_read  <= '0';
			avm_dcache_write <= '0';
			avm_dcache_writedata <= (others => '-');
			avm_dcache_byteen <= (others => '-');
			
			r_data <= (31 downto 0 => '0');
			r_data_valid <= '0';
			r_wait_request <= '1';
		elsif rising_edge(ck) then
			avm_dcache_read  <= '0';
			avm_dcache_write <= '0';
			avm_dcache_writedata <= (others => '-');
			avm_dcache_byteen <= (others => '-');
			dc_stall <= '1';
			
			if mem_load = '1' then
				avm_dcache_read   <= r_wait_request and avm_dcache_waitrequest;
				avm_dcache_write  <= '0';
				avm_dcache_byteen <= "1111";
				
				dc_stall <= not avm_dcache_readdatavalid;
				
				if avm_dcache_waitrequest='0' then
					r_wait_request <= '0';
				end if;
				
				if avm_dcache_readdatavalid='1' then
					r_data <= avm_dcache_readdata;
				end if;
				
			elsif mem_stw = '1' then
				avm_dcache_read      <= '0';
				avm_dcache_write     <= r_wait_request and avm_dcache_waitrequest;
				avm_dcache_byteen    <= "1111";
				avm_dcache_writedata <= mem_data;
				
				dc_stall <= avm_dcache_waitrequest;
				
				if avm_dcache_waitrequest='0' then
					r_wait_request <= '0';
				end if;
			elsif mem_stb = '1' then
				avm_dcache_read      <= '0';
				avm_dcache_write     <= r_wait_request and avm_dcache_waitrequest;
				avm_dcache_byteen    <= get_byteen(mem_adr);
				avm_dcache_writedata <= mem_data;
				
				dc_stall <= avm_dcache_waitrequest;
				
				if avm_dcache_waitrequest='0' then
					r_wait_request <= '0';
				end if;
			else
				r_wait_request <= '1';
			end if;
			
			r_data_valid <= avm_dcache_readdatavalid;
			
		end if;
	end process;

	dc_data <= r_data;
	
end behavioral;