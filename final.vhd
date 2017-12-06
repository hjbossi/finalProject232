-- Hannah Bossi 
-- CS232 Final Project 
-- Test Code for Keyboard Driver

Library IEEE;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity final is
	port(
	clock   :in std_logic; 
	keyboard_clock : in std_logic; -- clock for the keyboard
	keyboard_data  : in std_logic; -- data signal from the keyboard
	isUp    :out std_logic; --  is up arrow pressed
	isW     :out std_logic; -- is W pressed
	isEnter :out std_logic; -- is Enter pressed
	isESC     :out std_logic;  -- is ESC pressed
	debug   : out std_logic_vector(7 downto 0) 
	); 
end entity; 


architecture test of final is
	-- add the component for the keyboard
   component ps2_keyboard is 
	 PORT(
     clk          : IN  STD_LOGIC;                     --system clock
     ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS/2 keyboard
     ps2_data     : IN  STD_LOGIC;                     --data signal from PS/2 keyboard
     ps2_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on ps2_code bus
     ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --code received from PS/2
  end component; 
  
  -- add the internal signals for the port map 
	signal key_pressed  :std_logic_vector(7 downto 0); 
	signal key_new      :std_logic; 
	
begin
	
	-- create component to be used in process
	keyboard1 : ps2_keyboard
		port map(clk => clock, ps2_clk => keyboard_clock, ps2_data => keyboard_data, ps2_code_new => key_new, ps2_code => key_pressed);
	
	process(clock,key_pressed,key_new)
		begin
			debug <= key_pressed; 
			if (rising_edge(clock)) then 
				-- check if w is pressed
				if key_pressed = "00011101" and key_new = '0' then 
					isW <= '1'; 
				else
					isW <= '0'; 
				end if; 
				
				-- check if up arrow is pressed
				if key_pressed = "01110101" and key_new = '0' then 
					isUP <= '1'; 
				else
					isUP <= '0'; 
				end if; 
				
				-- check if enter is pressed
				if key_pressed = "01011010" and key_new = '0' then 
					isEnter <= '1'; 
				else
					isEnter <= '0'; 
				end if; 
				
				-- check if escape is pressed
				if key_pressed = "01110110" and key_new = '0' then 
					isESC <= '1'; 
				else
					isESC <= '0'; 
				end if; 
				
			end if; 
	end process; 




	
		
		
  
  
  
  
end architecture;