----------------------------------------------------------------------------------
-- Description: Ties the PongGame and SevenSegmentDriver components to the 
-- Basys3 board
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.physical_io_package.ALL;

entity PongGame_Basys3 is
    port (
		reset: in std_logic;
		clk: in std_logic;
        btnL: in std_logic;
        btnR: in std_logic;
        seg: out std_logic_vector(6 downto 0);
        an: out std_logic_vector(3 downto 0);
        led: out std_logic_vector(15 downto 0)
	);
end PongGame_Basys3;

architecture PongGame_Basys3_ARCH of PongGame_Basys3 is
    
    component PongGame is
        port (
			reset: in std_logic;
			clock: in std_logic;
			leftPaddle: in std_logic;
			rightPaddle: in std_logic;

			ledField: out std_logic_vector(15 downto 0);
			leftScore: out std_logic_vector(6 downto 0);
			rightScore: out std_logic_vector(6 downto 0)
		);
	end component;

begin


end PongGame_Basys3_ARCH;
