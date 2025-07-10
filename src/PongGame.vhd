library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------
-- 
-- Name: PongGame
-- Designers: Abhijeet Surakanti, Salini Ambadapudi, Gurbir Singh
--
--     This component implements the main logic of the Pong
--     game system. It uses a state machine as its primary
--     control architecture.
--
--     It is a synchronous component that takes in two inputs:
--     leftPaddle, and rightPaddle which act as the primary
--     interface through which the players play the game.
--
--     It also has three outputs: ledField(16), leftScore(7),
--     and rightScore(7). The ledField output is directly
--     connected to the LED array on the Basys3. The leftScore
--     and rightScore signals are connected to the 7-segment
--     displays. They count up to 99.
--
--------------------------------------------------------------

entity PongGame is
	port (
		reset: in std_logic;
		clock: in std_logic;
		leftPaddle: in std_logic;
		rightPaddle: in std_logic;

		ledField: out std_logic_vector(15 downto 0);
		leftScore: out std_logic_vector(6 downto 0);
		rightScore: out std_logic_vector(6 downto 0)
	);
end PongGame;
