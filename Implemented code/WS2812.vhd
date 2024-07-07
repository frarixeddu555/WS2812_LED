library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TX_WS2812 is
	 Port ( 
			  ck 			: in 		std_logic;                                            -- 50MHz
			  reset 		: in 		std_logic;
--			  color 		: in  		std_logic_vector (23 downto 0);                   -- it is decoded by the DECODER process
			  switch 		: in  		std_logic_vector (7 downto 0);
			  btn 			: in  		std_logic;
			  s_out			: out 		std_logic);
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
	signal blue_aux, red_aux, green_aux 								: unsigned (7 downto 0);
	signal blue, red, green 											: unsigned (7 downto 0);
	
	-- "Fade color" Finite State machine
	signal en_count1, en_count2, en_count3								: std_logic;
	signal inc, dec														: std_logic;
	type estado1 is (IDLE1, INC0, INC1, DEC0, INC2, DEC1, INC3, DEC2);
		signal state1, state1_nxt : estado1;
	-- decoder
	signal color 														: std_logic_vector (23 downto 0);
	-- counter single signal 0->1
	signal hit_down_1, hit_down_0, hit_up_1, hit_up_0 					: std_logic;
	signal clr_tmp, en_tmp 												: std_logic;
	signal count_tmp 													: unsigned (6 downto 0);
	-- counter 24 bit signal
	signal hit_24 														: std_logic;
	signal clr_24, en_24												: std_logic;
	signal count_24 													: unsigned (4 downto 0);
	-- counter 50 us
	signal hit_50 														: std_logic;
	signal clr_50, en_50 												: std_logic;
	signal count_50														: unsigned (15 downto 0);
	-- shifter register
	signal load, shift 													: std_logic;
	signal s_value 														: std_logic;
	signal reg 															: unsigned (23 downto 0);
	-- "Send data to LED" finite states machine
	type estado2 is (IDLE2, START, INIT, UP0, UP1, DOWN0, DOWN1, SH, RST_CODE);
		signal state2, state2_nxt : estado2;
		
	
begin

------------------------------------------------------------------------------
------------------- START MODULE 3 SWITCHES DRIVING COLORS -------------------
------------------------------------------------------------------------------

---- DECODER -----
--
--DECODER_COLOR : process (switch)
--	begin
--		case switch is 
--		
--				when "000" => 
--					color <= "000000000000000000000000";
--				when "001" => 
--					color <= "111111110000000000000000";
--				when "010" => 
--					color <= "000000001111111100000000";
--				when "011" => 
--					color <= "111111111111111100000000";
--				when "100" => 
--					color <= "000000000000000011111111";
--				when "101" => 
--					color <= "111111110000000011111111";
--				when "110" => 
--					color <= "000000001111111111111111";
--				when "111" => 
--					color <= "111111111111111111111111";
--				when others => 
--					color <= "000000000000000000000000";
--		end case;
--end process;					

--------------------------------------------------------------------------------
------------------ END MODULE 3 SWITCHES DRIVING COLORS ------------------------
--------------------------------------------------------------------------------

------------------------------------------------------------------------------
---------------- START FADING BLOCK FOR JUST ONE COLOR MANUALLY --------------
------------------------------------------------------------------------------
	
---- DECODER FOR ONE COLOR -----
--
--DECODER_COLOR : process (switch) -- decoding 24 bit for the 3 colors whit 8 bit
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

---------------------------------------------------------------------------------------	
-- START MODULE TO DRIVE A SINGLE COLOR WITH 8 BRIGHTNESS LEVELS MANUALLY (SWITCHES) --
---------------------------------------------------------------------------------------

---- BRIGHTNESS DRIVER FOR ONE COLOR 
--	process (switch)
--		begin
--				color <= "0000000000000000" & switch; -- first 16bit are setted to '0'
--													  -- last 8 bit are drived by switch input
--	end process;
--	
--
-------------------------------------------------------------------------------------
-- END MODULE TO DRIVE A SINGLE COLOR WITH 8 BRIGHTNESS LEVELS MANUALLY (SWITCHES) --
-------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
---------- START MODULE LED FADING BLOCK FOR JUST ONE COLOR (GREEN) ------------------
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
--				ck_en 	<= '1';				  -- When ck_en = '1', LED assume the current color
--			end if;
--		end if;
--end process;
--
--
------- FADING AUX ------ 
--FLIP_ADD_ODD_AUX : process (ck, reset) 
--begin
--	if (reset= '1') then						-- this process flips the green signal's bit and adds/odds an offset for the brightness
--		green_aux 		<= (others => '0');
--		red_aux 		<= (others => '0');
--		blue_aux 		<= (others => '0');
--	elsif (ck'event and ck = '1') then
--		if (ck_en = '1') then
--			if (inc = '1') then				-- add signal is drived by the FSM
--				green_aux (7 downto 0) <= 
--											   (green(0) &
--												green(1) &
--												green(2) &
--												green(3) &
--												green(4) &
--												green(5) &
--												green(6) &
--												green(7)) + 5 ;  -- add 5 as offset for brightness.
--																 -- for one color, brightness do 0-> 5 -> . . . -> 255
--			elsif (dec = '1') then
--				green_aux (7 downto 0) <= 
--											   (green(0) &
--												green(1) &
--												green(2) &
--												green(3) &
--												green(4) & 
--												green(5) & 
--												green(6) &
--												green(7)) - 5 ; -- FSM starts odding 5 for brightness when we reach the maximum of the brightness
--			end if;	
--		end if;
--	end if;
--
--end process;
--
-------- FADING ----- 								
--FLIP_ADD_ODD : process (ck, reset) 		-- this and the previous process complete the "flip -> add/odd -> flip" operation	
--	begin									-- we want to realize. In particular, this process gets the final reverse operation 
--		if (reset= '1') then
--			color 	<= (others => '0');
--			green 	<= (others => '0');
--			red 	<= (others => '0');
--			blue 	<= (others => '0');
--		elsif (ck'event and ck = '1') then
--			blue 			 <=	blue_aux;
--			red 			 <=	red_aux;
--			green 			 <= green_aux(0) &
--								green_aux(1) & 
--								green_aux(2) & 
--								green_aux(3) & 
--								green_aux(4) & 
--								green_aux(5) & 
--								green_aux(6) & 
--								green_aux(7);
--		end if;							
--		color <= std_logic_vector(blue & red & green);  -- here the color [23:0] output
--end process;
--
--
--
----- "Fade color" Finite State machine ----
-- FADE_1COLOR_LED_FSM : process (ck, reset)	
-- 	begin										-- this FSM drives the two phases of the LED, that is, "increase brightness" and "decrease brightness"
-- 		if (reset = '1') then					-- when the color takes a FF or 00 value
-- 			state1 	<= IDLE1;
-- 		elsif (ck'event and ck = '1') then
-- 			state1 	<= state1_nxt;
-- 		end if;
-- end process;
					
-- process (color, state1, btn)
-- 	begin
-- 		case state1 is
-- 			when IDLE1 =>
-- 				if (btn = '1') then
-- 					state1_nxt 	<= INC0;
-- 				else
-- 					state1_nxt 	<= IDLE1;
-- 				end if;		
-- 			when INC0 =>
-- 				if (green = x"FF") then
-- 					state1_nxt 	<= INC1;
-- 				else
-- 					state1_nxt 	<= INC0;
-- 				end if;
-- 			when INC1 =>
-- 				if (green = x"00") then
-- 					state1_nxt 	<= INC0;
-- 				else
-- 					state1_nxt 	<= INC1;
-- 				end if;
				
-- 			when others => 
-- 					state1_nxt 	<= IDLE1;
-- 		end case;
			
-- 	end process;
							
-- process (state1)
-- 	begin
-- 		case state1 is
-- 				when IDLE1 =>            
-- 					inc       <= '0';
-- 					dec       <= '0';
-- 				when INC0 =>				
-- 					inc       <= '1';
-- 					dec       <= '0';
-- 				when INC1 =>				
-- 					inc       <= '0';
-- 					dec       <= '1';
				
-- 				when others => 
-- 					inc       <= '0';
-- 					dec       <= '0';
-- 		end case;
-- end process;
--
--
--------------------------------------------------------------------------------
----------------- END LED FADING BLOCK FOR JUST ONE COLOR (GREEN) --------------
--------------------------------------------------------------------------------

----------------------------------------------------------------------------
-------------------- START LED FADING BLOCK --------------------------------
----------------------------------------------------------------------------

--- FREQUENCY DIVISOR -----
FREQ_DIV : process (ck, reset) 
	begin
		if (reset = '1') then
				
			cnt_div <= (others => '0');
			ck_en <= '0';
		
		elsif (ck'event and ck = '1') then
			if (cnt_div < 124999) then		-- The frequency for the LED must be > 400 Hz
				cnt_div <= cnt_div + 1;
				ck_en <= '0';
					
			else
				cnt_div <= (others => '0');
				ck_en <= '1';				-- When ck_en = '1', LED assume the current color
			end if;
		end if;
end process;
			

----- FADING AUX  ------  -- flip and add/odd an offset to the color chose by the sequence of the FSM
FLIP_ADD_ODD_AUX : process (ck, reset) 
begin
	if (reset = '1') then
		green_aux 		<= (others => '0');
		red_aux 		<= (others => '0');
		blue_aux 		<= (others => '0');
	elsif (ck'event and ck = '1') then
		if (ck_en = '1') then
			if (en_count1 = '1') then		-- en_count1 is generated by the FSM and selects what 8 bit's group must change
				if (inc = '1') then			
					blue_aux (7 downto 0) <=         		-- Put in an auxiliar signal the sum of blue flipped,
											(blue(0) &		--
											blue(1) &		--
											blue(2) &		--
											blue(3) &		--
											blue(4) &		--
											blue(5) &		--
											blue(6) &		--
											blue(7)) + 5 ;	-- plus an offset (to change the brightness)
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
				if (inc = '1') then	
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
				if (inc = '1') then	
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
		
------ FADING -----						-- this with the previous process complete the "flip -> add/odd -> flip" function
FLIP_ADD_ODD : process (ck, reset)	-- we want to realize. In particular, this process gets the final reverse operation 
	begin							-- and outputs the color signal.	
		if (reset = '1') then					-- This operation is necessary to respect
			color 	<= (others => '0');			-- the correct order bits to send to the LED.
			green 	<= (others => '0');			-- G R B = 7654321_7654321_7654321 where the
			red 	<= (others => '0');			-- rightmost bit of each 8 bit (of each color)
			blue 	<= (others => '0');			-- drive the highest brightness, the leftmost 
		elsif (ck'event and ck = '1') then		-- the lowest one.
			blue 			
					<= blue_aux(0) &
						blue_aux(1) & 
						blue_aux(2) & 
						blue_aux(3) & 
						blue_aux(4) & 
						blue_aux(5) & 
						blue_aux(6) & 
						blue_aux(7);  
			red 			
					<= red_aux(0) &
						red_aux(1) & 
						red_aux(2) & 
						red_aux(3) & 
						red_aux(4) & 
						red_aux(5) & 
						red_aux(6) & 
						red_aux(7);
			green			
					<= green_aux(0) &
						green_aux(1) & 
						green_aux(2) & 
						green_aux(3) & 
						green_aux(4) & 
						green_aux(5) & 
						green_aux(6) & 
						green_aux(7);
		end if;							
		color <= std_logic_vector(blue & red & green);  -- color [23:0] signal
end process;


	

	
	----- FIRST Finite State Machine to control LED fading
	
FADE_LED_FSM : process (ck, reset)  			-- In this FSM we set up a precise sequence to color the LED.
	begin						-- We add and odd bit to reach this sequence:
		if (reset = '1') then	-- 000000->FF0000->FF00FF->0000FF->00FF00->FFFF00->FF0000->...
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
					state1_nxt <= INC0;
				else
					state1_nxt <= IDLE1;
				end if;
			when INC0 =>
				if (green = x"FF") then
						state1_nxt <= INC1;
				else
					state1_nxt <= INC0;
				end if;
			when INC1 =>
				if (blue = x"FF") then
						state1_nxt <= DEC0;
				else
					state1_nxt <= INC1;
				end if;
			when DEC0 =>
				if (green = x"00") then
					state1_nxt <= INC2;
				else
					state1_nxt <= DEC0;
				end if;
			when INC2 =>
				if (red = x"fF") then
					state1_nxt <= DEC1;
				else
					state1_nxt <= INC2;
				end if;
			when DEC1 =>
				if (blue = x"00") then
					state1_nxt <= INC3;
				else
					state1_nxt <= DEC1;
				end if;
			when INC3 =>
				if (green = x"fF") then
					state1_nxt <= DEC2;
				else
					state1_nxt <= INC3;
				end if;
			when DEC2 =>
				if (red = x"00") then
					state1_nxt <= INC1;  -- CHECK1, not CHECK0 to avoid stepping up a clock cycle
				else
					state1_nxt <= DEC2;  
				end if;
								
			when others => 
				state1_nxt <= IDLE1;
		end case;
end process;
								
process (state1)
	begin
		case state1 is
			when IDLE1 =>            
				 inc       <= '0';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '0';
			when INC0 =>				-- color = x"000000"
				 inc       <= '1';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '1';
			when INC1 =>				-- color = x"FF0000"
				 inc       <= '1';
				 dec       <= '0';
				 en_count1 <= '1';
				 en_count2 <= '0';
				 en_count3 <= '0';
			when DEC0 =>				-- color = x"FF00FF"
				 inc       <= '0';
				 dec       <= '1';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '1';
			when INC2 =>				-- color = x"0000FF"
				 inc       <= '1';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '1';
				 en_count3 <= '0';
			when DEC1 =>				-- color = x"00FFFF"
				 inc       <= '0';
				 dec       <= '1';
				 en_count1 <= '1';
				 en_count2 <= '0';
				 en_count3 <= '0';
			when INC3 =>				-- color = x"00FF00"
				 inc       <= '1';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '1';
			when DEC2 =>				-- color = x"FFFF00"
				 inc       <= '0';
				 dec       <= '1';
				 en_count1 <= '0';
				 en_count2 <= '1';
				 en_count3 <= '0';
				 
			when others => 
				 inc       <= '0';
				 dec       <= '0';
				 en_count1 <= '0';
				 en_count2 <= '0';
				 en_count3 <= '0';
		end case;
end process;

------------------------------------------------------------------------------
---------------------- END LED FADING BLOCK ----------------------------------
------------------------------------------------------------------------------


----------- COUNTER SINGLE SIGNAL (1 -> 0 cycle) --------	
COUNTER_PERIOD : process (ck, reset)						
	begin													
		if (reset = '1') then								
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
		
RC_COUNTER_PERIOD : process (count_tmp)				-- at time_up0 	=> hit_up_0 = 1
	begin											-- at time_up1  => hit_up_1 = 1
		if (count_tmp < tot_count_tmp - 1) then		-- at time_max 	=> hit_down_0, hit_down_1 = 1
				if (count_tmp = time_up0 - 1) then	-- We use a single counter to drive the system counting part
						hit_down_1 		<= '0';
						hit_up_1 		<= '0';
						hit_down_0 		<= '0';
						hit_up_0 		<= '1';
				elsif (count_tmp = time_up1 - 1) then	
						hit_down_1 		<= '0';
						hit_up_1		<= '1';
						hit_down_0		<= '0';
						hit_up_0 		<= '0';	
				else
						hit_down_1 		<= '0';									
						hit_up_1 		<= '0';
						hit_down_0 		<= '0';
						hit_up_0 		<= '0';
				end if;	
		else
				hit_down_1 <= '1';									
				hit_up_1 <= '0';
				hit_down_0 <= '1';
				hit_up_0 <= '0';
		end if;
					
end process;
									

	----------- COUNTER SINGLE SIGNAL (24 BIT) --------		
COUNTER_24_BIT : process (ck, reset)				-- this module gives a hit_24 = 1 when the 24bits have been sent.
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
COUNTER_RESET_TIME : process (ck, reset)	-- this module counts how long should stay in the RST_CODE state
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

	------------- SHIFTER REGISTER ------	
SHIFT_REGISTER : process (ck, reset)	-- a simple shift register that sets the leftmost 
	begin								-- bits to 0 and provides the LSB as output to s_value
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

s_value <= std_logic(reg(0)); -- s_value represent the bit we are current extracting (the LSB)
							  -- from the 24 bit "color" signal transmitted to turn on the LED

	------------ "Send data to LED" finite states machine ------
FSM : process (ck, reset)	-- this FSM leads the 24 bits stream as
begin						-- the protocol of WS2812 LED want
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
						load 		<= '0';  
						shift		<= '0';
						clr_tmp 	<= '0';
						en_tmp 		<= '0';
						clr_24 		<= '0';
						en_24 		<= '0';
						clr_50 		<= '1'; -- clr_50
						en_50 		<= '0';
						s_out 		<= '0';
		when INIT => 
						load 		<= '1';	-- load
						shift 		<= '0';
						clr_tmp		<= '1';	-- clr_tmp
						en_tmp 		<= '0';
						clr_24		<= '1';	-- clr_24
						en_24 		<= '0';
						clr_50		<= '1';	-- clr_50
						en_50 		<= '0';
						s_out 		<= '0';
		when START => 
						load 		<= '0'; 
						shift 		<= '0'; 
						clr_tmp 	<= '0';
						en_tmp 		<= '0';  
						clr_24 		<= '0';
						en_24 		<= '0';  
						clr_50 		<= '1';	-- clr_50
						en_50 		<= '0';
						s_out 		<= '0';
		when UP1 => 
						load 		<= '0';
						shift		<= '0';
						clr_tmp 	<= '0';
						en_tmp 		<= '1';	-- en_tmp
						clr_24 		<= '0';
						en_24 		<= '0';
						clr_50 		<= '0';
						en_50 		<= '0';
						s_out 		<= '1';  
		when DOWN1 => 
						load 		<= '0';
						shift 		<= '0';
						clr_tmp 	<= '0';
						en_tmp 		<= '1';	-- en_tmp
						clr_24 		<= '0';
						en_24 		<= '0';
						clr_50 		<= '0';
						en_50 		<= '0';
						s_out 		<= '0';
		when UP0 => 
						load 		<= '0';
						shift 		<= '0';  
						clr_tmp 	<= '0';
						en_tmp 		<= '1';	-- en_tmp
						clr_24 		<= '0';
						en_24 		<= '0';
						clr_50 		<= '0';
						en_50 		<= '0';
						s_out 		<= '1';  	
		when DOWN0 => 
						load 		<= '0';
						shift 		<= '0';
						clr_tmp 	<= '0';
						en_tmp 		<= '1';	-- en_tmp
						clr_24 		<= '0';
						en_24 		<= '0';
						clr_50 		<= '0';
						en_50 		<= '0';
						s_out 		<= '0';
		when SH => 
						load 		<= '0';
						shift		<= '1';	-- shift
						clr_tmp 	<= '0'; 
						en_tmp 		<= '0';
						clr_24 		<= '0';
						en_24 		<= '1'; -- en_24
						clr_50 		<= '0';
						en_50 		<= '0';
						s_out 		<= '0';
		when RST_CODE => 
						load 		<= '0';
						shift 		<= '0';
						clr_tmp 	<= '0';
						en_tmp 		<= '0';
						clr_24 		<= '0';
						en_24 		<= '0';
						clr_50 		<= '0';
						en_50 		<= '1';	--en_50
						s_out 		<= '0';	
						
		when others =>              -- clear all	
						load 		<= '0';
						shift 		<= '0';
						clr_tmp 	<= '1';
						en_tmp 		<= '0';
						clr_24 		<= '1';
						en_24 		<= '0';  
						clr_50 		<= '1';
						en_50 		<= '0';
						s_out 		<= '0';				
	end case;
end process;							

end Behavioral;
