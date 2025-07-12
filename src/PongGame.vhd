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
	constant PATTERN_PERIOD: integer := CLOCK_RATE-1;

	signal winMode: Player_t;
	signal patternMode: std_logic;
	signal winPattern: std_logic_vector(15 downto 0);
	signal startTimerEn: std_logic;
	signal timerDoneEn: std_logic;

	-- speed control declarations
	type ArrayInt_t is array (0 to 8) of integer;
	constant SPEED_COUNTS: ArrayInt_t := (0, CLOCK_RATE-1, (CLOCK_RATE/2)-1,
										  (CLOCK_RATE/3)-1, (CLOCK_RATE/4)-1,
										  (CLOCK_RATE/5)-1, (CLOCK_RATE/6)-1,
										  (CLOCK_RATE/7)-1, (CLOCK_RATE/8)-1);
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

	----------------------------------------------------------
	-- Scorekeeper storage blocks
	----------------------------------------------------------
	LEFT_SCORE: count_to_99(reset, clock, leftWinEn, leftScoreSignal);
	RIGHT_SCORE: count_to_99(reset, clock, rightWinEn, rightScoreSignal);
	leftScore <= std_logic_vector(to_unsigned(leftScoreSignal, 7));
	rightScore <= std_logic_vector(to_unsigned(rightScoreSignal, 7));

	----------------------------------------------------------
	-- Timer process that starts counting on the startTimerEn
	-- pulse upto PATTERN_PERIOD and pulses timerDoneEn after
	-- finishing.
	----------------------------------------------------------
	PATTERN_TIMER: process(reset, clock)
		variable countMode: std_logic;
		variable counter: integer range 0 to PATTERN_PERIOD;
	begin
		if (reset=ACTIVE) then
			timerDoneEn <= not ACTIVE;
			countMode := not ACTIVE;
			counter := 0;
		elsif (rising_edge(clock)) then
			timerDoneEn <= not ACTIVE;
			if (startTimerEn=ACTIVE) then
				countMode := ACTIVE;
				counter := 0;
			elsif (countMode=ACTIVE) then
				if (counter=PATTERN_PERIOD) then
					timerDoneEn <= ACTIVE;
					counter := 0;
					countMode := not ACTIVE;
				else
					counter := counter+1;
				end if;
			end if;
		end if;
	end process;

	PATTERN_GEN: with winMode select winPattern <=
		LEFT_WIN_PATTERN when LEFT,
		RIGHT_WIN_PATTERN when RIGHT;

	----------------------------------------------------------
	-- A timer with a configurable pulse rate: rateEn. Speed
	-- is reset by speedRstEn and incremented by speedIncEn.
	-- The available speeds are described by SPEED_COUNTS.
	----------------------------------------------------------
	SPEED_CONTROL: process(reset, clock)
		variable speedLevel: integer range 0 to 8;
		-- 1 sec requires the longest count
		variable counter: integer range 0 to SPEED_COUNTS(1);
	begin
		if (reset=ACTIVE) then
			rateEn <= not ACTIVE;
			speedLevel := 0;
			counter := 0;
		elsif (rising_edge(clock)) then
			rateEn <= not ACTIVE;

			if (speedRstEn=ACTIVE) then
				speedLevel := 0;
				counter := 0;
			elsif (speedIncEn=ACTIVE) then
				rateEn <= ACTIVE; -- immediately move ball on successful hit
				if (speedLevel<8) then
					speedLevel := speedLevel+1;
					counter := 0;
				end if;
			end if;

			if (counter=SPEED_COUNTS(speedLevel)) then
				rateEn <= ACTIVE;
				counter := 0;
			else
				counter := counter+1;
			end if;
		end if;
	end process;

	----------------------------------------------------------
	-- Control block that updates ballPosNum. In serve mode,
	-- it directly sets ball on one or the other end of the
	-- field. When not in serve mode, it increments/decrements
	-- on every rateEn pulse.
	----------------------------------------------------------
	BALL_POSITIONER: process(reset, clock)
	begin
		if (reset=ACTIVE) then
			ballPosNum <= 0;
		elsif (rising_edge(clock)) then
			if (serveMode=ACTIVE) then
				if (receivingPlayerMode=LEFT) then
					ballPosNum <= 0;
				elsif (receivingPlayerMode=RIGHT) then
					ballPosNum <= 15;
				end if;
			elsif (serveMode=not ACTIVE) then
				if (rateEn=ACTIVE) then
					if (receivingPlayerMode = LEFT) then
						ballPosNum <= ballPosNum + 1;
					elsif (receivingPlayerMode = RIGHT) then
						ballPosNum <= ballPosNum - 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	LED_DECODER: process(ballPosNum)
		variable temp: std_logic_vector(15 downto 0);
	begin
		temp := (others => '0');
		if (ballPosNum>=0 and ballPosNum<=15) then
			temp(ballPosNum) := ACTIVE;
		end if;

		ballPosLed <= temp;
	end process;

	LED_SELECT:
		with patternMode select
			ledField <= ballPosLed when '0',
						winPattern when '1',
						(others => '1') when others;
 
end PongGame_ARCH;
