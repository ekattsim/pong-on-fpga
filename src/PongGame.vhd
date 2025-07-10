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

architecture PongGame_ARCH of PongGame is

	-- general constants
	constant ACTIVE: std_logic := '1';
	
	-- state machine declarations
	type States_t is (RIGHT_SERVE, LEFT_SERVE,
					  RIGHT_MOVING, LEFT_MOVING,
					  RIGH_HITZONE, LEFT_HITZONE,
					  RIGHT_ROUND_OVER, LEFT_ROUND_OVER,
					  RIGHT_GAME_OVER, LEFT_GAME_OVER);
	signal prevState: States_t;
	signal currentState: States_t;
	signal nextState: States_t;

	-- win pattern declarations
	constant LEFT_WIN_PATTERN: std_logic_vector(15 downto 0) := "1111111100000000";
	constant RIGHT_WIN_PATTERN: std_logic_vector(15 downto 0) := "0000000011111111";
	constant PATTERN_PERIOD: integer := (100000000)-1;
	signal winPattern: std_logic_vector(15 downto 0);
	signal patternMode: std_logic;
	signal startTimerEn: std_logic;
	signal timerDoneEn: std_logic;

	-- speed control declarations
	signal speedRstEn: std_logic;
	signal speedIncEn: std_logic;
	signal rateEn: std_logic;

	-- ball position declarations
	signal ballPosNum: std_logic_vector(3 downto 0);
	signal ballPosLed: std_logic_vector(15 downto 0);

	-- score-keeping declarations
	signal leftWinEn: std_logic;
	signal rightWinEn: std_logic;
	signal leftScoreSignal: std_logic_vector(3 downto 0);
	signal rightScoreSignal: std_logic_vector(3 downto 0);


	----------------------------------------------------------
	-- A basic counter that counts from 0 to 99. The count
	-- signal is incremented every time countEnable pulses.
	-- After 99, the counter stops counting.
	----------------------------------------------------------
	procedure count_to_99(signal reset: in std_logic;
						  signal clock: in std_logic;
						  signal countEnable: in std_logic;
						  signal count: inout integer) is
	begin
		if (reset=ACTIVE) then
			count <= 0;
		elsif (rising_edge(clock)) then
			if (countEnable=ACTIVE) then
				if (count>=0 and count<99) then
					count <= count + 1;
				else
					count <= 99;
				end if;
			end if;
		end if;
	end count_to_99;
