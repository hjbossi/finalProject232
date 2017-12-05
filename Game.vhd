-- Matt Jones
-- Fall 2017
-- Project 9 - game.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

entity game is

	port(
		clk		: in	std_logic;
		input	: in	std_logic;
		b1  : in std_logic; -- start
		player1	: in std_logic;
		player2	: in std_logic;
		player3	: in std_logic;
		player4	: in std_logic;
		reset	: in	std_logic;
		output	: out	std_logic_vector(1 downto 0)
	);

end entity;

architecture rtl of game is

	-- Build an enumerated type for the state machine
	type state_type is (sIdle, sWait, sPlay, sEnd);

	-- Register to hold the current state
	signal state   : state_type;
	signal counter : std_logic_vector(2 downto 0);
	signal ra		: std_logic_vector(3 downto 0);
	signal rb		: std_logic_vector(3 downto 0);
	signal rc		: std_logic_vector(3 downto 0);
	signal rd		: std_logic_vector(3 downto 0);
	signal re		: std_logic_vector(3 downto 0);

begin

	-- Logic to advance to the next state
	process (clk, reset)
	begin
		if reset = '1' then
			state <= sIdle;
			counter <= "011";
			ra <= "0000";
			rb <= "0000";
			rc <= "0000";
			rd <= "0000";
			re <= "1111";
		elsif (rising_edge(clk)) then
			case state is
				when sIdle=>
					if b1 = '1' then
						state <= sWait;
					end if;
				when sWait=>
					if counter <= "000" then
						state <= sPlay;
					else
						counter <= unsigned(counter) - 1;
					end if;
				when sPlay=>
					if player1 = '1' and rand(3) = '1' then
						ra <= ra + 1;
						re <= re - 1;
					elsif player2 = '1' and rand(2) = '1' then
						rb <= rb + 1;
						re <= re - 1;
					elsif player3 = '1' and rand(1) = '1' then
						rc <= rc + 1;
						re <= re - 1;
					elsif player4 = '1' and rand(0) = '1' then
						rd <= rd + 1;
						re <= re - 1;
					elsif re <= "0000" then
						state <= sEnd;
					end if;
				when sEnd =>
					if b1 = '1' then
						state <= sWait;
					end if;
			end case;
		end if;
	end process;

end rtl;
