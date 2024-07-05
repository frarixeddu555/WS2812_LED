----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:28:33 06/17/2024 
-- Design Name: 
-- Module Name:    TX_WS2812 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TX_WS2812 is
	 Port ( 
			  ck 			: in 		std_logic;                                            -- 50MHz
			  reset 		: in 		std_logic;
--			  color 		: in  	STD_LOGIC_VECTOR (23 downto 0);                   -- it is decoded by the DECODER process
			  switch 	: in  	STD_LOGIC_VECTOR (7 downto 0);
			  btn 		: in  	STD_LOGIC;
			  s_out		: out 	STD_LOGIC);
end TX_WS2812;

architecture Behavioral of TX_WS2812 is
	
	-- constants
	constant 	tot_count_tmp 				: integer := 63;  -- cycles to send one data of 24.
	constant 	time_up1 					: integer := 40; -- set time up1. time_down1 is tot_count_tmp - time_up1;
	constant 	time_up0 					: integer := 18; -- set time up0. time_down0 is tot_count_tmp - time_up0;
	constant 	tot_count_24 				: integer := 24;  -- number of bit to send
	constant 	tot_count_50 				: integer := 13000; -- number of waiting clock cycles to refresh. Apparently, the min clock's cycle to count is 13000, say, at least 260 us.
	
	
	-- Frequency divisor 
	signal cnt_div  													: unsigned (24 downto 0);
	signal ck_en 														: std_logic;
	-- COUNTER1, COUNTER2, COUNTER 3
	signal blue_aux, red_aux, green_aux 						: unsigned (7 downto 0);
	signal blue, red, green 										: unsigned (7 downto 0);
	
	-- FIRST Finite State machine
	signal en_count1, en_count2, en_count3						: std_logic;
	signal add, dec													: std_logic;
	type estado1 is (IDLE1, CHECK0, OP0, CHECK1, OP1, CHECK2, OP2, CHECK3, OP3, CHECK4, OP4, CHECK5, OP5, CHECK6, OP6);
		signal state1, state1_nxt : estado1;
	-- decoder
	signal color 														: std_logic_vector (23 downto 0);
	-- counter single signal 0->1
	signal hit_down_1, hit_down_0, hit_up_1, hit_up_0 		: std_logic;
	signal clr_tmp, en_tmp 											: std_logic;
	signal count_tmp 													: unsigned (6 downto 0);
	-- counter 24 bit signal
	signal hit_24 														: std_logic;
	signal clr_24, en_24												: std_logic;
	signal count_24 													: unsigned (4 downto 0);
	-- counter 50 us
	signal hit_50 														: std_logic;
	signal clr_50, en_50 											: std_logic;
	signal count_50													: unsigned (15 downto 0);
	-- shifter register
	signal load, shift 												: std_logic;
	signal s_value 													: std_logic;
	signal reg 															: unsigned (23 downto 0);
	-- SECOND finite states machine
	type estado2 is (IDLE2, START, INIT, UP0, UP1, DOWN0, DOWN1, SH, RST_CODE);
		signal state2, state2_nxt : estado2;
	
begin
------------------------------------------------------------------------------------	
---- START CONTROL A SINGLE COLOR WITH 8 BRIGHTNESS LEVELS MANUALLY (SWITCHES) -----	
------------------------------------------------------------------------------------

---- BRIGHTNESS DRIVER FOR ONE COLOR 
--	process (switch)
--		begin
--				color <= "0000000000000000" & switch; -- B R G  
--	end process;
--	
--
------------------------------------------------------------------------------------
---- END CONTROL A SINGLE COLOR WITH 8 BRIGHTNESS LEVELS MANUALLY (SWITCHES) -------
------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
----------------- START LED FADING BLOCK FOR JUST ONE COLOR (GREEN) ------------------
--------------------------------------------------------------------------------------
--
----- FREQUENCY DIVISOR -----  -- this process outputs ck_en to drive changing of brightness of the chose color
--process (ck, reset) 
--	begin
--		if (reset= '1') then
--			cnt_div 	<= (others => '0');
--			ck_en 	<= '0';
--		elsif (ck'event and ck = '1') then
--			if (cnt_div < 1249999) then       -- The frequency for the LED must be > 400 Hz
--				cnt_div 	<= cnt_div + 1;
--				ck_en		<= '0';							
--			else
--				cnt_div 	<= (others => '0');
--				ck_en 	<= '1';
--			end if;
--		end if;
--end process;
--
--
------- COUNTER1 (XX0000) ------ -- this process reverts the green signal's bit and adds/odds an offset for the brightness
--process (ck, reset) 
--begin
--	if (reset= '1') then
--		green_aux 		<= (others => '0');
--		red_aux 			<= (others => '0');
--		blue_aux 		<= (others => '0');
--	elsif (ck'event and ck = '1') then
--		if (ck_en = '1') then
----				if (en_count1 = '1') then
--				if (add = '1') then	
--					green_aux (7 downto 0) <= 
--													(green(0) &
--													 green(1) &
--													 green(2) &
--													 green(3) &
--													 green(4) &
--													 green(5) &
--													 green(6) &
--													 green(7)) + 5 ;
--				elsif (dec = '1') then
--					green_aux (7 downto 0) <= 
--													(green(0) &
--													 green(1) &
--													 green(2) &
--													 green(3) &
--													 green(4) & 
--													 green(5) & 
--													 green(6) &
--													 green(7)) - 5 ;
--				end if;	
----				end if;
--		end if;
--	end if;
--
--end process;
--
-------- STATUS REGISTER ----- -- this and the previous process complete the reverse->add/odd->reverse function
--process (ck, reset) 			  -- we want to realize. In particular, this process gets the final reverse operation 
--	begin
--		if (reset= '1') then
--			color 	<= (others => '0');
--			green 	<= (others => '0');
--			red 		<= (others => '0');
--			blue 		<= (others => '0');
--		elsif (ck'event and ck = '1') then
--			blue <= 			blue_aux;
--			red <= 			red_aux;
--			green <= 		green_aux(0) &
--								green_aux(1) & 
--								green_aux(2) & 
--								green_aux(3) & 
--								green_aux(4) & 
--								green_aux(5) & 
--								green_aux(6) & 
--								green_aux(7);
--		end if;							
--		color <= std_logic_vector(blue & red & green);
--end process;
--
--
--
--	----- FIRST Finite State Machine to control LED fading
--process (ck, reset)       -- this FSM drives the two phases of the LED. Increase brightness and decrease brightness
--	begin						  -- when the color takes a FF or 00 value
--		if (reset = '1') then
--			state1 	<= IDLE1;
--		elsif (ck'event and ck = '1') then
--			state1 	<= state1_nxt;
--		end if;
--end process;
--					
--process (color, state1, btn)
--	begin
--		case state1 is
--			when IDLE1 =>
--				if (btn = '1') then
--					state1_nxt 	<= CHECK0;
--				else
--					state1_nxt 	<= IDLE1;
--				end if;		
--			when CHECK0 =>
--				if (green = x"FF") then
--					state1_nxt 	<= CHECK1;
--				else
--					state1_nxt 	<= CHECK0;
--				end if;
--			when CHECK1 =>
--				if (green = x"00") then
--					state1_nxt 	<= CHECK0;
--				else
--					state1_nxt 	<= CHECK1;
--				end if;
--				
--			when others => 
--					state1_nxt 	<= IDLE1;
--		end case;
--			
--	end process;
--							
--process (state1)
--	begin
--		case state1 is
--				when IDLE1 =>            
--					add       <= '0';
--					dec       <= '0';
--					en_count1 <= '0'; 
--				when CHECK0 =>				
--					add       <= '1';
--					dec       <= '0';
--					en_count1 <= '1'; 
--				when CHECK1 =>				
--					add       <= '0';
--					dec       <= '1';
--					en_count1 <= '1';
--				
--				when others => 
--					add       <= '0';
--					dec       <= '0';
--					en_count1 <= '0';
--		end case;
--end process;
--
--
--------------------------------------------------------------------------------
----------------- END LED FADING BLOCK FOR JUST ONE COLOR (GREEN) --------------
--------------------------------------------------------------------------------

------------------------------------------------------------------------------
---------------- START FADING BLOCK FOR JUST ONE COLOR MANUALLY --------------
------------------------------------------------------------------------------
	
---- DECODER FOR ONE COLOR -----
--
--DECODER_COLOR : process (switch)
--	begin
--		case switch is 
--			when "00000000" => 
--				color <= "000000000000000000000000";
--			when "001" => 
--				color <= "111111110000000000000000";
--			when "010" => 
--				color <= "000000001111111100000000";
--			when "011" => 
--				color <= "111111111111111100000000";
--			when "100" => 
--				color <= "000000000000000011111111";
--			when "101" => 
--				color <= "111111110000000011111111";
--			when "110" => 
--				color <= "000000001111111111111111";
--			when "111" => 
--				color <= "111111111111111111111111";
--			when others => 
--				color <= "000000000000000000000000";
--		end case;
--end process;	
--
------------------------------------------------------------------------------
---------------- END FADING BLOCK FOR JUST ONE COLOR MANUALLY ----------------
------------------------------------------------------------------------------

----------------------------------------------------------------------------
-------------------- START LED FADING BLOCK --------------------------------
----------------------------------------------------------------------------

--- FREQUENCY DIVISOR -----
process (ck, reset) 
	begin
		if (reset= '1') then
				
			cnt_div <= (others => '0');
			ck_en <= '0';
		
		elsif (ck'event and ck = '1') then
			if (cnt_div < 1249) then       -- The frequency for the LED must be > 400 Hz
				cnt_div <= cnt_div + 1;
				ck_en <= '0';
					
			else
				cnt_div <= (others => '0');
				ck_en <= '1';
			end if;
		end if;
end process;
			

	----- FADING AUX  ------
		process (ck, reset) 
		begin
			if (reset= '1') then
				green_aux 		<= (others => '0');
				red_aux 			<= (others => '0');
				blue_aux 		<= (others => '0');
			elsif (ck'event and ck = '1') then
				if (ck_en = '1') then
					if (en_count1 = '1') then
						if (add = '1') then	
							blue_aux (7 downto 0) <= 
														(blue(0) &
														 blue(1) &
														 blue(2) &
														 blue(3) &
														 blue(4) &
														 blue(5) &
														 blue(6) &
														 blue(7)) + 5 ;
						elsif (dec = '1') then
							blue_aux (7 downto 0) <= 
														(blue(0) &
														 blue(1) &
														 blue(2) &
														 blue(3) &
														 blue(4) & 
														 blue(5) & 
														 blue(6) &
														 blue(7)) - 5 ;
						end if;
					elsif (en_count2 = '1') then
						if (add = '1') then	
							red_aux (7 downto 0) <= 
														(red(0) &
														 red(1) &
														 red(2) &
														 red(3) &
														 red(4) &
														 red(5) &
														 red(6) &
														 red(7)) + 5 ;
						elsif (dec = '1') then
							red_aux (7 downto 0) <= 
														(red(0) &
														 red(1) &
														 red(2) &
														 red(3) &
														 red(4) & 
														 red(5) & 
														 red(6) &
														 red(7)) - 5 ;
						end if;
					elsif (en_count3 = '1') then
						if (add = '1') then	
							green_aux (7 downto 0) <= 
														(green(0) &
														 green(1) &
														 green(2) &
														 green(3) &
														 green(4) &
														 green(5) &
														 green(6) &
														 green(7)) + 5 ;
						elsif (dec = '1') then
							green_aux (7 downto 0) <= 
														(green(0) &
														 green(1) &
														 green(2) &
														 green(3) &
														 green(4) & 
														 green(5) & 
														 green(6) &
														 green(7)) - 5 ;
						end if;
					end if;
				end if;
			end if;						

		end process;
		
------ STATUS REGISTER ----- -- this and the previous process complete the reverse->add/odd->reverse function
process (ck, reset) 			  -- we want to realize. In particular, this process gets the final reverse operation 
	begin
		if (reset= '1') then
			color 	<= (others => '0');
			green 	<= (others => '0');
			red 		<= (others => '0');
			blue 		<= (others => '0');
		elsif (ck'event and ck = '1') then
			blue 			<= blue_aux(0) &
								blue_aux(1) & 
								blue_aux(2) & 
								blue_aux(3) & 
								blue_aux(4) & 
								blue_aux(5) & 
								blue_aux(6) & 
								blue_aux(7);
			red 			<= red_aux(0) &
								red_aux(1) & 
								red_aux(2) & 
								red_aux(3) & 
								red_aux(4) & 
								red_aux(5) & 
								red_aux(6) & 
								red_aux(7);
			green 		<= green_aux(0) &
								green_aux(1) & 
								green_aux(2) & 
								green_aux(3) & 
								green_aux(4) & 
								green_aux(5) & 
								green_aux(6) & 
								green_aux(7);
		end if;							
		color <= std_logic_vector(blue & red & green);
end process;


	

	
	----- FIRST Finite State Machine to control LED fading
	
process (ck, reset)
	begin
		if (reset = '1') then
			state1 <= IDLE1;
		elsif (ck'event and ck = '1') then
			state1 <= state1_nxt;
		end if;
end process;
						
process (blue, red, green, state1, btn)
	begin
		case state1 is
			when IDLE1 =>
				if (btn = '1') then
					state1_nxt <= CHECK0;
				else
					state1_nxt <= IDLE1;
				end if;
			when CHECK0 =>
				if (green = x"FF") then
						state1_nxt <= CHECK1;
				else
					state1_nxt <= CHECK0;
				end if;
			when CHECK1 =>
				if (blue = x"FF") then
						state1_nxt <= CHECK2;
				else
					state1_nxt <= CHECK1;
				end if;
			when CHECK2 =>
				if (green = x"00") then
					state1_nxt <= CHECK3;
				else
					state1_nxt <= CHECK2;
				end if;
			when CHECK3 =>
				if (red = x"fF") then
					state1_nxt <= CHECK4;
				else
					state1_nxt <= CHECK3;
				end if;
			when CHECK4 =>
				if (blue = x"00") then
					state1_nxt <= CHECK5;
				else
					state1_nxt <= CHECK4;
				end if;
			when CHECK5 =>
				if (green = x"fF") then
					state1_nxt <= CHECK6;
				else
					state1_nxt <= CHECK5;
				end if;
			when CHECK6 =>
				if (red = x"00") then
					state1_nxt <= CHECK1;  -- CHECK1, not CHECK0 to avoid stepping up a clock cycle
				else
					state1_nxt <= CHECK6;  
				end if;
								
			when others => 
				state1_nxt <= IDLE1;
		end case;
end process;
								
process (state1)
	begin
		case state1 is
			when IDLE1 =>            
				 add       <= '0';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '0';
			when CHECK0 =>				-- x"000000"
				 add       <= '1';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '1';
			when CHECK1 =>				-- x"FF0000"
				 add       <= '1';
				 dec       <= '0';
				 en_count1 <= '1';
				 en_count2 <= '0';
				 en_count3 <= '0';
			when CHECK2 =>				-- x"FF00FF"
				 add       <= '0';
				 dec       <= '1';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '1';
			when CHECK3 =>				-- x"0000FF"
				 add       <= '1';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '1';
				 en_count3 <= '0';
			when CHECK4 =>				-- x"00FFFF"
				 add       <= '0';
				 dec       <= '1';
				 en_count1 <= '1';
				 en_count2 <= '0';
				 en_count3 <= '0';
			when CHECK5 =>				-- x"00FF00"
				 add       <= '1';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '1';
			when CHECK6 =>				-- x"FFFF00"
				 add       <= '0';
				 dec       <= '1';
				 en_count1 <= '0';
				 en_count2 <= '1';
				 en_count3 <= '0';
				 
			when others => 
				 add       <= '0';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '0';
		end case;
end process;

------------------------------------------------------------------------------
---------------------- END LED FADING BLOCK ----------------------------------
------------------------------------------------------------------------------

------------------------------------------------------------------------------
------------------- START 3 SWITCHES DRIVIN COLORS ----------------------------
------------------------------------------------------------------------------

---- DECODER -----
--
--DECODER_COLOR : process (switch)
--	begin
--		case switch is 
--		
--				when "000" => 
--								color <= "000000000000000000000000";
--				when "001" => 
--								color <= "111111110000000000000000";
--				when "010" => 
--								color <= "000000001111111100000000";
--				when "011" => 
--								color <= "111111111111111100000000";
--				when "100" => 
--								color <= "000000000000000011111111";
--				when "101" => 
--								color <= "111111110000000011111111";
--				when "110" => 
--								color <= "000000001111111111111111";
--				when "111" => 
--								color <= "111111111111111111111111";
--				when others => 
--								color <= "000000000000000000000000";
--		end case;
--end process;					

--------------------------------------------------------------------------------
---------------------------- END SWITCHES BLOCK --------------------------------
--------------------------------------------------------------------------------

----------- COUNTER SINGLE SIGNAL (1 -> 0 cycle) --------                  -- at time_up0  =>  hit_up_0 = 1
COUNTER_PERIOD : process (ck, reset)												-- at time_up1  => hit_up_1 = 1
	begin																						-- at time_max => hit_down_0, hit_down_1 = 1
		if (reset = '1') then                                    -- I wanted to use a single counter to drive the system counting part
				count_tmp <= (others => '0');
		elsif (ck'event and ck = '1') then
				if (clr_tmp = '1') then
						count_tmp <= (others => '0');	
				elsif (en_tmp = '1') then
						if (count_tmp < tot_count_tmp - 1) then  
								count_tmp <= count_tmp + 1;	
						else
								count_tmp <= (others => '0');
						end if;																	
				end if;
		end if;
end process;
		
RC_COUNTER_PERIOD : process (count_tmp)
	begin
		if (count_tmp < tot_count_tmp - 1) then
				if (count_tmp = time_up0 - 1) then
						hit_down_1 <= '0';
						hit_up_1 <= '0';
						hit_down_0 <= '0';
						hit_up_0 <= '1';
				elsif (count_tmp = time_up1 - 1) then	
						hit_down_1 <= '0';
						hit_up_1 <= '1';
						hit_down_0 <= '0';
						hit_up_0 <= '0';	
				else
						hit_down_1 <= '0';									
						hit_up_1 <= '0';
						hit_down_0 <= '0';
						hit_up_0 <= '0';
				end if;	
		else
				hit_down_1 <= '1';									
				hit_up_1 <= '0';
				hit_down_0 <= '1';
				hit_up_0 <= '0';
		end if;
					
end process;
									

	----------- COUNTER SINGLE SIGNAL (24 BIT) --------					-- this module gives a hit_24 = 1 when the 24bits have been sent.
COUNTER_24_BIT : process (ck, reset)
	begin
		if (reset = '1') then
			count_24 <= (others => '0');
		elsif (ck'event and ck = '1') then
			if (clr_24 = '1') then
					count_24 <= (others => '0');
			elsif (en_24 = '1') then
					if (count_24 < tot_count_24 - 1) then
							count_24 <= count_24 + 1;			
					else
							count_24 <= (others => '0');	
					end if;
			end if;
		end if;
end process;
		
		
RC_COUNTER_24_BIT : process (count_24)
	begin
		if (count_24 = tot_count_24 - 1) then
			hit_24 <= '1';	
		else
			hit_24 <= '0';
		end if;
end process;
							
	----------- COUNTER SINGLE SIGNAL (50 us) --------					
COUNTER_RESET_TIME : process (ck, reset)                           -- this module counts how long should stay in the RST_CODE state
	begin
		if (reset = '1') then
			count_50 <= (others => '0');
		elsif (ck'event and ck = '1') then
			if (clr_50 = '1') then
					count_50 <= (others => '0');
			elsif (en_50 = '1') then
				if (count_50 = tot_count_50 - 1) then
					count_50 <= (others => '0');
					hit_50 <= '1';
				else
					count_50 <= count_50 + 1;
					hit_50 <= '0';
				end if;
			end if;
		end if;
end process;

	------------- SHIFTER REGISTER ------                           -- a simple shift register that sets the leftmost bits to 0 and provides the LSB as output to s_value
SHIFT_REGISTER : process (ck, reset)
	begin
		if (reset = '1') then
			reg <= (others => '0');
		elsif (ck'event and ck = '1') then		
			if (load = '1') then	
				reg <= unsigned (color);
			elsif (shift = '1') then
				reg <= ('0' & reg (23 downto 1));		
			end if;
		end if;
end process;

s_value <= std_logic(reg(0));
											

	------------ second FINITE STATE MACHINE ------
FSM : process (ck, reset)
begin
	if (reset = '1') then
		state2 <= IDLE2;
	elsif (ck'event and ck = '1') then
		state2 <= state2_nxt;
	end if;
end process;

RC_FSM : process (state2, btn, s_value, hit_up_1, hit_up_0, hit_down_0, hit_down_1, hit_24, hit_50)    -- driven just by SWITCH signal
begin
	case state2 is
		when IDLE2 => 
					state2_nxt <= INIT;	
		when INIT => 
					state2_nxt <= START;
		when START => 
					if (s_value = '1') then
						state2_nxt <= UP1;
					else
						state2_nxt <= UP0;
					end if;	
		when UP1 =>				
					if (hit_up_1 = '1') then
						state2_nxt <= DOWN1;
					else
						state2_nxt <= UP1;
					end if;			
		when DOWN1 =>
					if (hit_down_1 = '1') then
						state2_nxt <= SH;
					else
						state2_nxt <= DOWN1;
					end if;			
		when UP0 =>
					if (hit_up_0 = '1') then
						state2_nxt <= DOWN0;
					else
						state2_nxt <= UP0;
					end if;					
		when DOWN0 =>
					if (hit_down_0 = '1') then
						state2_nxt <= SH;
					else
						state2_nxt <= DOWN0;
					end if;			
		when SH =>
					if (hit_24 = '1') then
						state2_nxt <= RST_CODE;
					else
						state2_nxt <= START;
					end if;				
		when RST_CODE =>
					if (hit_50 = '1') then
						state2_nxt <= INIT;
					else
						state2_nxt <= RST_CODE;
					end if;
					
		when others =>	
					state2_nxt <= IDLE2;
	end case;
	
end process;
									
RC_FSM_OUTPUTS : process (state2)
begin
	case state2 is
		when IDLE2 => 
						load <= '0';  
						shift <= '0';
						clr_tmp <= '0';
						en_tmp <= '0';
						clr_24 <= '0';
						en_24 <= '0';
						clr_50 <= '1'; -- clr_50
						en_50 <= '0';
						s_out <= '0';
		when INIT => 
						load <= '1';  -- load
						shift <= '0';
						clr_tmp <= '1'; -- clr_tmp
						en_tmp <= '0';
						clr_24 <= '1';  -- clr_24
						en_24 <= '0';
						clr_50 <= '1';  -- clr_50
						en_50 <= '0';
						s_out <= '0';
		when START => 
						load <= '0'; 
						shift <= '0'; 
						clr_tmp <= '0';
						en_tmp <= '0';  
						clr_24 <= '0';
						en_24 <= '0';  
						clr_50 <= '1';  -- clr_50
						en_50 <= '0';
						s_out <= '0';
		when UP1 => 
						load <= '0';
						shift <= '0';
						clr_tmp <= '0';
						en_tmp <= '1';  -- en_tmp
						clr_24 <= '0';
						en_24 <= '0';
						clr_50 <= '0';
						en_50 <= '0';
						s_out <= '1';  
		when DOWN1 => 
						load <= '0';
						shift <= '0';
						clr_tmp <= '0';
						en_tmp <= '1';  -- en_tmp
						clr_24 <= '0';
						en_24 <= '0';
						clr_50 <= '0';
						en_50 <= '0';
						s_out <= '0';
		when UP0 => 
						load <= '0';
						shift <= '0';  
						clr_tmp <= '0';
						en_tmp <= '1';  -- en_tmp
						clr_24 <= '0';
						en_24 <= '0';
						clr_50 <= '0';
						en_50 <= '0';
						s_out <= '1';  	
		when DOWN0 => 
						load <= '0';
						shift <= '0';
						clr_tmp <= '0';
						en_tmp <= '1';  -- en_tmp
						clr_24 <= '0';
						en_24 <= '0';
						clr_50 <= '0';
						en_50 <= '0';
						s_out <= '0';
		when SH => 
						load <= '0';
						shift <= '1';  -- shift
						clr_tmp <= '0'; 
						en_tmp <= '0';
						clr_24 <= '0';
						en_24 <= '1'; -- en_24
						clr_50 <= '0';
						en_50 <= '0';
						s_out <= '0';
		when RST_CODE => 
						load <= '0';
						shift <= '0';
						clr_tmp <= '0';
						en_tmp <= '0';
						clr_24 <= '0';
						en_24 <= '0';
						clr_50 <= '0';
						en_50 <= '1';  --en_50
						s_out <= '0';	
						
		when others =>              -- clr general	
						load <= '0';
						shift <= '0';
						clr_tmp <= '1';
						en_tmp <= '0';
						clr_24 <= '1';
						en_24 <= '0';  
						clr_50 <= '1';
						en_50 <= '0';
						s_out <= '0';				
	end case;
end process;							

end Behavioral;

