-- RGB VGA test pattern  Rob Chapman  Mar 9, 1998

 -- This file uses the VGA driver and creates 3 squares on the screen which
 -- show all the available colors from mixing red, green and blue

Library IEEE;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vgatest is
  port(clock         : in std_logic;
       R, G, B, H, V : out std_logic);
end entity;

architecture test of vgatest is

  component vgadrive is
    port( clock          : in std_logic;  -- 25.175 Mhz clock
        red, green, blue : in std_logic;  -- input values for RGB signals
        row, column      : out std_logic_vector(9 downto 0); -- for current pixel
        Rout, Gout, Bout, H, V : out std_logic); -- VGA drive signals
  end component;
  
  signal Y, X : std_logic_vector(9 downto 0);
  signal red, green, blue : std_logic;

begin

  -- for debugging: to view the bit order
  VGA : component vgadrive
    port map ( clock => clock, red => red, green => green, blue => blue,
               row => Y, column => X,
               Rout => R, Gout => G, Bout => B, H => H, V => V);
 
  -- red square from 0,0 to 360, 350
  -- green square from 0,250 to 360, 640
  -- blue square from 120,150 to 480,500
  RGB : process(Y, X)
  begin
    -- wait until clock = '1';
    
    if  Y < 480-20 and Y > 480-90 and X < 640-285 and X > 640-365  then
      red <= '1';
	 elsif  Y < 480-85 and Y > 480-105 and X < 640-317 and X > 640-333  then
	   red <= '1';
    elsif  Y < 480-104 and Y > 480-150 and X < 640-305 and X > 640-345  then
	   red <= '1';
    elsif  Y < 480-210 and Y > 480-290 and X < 640-125 and X > 640-175  then
      red <= '1';
		blue <= '1';
    elsif  Y < 480-240 and Y > 480-260 and X < 640-174 and X > 640-200  then
      red <= '1';
		blue <= '1';
    elsif  Y < 480-220 and Y > 480-280 and X < 640-199 and X > 640-240  then
      red <= '1';
		blue <= '1';
    elsif  Y > 20 and Y < 90 and X > 285 and X < 365  then
      green <= '1';
	 elsif  Y > 85 and Y < 105 and X > 317 and X < 333  then
	   green <= '1';
    elsif  Y > 104 and Y < 150 and X > 305 and X < 345  then
	   green <= '1';    
    elsif  Y > 210 and Y < 290 and X > 125 and X < 175  then
      blue <= '1';
    elsif  Y > 240 and Y < 260 and X > 174 and X < 200  then
	   blue <= '1';
    elsif  Y > 220 and Y < 280 and X > 199 and X < 240  then
	   blue <= '1';
    elsif  Y > 235 and Y < 245 and X > 315 and X < 325  then
		blue <= '1';
		green <= '1'; 
		red <= '1';
    elsif Y > 237 and Y < 242 and X > 312 and X < 327  then
		blue <= '1';
		green <= '1'; 
		red <= '1';
    elsif  Y > 232 and Y < 247 and X > 317 and X < 322  then
		blue <= '1';
		green <= '1'; 
		red <= '1';
    else
      blue <= '0';
		green <= '0';
		red <= '0';
    end if;
	 
  end process;

end architecture;
