-- VHDL project: VHDL code for car parking system

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity final_project is
port 
(
  CLOCK_50: in std_logic;-- clock 
  front_sensor, back_sensor: in std_logic; -- two sensor in front and behind the gate
  SW : in std_logic_vector(4 downto 0);   -- input password and reset button
  LEDR: out std_logic_vector(9 downto 0); -- signaling LEDs
  HEX1, HEX0: out std_logic_vector(6 downto 0) -- 7-segment Display 
);
end final_project;

architecture Beh of final_project is
-- FSM States
type FSM_States is (IDLE,WAIT_PASSWORD,WRONG_PASS,RIGHT_PASS,STOP);
signal current_state,next_state: FSM_States;
signal counter_wait:integer range 0 to 49999999 := 0;
signal reset_n,right_tmp, wrong_tmp: std_logic;
signal password_1, password_2: std_logic_vector(1 downto 0); -- input password 
signal sec :std_logic_vector(2 downto 0);
signal sec_len1 : std_logic_vector(2 downto 0):="101";



begin

password_1<=SW(3 downto 2); 
password_2<=SW(1 downto 0); 
reset_n <= SW(4);

-- this code block is about the memory element(state register) with state table
process(CLOCK_50,reset_n,current_state,front_sensor,password_1,password_2,back_sensor,counter_wait)
begin
 if(reset_n='0') then
  current_state <= IDLE;
 elsif(rising_edge(CLOCK_50)) then
  current_state <= next_state;
  if (counter_wait < 49999999) then   -- change 50mhz to sec
	 counter_wait <= counter_wait + 1;
	else 
	 counter_wait <= 0;
  

  
  
 case current_state is 
 
 when IDLE =>
 if(front_sensor = '1') then -- if the front sensor is on,
                             -- there is a car going to the gate
  next_state <= WAIT_PASSWORD;-- wait for password
 else
  next_state <= IDLE;
 end if;
 
 when WAIT_PASSWORD =>
 
 if (sec < sec_len1) then
			sec <= sec + 1;
					
					 
  next_state <= WAIT_PASSWORD;-- check password after 5 sec
 else                     
 if((password_1="01")and(password_2="10")) then
 next_state <= RIGHT_PASS; -- if password is correct, let them in
 elsif((password_1="00")and(password_2="00")) then
  next_state <= WAIT_PASSWORD;
 else
 next_state <= WRONG_PASS; -- if not, tell them wrong pass by lighting LEDR(1) and
                           -- let them input the password again
 end if;
 end if;
 
 when WRONG_PASS =>
 
 if (sec < sec_len1) then
			sec <= sec + 1;
  elsif((password_1="01")and(password_2="10")) then
 next_state <= RIGHT_PASS;-- if password is correct, let them in
else
 next_state <= WRONG_PASS;-- if not, they cannot get in until the password is right
     sec <="000";
  end if;
  
 when RIGHT_PASS =>
 if (sec < sec_len1) then
		 sec <= sec + 1;
elsif(front_sensor='1' and back_sensor = '1') then
		sec <= "000";
 next_state <= STOP;  -- if the gate is opening for the current car, and the next car come, 
                      -- STOP the next car and require password
                      -- the current car going into the car park
  elsif(back_sensor= '1') then
                             -- if the current car passed the gate and going into the car park
                             -- and there is no next car, go to IDLE
 next_state <= IDLE;
  else
 next_state <= RIGHT_PASS;
  end if;
    

when STOP =>	
    if (sec < sec_len1) then
			 sec <= sec + 1;
					 
	 next_state <= WAIT_PASSWORD;
else
if((password_1="01")and(password_2="10"))then  -- check password of the next car
                                            -- if the pass is correct, let them in
  next_state <= RIGHT_PASS;
  elsif((password_1="00")and(password_2="00")) then
  next_state <= WAIT_PASSWORD;
  else
 next_state <= STOP;
  end if;
 end if;
    

 when others => next_state <= IDLE;
 end case;
 
 
 -- wait for password

 if(reset_n='0') then
 sec<= (others => '0');
 elsif(rising_edge(CLOCK_50))then
  if(current_state=WAIT_PASSWORD)then
  
  if (sec < sec_len1) then
   sec <= sec + 1;
	else 
		sec<= (others => '0');			 
  end if;
  end if;
 end if;
 end if; 
 end if;
 end process;
 
 -- output 
 process(CLOCK_50) 
 begin
 if(reset_n='0') then
 HEX0 <= "1111111"; -- off
 HEX1 <= "1111111"; -- off
 
 
 elsif(rising_edge(CLOCK_50)) then
 case(current_state) is

 when IDLE => 
 wrong_tmp <= '0';
 right_tmp <= '0';
 HEX1 <= "1111111"; -- off
 HEX0 <= "1111111"; -- off
 LEDR(9)<= front_sensor;

 when WAIT_PASSWORD =>
 wrong_tmp <= '0';
 right_tmp <= '1'; 
                     -- LEDR(1) turn on and Display 7-segment LED as EN to let the car know they need to input password
 HEX1 <= "0000110"; -- E 
 HEX0 <= "1001000"; -- n 

 when WRONG_PASS =>
 wrong_tmp <= '0'; -- if password is wrong, LEDR(1) in on
 right_tmp <= not right_tmp;
 HEX1 <= "0000110"; -- E
 HEX0 <= "0001000"; -- A


when RIGHT_PASS =>
 wrong_tmp <= not wrong_tmp;
 right_tmp <= '0'; -- if password is correct, LEDR(0) is on.
 HEX1 <= "1000010"; -- G
 HEX0 <= "1000000"; -- 0 
 LEDR(8)<=back_sensor;
 LEDR(9)<='0';

 when STOP =>
 wrong_tmp <= '0';
 right_tmp <= not right_tmp; -- Stop the next car and LEDR(1) is on.
 HEX1 <= "0010010"; -- 5
 HEX0 <= "0001100"; -- P 
 LEDR(8)<='1';
 LEDR(9)<='1';

 when others => 
 wrong_tmp <= '0';
 right_tmp <= '0';
 HEX1 <= "1111111"; -- off
 HEX0 <= "1111111"; -- off
  end case;
 end if;
 end process;
  LEDR(1) <= right_tmp;
  LEDR(0) <= wrong_tmp;

 --  second display on LEDRs
 process(sec)
 begin
  case sec is
   when "000" => LEDR(7 downto 5) <= "000";
   when "001" => LEDR(7 downto 5) <= "001";
   when "010" => LEDR(7 downto 5) <= "010";
   when "011" => LEDR(7 downto 5) <= "011";
   when "100" => LEDR(7 downto 5) <= "100";
   when "101" => LEDR(7 downto 5) <= "101";
   when "110" => LEDR(7 downto 5) <= "110";
   when "111" => LEDR(7 downto 5) <= "111";
  end case;
 end process;
  
  
end Beh;