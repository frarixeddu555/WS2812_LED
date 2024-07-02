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
			  ck : in std_logic;                                            -- 50MHz
			  reset : in std_logic;
--			  color : in  STD_LOGIC_VECTOR (23 downto 0);                   -- be decoded by the DECODER process
			  switch : in  STD_LOGIC_VECTOR (2 downto 0);
           btn : in  STD_LOGIC;
           s_out : out  STD_LOGIC);
end TX_WS2812;

architecture Behavioral of TX_WS2812 is
	
	-- constants
	constant 	tot_count_tmp 													: integer := 63;  -- cycles to send one data of 24.
	constant 	time_up1 														: integer := 40; -- set time up1. time_down1 is tot_count_tmp - time_up1;
	constant 	time_up0 														: integer := 18; -- set time up0. time_down0 is tot_count_tmp - time_up0;
	constant 	tot_count_24 													: integer := 24;  -- number of bit to send
	constant 	tot_count_50 													: integer := 2500; -- number of waiting clock cycles to refresh 
	-- decoder
	signal color : STD_LOGIC_VECTOR (23 downto 0);
	-- counter single signal 0->1
	signal 	hit_down_1, hit_down_0, hit_up_1, hit_up_0 				: std_logic;
	signal 	clr_tmp, en_tmp 													: std_logic;
	signal 	count_tmp 															: unsigned (6 downto 0);
	-- counter 24 bit signal
	signal 	hit_24 																: std_logic;
	signal 	clr_24, en_24														: std_logic;
	signal 	count_24 															: unsigned (4 downto 0);
	-- counter 50 us
	signal hit_50 																	: std_logic;
	signal clr_50, en_50 														: std_logic;
	signal count_50 : unsigned (11 downto 0);
	-- shifter register
	signal load, shift 															: std_logic;
	signal s_value 																: std_logic;
	signal reg 																		: unsigned (23 downto 0);
	-- finite states machine
	type estado is (IDLE, START, INIT, UP0, UP1, DOWN0, DOWN1, SH, RST_CODE);
		signal state, state_nxt : estado;
	
begin

------ DECODER -----

	DECODER_COLOR : process (switch)
		begin
						case switch is 
						
								when "000" => 
														color <= "000000000000000000000000";
								when "001" => 
														color <= "111111110000000000000000";
								when "010" => 
														color <= "000000001111111100000000";
								when "011" => 
														color <= "111111111111111100000000";
								when "100" => 
														color <= "000000000000000011111111";
								when "101" => 
														color <= "111111110000000011111111";
								when "110" => 
														color <= "000000001111111111111111";
								when "111" => 
														color <= "111111111111111111111111";
								when others => 
														color <= "000000000000000000000000";
						end case;
	end process;
							
----------- COUNTER SINGLE SIGNAL (1 -> 0 cycle) --------                  -- at time_up0  =>  hit_up_0 = 1
	COUNTER_PERIOD : process (ck, reset)												-- at time_up1  => hit_up_1 = 1
		begin																						-- at time_max => hit_down_0, hit_down_1 = 1
						if (reset = '1') then                                    -- I wanted to use a single counter to drive the system counting part
						
								count_tmp <= (others => '0');
								
						elsif (ck'event and ck = '1') then
								if (clr_tmp = '1') then
											
--										hit_down_1 <= '0';									
--										hit_up_1 <= '0';
--										hit_down_0 <= '0';
--										hit_up_0 <= '0';
										
										count_tmp <= (others => '0');	
										
								elsif (en_tmp = '1') then
												
												if (count_tmp < tot_count_tmp - 1) then  
												
														count_tmp <= count_tmp + 1;
														
--														if (count_tmp = time_up0) then
--																
--																hit_down_1 <= '0';
--																hit_up_1 <= '0';
--																hit_down_0 <= '0';
--																hit_up_0 <= '1';
--												
--														elsif (count_tmp = time_up1) then
--																
--																hit_down_1 <= '0';
--																hit_up_1 <= '1';
--																hit_down_0 <= '0';
--																hit_up_0 <= '0';
--																
--														else
--														
--																hit_down_1 <= '0';									
--																hit_up_1 <= '0';
--																hit_down_0 <= '0';
--																hit_up_0 <= '0';
--																
--														end if;
														
												else
												
														count_tmp <= (others => '0');
														
--														hit_down_1 <= '1';									
--														hit_up_1 <= '0';
--														hit_down_0 <= '1';
--														hit_up_0 <= '0';
												
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
						
								count_24 <= (others => '1');
								
						elsif (ck'event and ck = '1') then
								if (clr_24 = '1') then
								
										count_24 <= (others => '0');
										
								elsif (en_24 = '1') then
										if (count_24 < tot_count_24 - 1) then
										
												count_24 <= count_24 + 1;	
--												hit_24 <= '0'; 
																								
										else
													 
												count_24 <= (others => '0');
--												hit_24 <= '1';
												
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
										

------------ FINITE STATE MACHINE ------
	FSM : process (ck, reset)
		begin
						if (reset = '1') then
						
								state <= IDLE;
								
						elsif (ck'event and ck = '1') then
						
								state <= state_nxt;
								
						end if;
	end process;
	
--	process (state, btn, s_value, hit_up_1, hit_up_0, hit_down_0, hit_down_1, hit_24, hit_50)        -- driven by a BTN and SWITCH signal
--		begin
--						case state is
--											when IDLE => 
--											
--																if (btn = '1') then
--																		state_nxt <= INIT;
--																else
--																		state_nxt <= IDLE;
--																end if;
--																
--											when INIT => 
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																else
--																		state_nxt <= START;
--																end if;
--																
--											when START => 
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																elsif (s_value = '1') then
--																		state_nxt <= UP1;
--																else
--																		state_nxt <= UP0;
--																end if;
--																
--											when UP1 =>
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																elsif (hit_up_1 = '1') then
--																		state_nxt <= DOWN1;
--																else
--																		state_nxt <= UP1;
--																end if;
--																
--											when DOWN1 =>
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																elsif (hit_down_1 = '1') then
--																		state_nxt <= SH;
--																else
--																		state_nxt <= DOWN1;
--																end if;
--																
--											when UP0 =>
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																elsif (hit_up_0 = '1') then
--																		state_nxt <= DOWN0;
--																else
--																		state_nxt <= UP0;
--																end if;
--																
--											when DOWN0 =>
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																elsif (hit_down_0 = '1') then
--																		state_nxt <= SH;
--																else
--																		state_nxt <= DOWN0;
--																end if;
--																
--											when SH =>
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																elsif (hit_24 = '1') then
--																		state_nxt <= RST_CODE;
--																else
--																		state_nxt <= START;
--																end if;
--																
--											when RST_CODE =>
--											
--																if (btn = '1') then
--																		state_nxt <= IDLE;
--																elsif (hit_50 = '1') then
--																		state_nxt <= INIT;
--																else
--																		state_nxt <= RST_CODE;
--																end if;
--																
--											when others =>	
--																state_nxt <= IDLE;

	RC_FSM : process (state, btn, s_value, hit_up_1, hit_up_0, hit_down_0, hit_down_1, hit_24, hit_50)    -- driven just by SWITCH signal
		begin
						case state is
											when IDLE => 
											
																		state_nxt <= INIT;
																
											when INIT => 
											
																		state_nxt <= START;
																
											when START => 
											
																if (s_value = '1') then
																		state_nxt <= UP1;
																else
																		state_nxt <= UP0;
																end if;
																
											when UP1 =>
											
															
																if (hit_up_1 = '1') then
																		state_nxt <= DOWN1;
																else
																		state_nxt <= UP1;
																end if;
																
											when DOWN1 =>
											
																if (hit_down_1 = '1') then
																		state_nxt <= SH;
																else
																		state_nxt <= DOWN1;
																end if;
																
											when UP0 =>
											
																if (hit_up_0 = '1') then
																		state_nxt <= DOWN0;
																else
																		state_nxt <= UP0;
																end if;
																
											when DOWN0 =>

																if (hit_down_0 = '1') then
																		state_nxt <= SH;
																else
																		state_nxt <= DOWN0;
																end if;
																
											when SH =>
											
																if (hit_24 = '1') then
																		state_nxt <= RST_CODE;
																else
																		state_nxt <= START;
																end if;
																
											when RST_CODE =>
											
																if (hit_50 = '1') then
																		state_nxt <= INIT;
																else
																		state_nxt <= RST_CODE;
																end if;
																
											when others =>	
																state_nxt <= IDLE;
						end case;
	end process;
											
	RC_FSM_OUTPUTS : process (state)
		begin
						case state is
											when IDLE => 
											
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

