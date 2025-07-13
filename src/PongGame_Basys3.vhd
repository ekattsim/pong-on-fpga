----------------------------------------------------------------------------------
-- Description: Ties the PongGame and SevenSegmentDriver components to the 
-- Basys3 board
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity PongGame_Basys3 is
    port (
        btnL: in std_logic;
        btnR: in std_logic;
        seg: out std_logic_vector(6 downto 0);
        an: out std_logic_vector(3 downto 0);
        led: out std_logic_vector(15 downto 0);
    );
end PongGame_Basys3;

architecture PongGame_Basys3_ARCH of PongGame_Basys3 is
    
    component SevenSegmentDriver
		port (
			reset: in std_logic;
			clock: in std_logic;

			digit3: in std_logic_vector(3 downto 0);    --leftmost digit
			digit2: in std_logic_vector(3 downto 0);    --2nd from left digit
			digit1: in std_logic_vector(3 downto 0);    --3rd from left digit
			digit0: in std_logic_vector(3 downto 0);    --rightmost digit

			blank3: in std_logic;    --leftmost digit
			blank2: in std_logic;    --2nd from left digit
			blank1: in std_logic;    --3rd from left digit
			blank0: in std_logic;    --rightmost digit

			sevenSegs: out std_logic_vector(6 downto 0);    --MSB=g, LSB=a
			anodes:    out std_logic_vector(3 downto 0)    --MSB=leftmost digit
	);
	end component;

    component PongGame is
        port (
            leftPaddle: in std_logic;
            rightPaddle: in std_logic;
            
        );
end component;
begin


end PongGame_Basys3_ARCH;
