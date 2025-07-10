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

component PongGame is
    port (
        leftPaddle: in std_logic;
    );
end component;

component SevenSegmentDriver is
    port(
        seg: out std_logic_vector(6 downto 0);
    );
end component;

architecture PongGame_Basys3_ARCH of PongGame_Basys3 is

begin


end PongGame_Basys3_ARCH;
