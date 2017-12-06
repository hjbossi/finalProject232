library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;

entity lfsr is
	Port (	clk : in STD_LOGIC;
				reset : in STD_LOGIC;
				outp : out STD_LOGIC_VECTOR (3 downto 0));
end lfsr;

architecture Behavioral of lfsr is
	
	signal feedback : std_logic;
	signal out_reg : std_logic_vector(3 downto 0):="0000";
	signal slowclock : std_logic;
	signal counter	: unsigned(27 downto 0);
	
begin
	feedback <= not (out_reg(3) xor out_reg(2));
	
	process (clk,reset) -- change to slowclock if you want to make it slower
	begin
		if (reset='1') then 
			out_reg <= "0000";
		elsif (rising_edge(clk)) then -- change to slowclock if you want to make it slower
			out_reg <= out_reg(2 downto 0) & feedback;
		end if;
	end process;
	
	process(clk, reset)
	begin
		if reset = '1' then
			counter <= "0000000000000000000000000000";
		elsif (rising_edge(clk)) then
			counter <= counter + 1;
		end if;
	end process;
	
	slowclock <= counter(23);
	
	outp <= out_reg;
	
end Behavioral;
