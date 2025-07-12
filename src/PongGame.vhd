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
	constant CLOCK_RATE: integer := 100000000;
	type Player_t is (RIGHT, LEFT);
	
	-- state machine declarations
	type States_t is (RIGHT_SERVE, LEFT_SERVE,
					  RIGHT_MOVING, LEFT_MOVING,
					  RIGHT_HITZONE, LEFT_HITZONE,
					  RIGHT_ROUND_OVER, LEFT_ROUND_OVER,
					  RIGHT_GAME_OVER, LEFT_GAME_OVER);
	signal prevState: States_t;
	signal currentState: States_t;
	signal nextState: States_t;

	-- win pattern declarations
	constant LEFT_WIN_PATTERN: std_logic_vector(15 downto 0) := "1111111100000000";
	constant RIGHT_WIN_PATTERN: std_logic_vector(15 downto 0) := "0000000011111111";
	constant PATTERN_PERIOD: integer := (100000000)-1;

	signal winMode: Player_t;
	signal patternMode: std_logic;
	signal winPattern: std_logic_vector(15 downto 0);
	signal startTimerEn: std_logic;
	signal timerDoneEn: std_logic;

	-- speed control declarations
	constant SPEED_0: integer := 0;
	constant SPEED_1: integer := CLOCK_RATE-1;
	constant SPEED_2: integer := (CLOCK_RATE/2)-1;
	constant SPEED_3: integer := (CLOCK_RATE/3)-1;
	constant SPEED_4: integer := (CLOCK_RATE/4)-1;
	constant SPEED_5: integer := (CLOCK_RATE/5)-1;
	constant SPEED_6: integer := (CLOCK_RATE/6)-1;
	constant SPEED_7: integer := (CLOCK_RATE/7)-1;
	constant SPEED_8: integer := (CLOCK_RATE/8)-1;
	signal speedRstEn: std_logic;
	signal speedIncEn: std_logic;
	signal rateEn: std_logic;

	-- ball position declarations
	signal serveMode: std_logic;
	signal receivingPlayerMode: Player_t;
	signal ballPosNum: integer range -1 to 16; -- -1 and 16 are needed for "misses"
	signal ballPosLed: std_logic_vector(15 downto 0);

	-- score-keeping declarations
	signal leftWinEn: std_logic;
	signal rightWinEn: std_logic;
	signal leftScoreSignal: integer range 0 to 99;
	signal rightScoreSignal: integer range 0 to 99;


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

begin

	----------------------------------------------------------
	-- Stores prevState as well because STATE_TRANSITION needs
	-- this for generating pulses.
	----------------------------------------------------------
	STATE_REGISTERS: process(reset, clock)
	begin
		if (reset=ACTIVE) then
			prevState <= RIGHT_SERVE;
			currentState <= RIGHT_SERVE;
		elsif (rising_edge(clock)) then
			prevState <= currentState;
			currentState <= nextState;
		end if;
	end process;


	----------------------------------------------------------
	-- This block handles control signal generation and state
	-- transitions.
	----------------------------------------------------------
	STATE_TRANSITION: process(leftPaddle, rightPaddle,
							  prevState, currentState,
							  ballPosNum, timerDoneEn,
							  leftScoreSignal, rightScoreSignal)
	begin
		-- set default outputs
		nextState <= currentState;
		speedRstEn <= not ACTIVE;
		speedIncEn <= not ACTIVE;
		receivingPlayerMode <= LEFT; -- just a default (no priority for LEFT)
		serveMode <= not ACTIVE;
		patternMode <= not ACTIVE;
		winMode <= LEFT;
		leftWinEn <= not ACTIVE;
		rightWinEn <= not ACTIVE;
		startTimerEn <= not ACTIVE;

		case (currentState) is
			when RIGHT_SERVE =>
				serveMode <= ACTIVE;

				if (rightPaddle=ACTIVE) then
					nextState <= LEFT_MOVING;
				end if;

			when LEFT_SERVE =>
				receivingPlayerMode <= RIGHT;
				serveMode <= ACTIVE;

				if (leftPaddle=ACTIVE) then
					nextState <= RIGHT_MOVING;
				end if;

			when RIGHT_MOVING =>
				if (currentState/=prevState) then
					speedIncEn <= ACTIVE;
				end if;
				receivingPlayerMode <= RIGHT;

				if (ballPosNum=0) then
					nextState <= RIGHT_HITZONE;
				end if;
				if ((ballPosNum/=0) and (rightPaddle=ACTIVE)) then
					nextState <= LEFT_ROUND_OVER;
				end if;

			when LEFT_MOVING =>
				if (currentState/=prevState) then
					speedIncEn <= ACTIVE;
				end if;

				if (ballPosNum=15) then
					nextState <= LEFT_HITZONE;
				end if;
				if ((ballPosNum/=15) and (leftPaddle=ACTIVE)) then
					nextState <= RIGHT_ROUND_OVER;
				end if;

			when RIGHT_HITZONE =>
				receivingPlayerMode <= RIGHT;

				if ((ballPosNum=0) and (rightPaddle=ACTIVE)) then
					nextState <= LEFT_MOVING;
				end if;
				if (ballPosNum=-1) then
					nextState <= LEFT_ROUND_OVER;
				end if;

			when LEFT_HITZONE =>
				if ((ballPosNum=15) and (leftPaddle=ACTIVE)) then
					nextState <= RIGHT_MOVING;
				end if;
				if (ballPosNum=16) then
					nextState <= RIGHT_ROUND_OVER;
				end if;

			when RIGHT_ROUND_OVER =>
				if (currentState/=prevState) then
					speedRstEn <= ACTIVE;
					rightWinEn <= ACTIVE;
					startTimerEn <= ACTIVE;
				end if;
				patternMode <= ACTIVE;
				winMode <= RIGHT;

				if (timerDoneEn=ACTIVE) then
					if ((rightScoreSignal>=7) and
						(rightScoreSignal-leftScoreSignal>=2)) then
						nextState <= RIGHT_GAME_OVER;
					else
						nextState <= LEFT_SERVE;
					end if;
				end if;

			when LEFT_ROUND_OVER =>
				if (currentState/=prevState) then
					speedRstEn <= ACTIVE;
					leftWinEn <= ACTIVE;
					startTimerEn <= ACTIVE;
				end if;
				patternMode <= ACTIVE;

				if (timerDoneEn=ACTIVE) then
					if ((leftScoreSignal>=7) and
						(leftScoreSignal-rightScoreSignal>=2)) then
						nextState <= LEFT_GAME_OVER;
					else
						nextState <= RIGHT_SERVE;
					end if;
				end if;

			when RIGHT_GAME_OVER =>
				patternMode <= ACTIVE;
				winMode <= RIGHT;

			when LEFT_GAME_OVER =>
				patternMode <= ACTIVE;
		end case;

	end process;

end PongGame_ARCH;
