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
    
    if  y > 350 and Y < 450 and X > 275 and X < 375  then
      red <= '1';
    elsif  Y > 200 and Y < 300 and X > 425 and X < 525  then
	   red <= '1';
    else
      red <= '0';
    end if;
    
    if  Y > 50 and Y < 150 and X > 275 and X < 375  then
      green <= '1';
	 
    else
      green <= '0';
    end if;
    
    if  Y > 200 and Y < 300 and X > 125 and X < 225  then
      blue <= '1';
	 elsif  Y > 200 and Y < 300 and X > 425 and X < 525  then
      blue <= '1';
    else
      blue <= '0';
    end if;

  end process;

end architecture;
