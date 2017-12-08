-- CS232 Final Project 
-- Hungry Hungry Hippos
-- Max Abramson, Hannah Bossi, John Dowling, Matt Jones

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity hungryHippos is
	port(
		clock         	: in std_logic;	
		rand_clock		: in std_logic; -- clock for random number
		
		-- Keyboard Component
		keyboard_clock : in std_logic; -- clock for the keyboard
		keyboard_data  : in std_logic; -- data signal from the keyboard
		
		-- VGA Driver
		R, G, B, H, V : out std_logic; -- output for the players colors
		
		-- output to hold the players scores
		score1 : out std_logic_vector(6 downto 0);
		score2 : out std_logic_vector(6 downto 0);
		score3 : out std_logic_vector(6 downto 0);
		score4 : out std_logic_vector(6 downto 0);
		
		-- debug signals
		debug 	 : out std_logic_vector(3 downto 0);
		rand_view : out std_logic_vector(3 downto 0)
	);
end entity;

-- ============================ ARCHITECTURE ==============================================
architecture rtl of hungryHippos is
	
	-- ======================== COMPONENTS =================================================
	
	-- VGA Driver 
	component vgadrive is
		port(
			clock         		: in std_logic;  -- 25.175 Mhz clock
			red, green, blue 	: in std_logic;  -- input values for RGB signals
			row, column      	: out std_logic_vector(9 downto 0); -- for current pixel
			Rout, Gout, Bout, H, V : out std_logic -- VGA drive signals
		); 
   end component;
  
	-- Seven Segment Display
  	component display
		port (
			A :  in  std_logic;
			B :  in  std_logic;
			C :  in  std_logic;
			D :  in  std_logic;
			LU :  out  std_logic;
			RU :  out  std_logic;
			RL :  out  std_logic;
			MU :  out  std_logic;
			MM :  out  std_logic;
			ML :  out  std_logic;
			LL :  out  std_logic
		);
	end component;
  
	-- Keyboard Driver
	component keyboard_in is 
			port(
				clock				: in std_logic; -- clock for state machine
				keyboard_clock : in std_logic; -- clock for the keyboard
				keyboard_data  : in std_logic; -- data signal from the keyboard
				isUp    			: out std_logic; --  is up arrow pressed
				isLShift     	: out std_logic; -- is W pressed
				isSpace 			: out std_logic; --- is space pressed
				isEnter 			: out std_logic; -- is Enter pressed
				isRShift     	: out std_logic; -- is P pressed 
				isESC     		: out std_logic  -- is ESC pressed
			);
	end component; 
	
	--linear feedback shift register used for generating pseudo-random 4 bit numbers
	component lfsr is
		port(
			clk : in STD_LOGIC;
			rst : in STD_LOGIC;
			outp : out STD_LOGIC_VECTOR (3 downto 0)
		);
	end component;
	
	--====================================== INTERNAL SIGNALS =============================================
	
	-- Build an enumerated type for the state machine
	type state_type is (sIdle, sWait, sPlay, sEnd);

	-- Register to hold the current state
	signal state	: state_type;
	
	-- VGA Coloring
	signal Y, X : std_logic_vector(9 downto 0);
	signal red, green, blue : std_logic;
	
	-- State Machine Signals
	signal counter : std_logic_vector(27 downto 0);
	signal ra		: unsigned(3 downto 0);
	signal rb		: unsigned(3 downto 0);
	signal rc		: unsigned(3 downto 0);
	signal rd		: unsigned(3 downto 0);
	signal re		: unsigned(3 downto 0);
	signal player1	: std_logic;
	signal player2	: std_logic;
	signal player3 : std_logic; 
	signal player4 : std_logic; 
	signal start 	: std_logic;
	signal reset	: std_logic;
	
	-- Random signal
	signal rand : std_logic_vector(3 downto 0);
	signal rand_test : std_logic_vector(3 downto 0);
	
	-- slow clock signals to make the speed of the game manageable
	signal slowclock : std_logic;
	signal slclcounter : unsigned(27 downto 0);
	
	
-- ================================================= PROCESSES ===================================================	
begin
	--component instances
	--i/o from component=>internal signal
	
	-- VGA component
	VGA : vgadrive 
		port map(
			clock => clock,
			red => red,
			green => green,
			blue => blue,
			row => Y,
			column => X,
			Rout => R,
			Gout => G,
			Bout => B,
			H => H,
			V => V
		);
  	
	-- Keyboard driver component
	keyboard1 : keyboard_in
		port map(
			clock => clock,
			keyboard_clock => keyboard_clock,
			isUp => player1,
			isLShift => player4,
			isEnter => start,
			isESC => reset,
			keyboard_data => keyboard_data,
			isSpace => player3,
			isRShift => player2
		);
	
	-- 7 Segment Display Components
	count1 : display
		port map(
			A => ra(3),
			B => ra(2),
			C => ra(1),
			D => ra(0), 
			MU => score1(0), 
			RU => score1(1), 
			RL => score1(2), 
			ML => score1(3), 
			LL => score1(4), 
			LU => score1(5), 
			MM => score1(6)
		);
		
	count2 : display
		port map(
			A => rb(3),
			B => rb(2),
			C => rb(1),
			D => rb(0), 
			MU => score2(0), 
			RU => score2(1), 
			RL => score2(2), 
			ML => score2(3), 
			LL => score2(4), 
			LU => score2(5), 
			MM => score2(6)
		);
		
	count3 : display
		port map (
			A => rc(3), 
			B => rc(2), 
			C => rc(1), 
			D => rc(0), 
			MU => score3(0), 
			RU => score3(1), 
			RL => score3(2), 
			ML => score3(3), 
			LL => score3(4), 
			LU => score3(5), 
			MM => score3(6)
		);
	
	count4 : display
		port map(
			A => rd(3),
			B => rd(2), 
			C => rd(1), 
			D => rd(0), 
			MU => score4(0), 
			RU => score4(1), 
			RL => score4(2), 
			ML => score4(3), 
			LL => score4(4), 
			LU => score4(5), 
			MM => score4(6)
		);
	
	-- LSFR components
	lfsr1: lfsr
		port map(
			clk => rand_clock, 
			rst=>reset, 
			outp => rand
		);
	
	-- ========================================= slowclock process ===================================================
	process(clock, reset)
	begin
		if reset = '1' then
			slclcounter <= "0000000000000000000000000000";
		elsif(rising_edge(clock)) then
			slclcounter <= slclcounter + 1;
		end if;
	end process;
	
	slowclock <= slclcounter(19);
	
	-- ===========================================  STATE MACHINE ====================================================
	process (slowclock, reset)
	begin
		if reset = '1' then
			state <= sIdle;
			counter <= "0000000000000000000000111111"; --can reduce number of bits in counter
			ra <= "0000";
			rb <= "0000";
			rc <= "0000";
			rd <= "0000";
			re <= "0000";
		elsif (rising_edge(slowclock)) then
			case state is
				-- Idle State
				when sIdle=>
					debug <= "0001"; 
					if start = '1' then
						state <= sWait;
					end if;
					
				-- Wait State	
				when sWait=>
					debug <= "0010"; 
					if counter <= "0000000000000000000000000000" then
						re <= "1111";
						state <= sPlay;
					else
						counter <= std_logic_vector(unsigned(counter) - 1);
					end if;
					
				-- Play State	
				when sPlay=>
					debug <= "0100";
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
					end if;--i/o from component=>internal signal
					
				-- End State	
				when sEnd =>
					debug <= "1000";
					if reset = '1' then
						state <= sIdle;
					end if;
			end case;
		end if;
	end process;
	
	-- =========================================== PROCESSS TO DRAW THE HIPPOS =======================================
	RGB : process(Y, X)
	begin
   -- wait until clock = '1';
   --Drawing the four hippos
    
   if re = "1111" then
		if player1 = '1' then
			if Y > 165 and Y < 195 and X > 255 and X < 270  then
			end if;
		end if;
			if  Y > 165 and Y < 195 and X > 255 and X < 270  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 165 and Y < 195 and X > 285 and X < 300  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 165 and Y < 195 and X > 315 and X < 330  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 165 and Y < 195 and X > 345 and X < 360  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 165 and Y < 195 and X > 375 and X < 390  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 225 and Y < 255 and X > 255 and X < 270  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 225 and Y < 255 and X > 285 and X < 300  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 225 and Y < 255 and X > 315 and X < 330  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
				blue <= '1';
				green <= '1'; 
				red <= '1';
			else
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
				else
					blue <= '0';
					green <= '0';
					red <= '0';
				end if;
			end if;
	elsif re = "1110" then
		if  Y > 165 and Y < 195 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 165 and Y < 195 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 165 and Y < 195 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 165 and Y < 195 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "1101" then
		if  Y > 165 and Y < 195 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 165 and Y < 195 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 165 and Y < 195 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "1100" then
		if  Y > 165 and Y < 195 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 165 and Y < 195 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "1011" then
		if  Y > 165 and Y < 195 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "1010" then
		if  Y > 225 and Y < 255 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "1001" then
		if  Y > 225 and Y < 255 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "1000" then
		if  Y > 225 and Y < 255 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "0111" then
		if  Y > 225 and Y < 255 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "0110" then
		if  Y > 225 and Y < 255 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "0101" then
		if  Y > 285 and Y < 315 and X > 255 and X < 270  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "0100" then
		if  Y > 285 and Y < 315 and X > 285 and X < 300  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif re = "0011" then
		if  Y > 285 and Y < 315 and X > 315 and X < 330  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;	
	elsif re = "0010" then
		if  Y > 285 and Y < 315 and X > 345 and X < 360  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		elsif  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	elsif  re = "0001" then
		if  Y > 285 and Y < 315 and X > 375 and X < 390  then
			blue <= '1';
			green <= '1'; 
			red <= '1';
		else	
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	else
		if Y > 150 and Y < 330 and X > 240 and X < 400 then
			if ra > rb and ra > rc and ra > rd then
				red <= '1';
				blue <= '0';
				green <= '0';
			elsif rb > ra and rb > rc and rb > rd then
				red <= '0';
				blue <= '1';
				green <= '0';
			elsif rc > ra and rc > rb and rc > rd then
				red <= '0';
				blue <= '0';
				green <= '1';
			elsif rd > ra and rd > rb and rd > rc then
				red <= '1';
				blue <= '1';
				green <= '0';
			elsif state = sWait or state = sIdle then
				red <= '1';
				green <= '1';
				blue <= '1';
			else
				red <= '1';
				green <= '1';
				blue <= '0';
			end if;
		else 
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
			else
				blue <= '0';
				green <= '0';
				red <= '0';
			end if;
		end if;
	end if;
	 
	end process;
  
	-- set the output signal
	rand_view <= rand;
end rtl;