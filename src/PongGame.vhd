library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.physical_io_package.ALL;

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
	generic (
		CLOCK_RATE: integer;
		LEFT_WIN_PATTERN: std_logic_vector(15 downto 0);
		RIGHT_WIN_PATTERN: std_logic_vector(15 downto 0);
		PATTERN_PERIOD: integer; -- specify in seconds
		INITIAL_SPEED: integer; -- specify in LEDs/sec
		MIN_WIN_SCORE: integer;
		WIN_BY_SCORE: integer
	);
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
	constant PATTERN_PERIOD_COUNT: integer := (CLOCK_RATE*PATTERN_PERIOD)-1;

	signal winMode: Player_t;
	signal patternMode: std_logic;
	signal winPattern: std_logic_vector(15 downto 0);
	signal startTimerEn: std_logic;
	signal timerDoneEn: std_logic;

	-- speed control declarations
	type ArrayInt_t is array (0 to 7) of integer;
	constant SPEED_COUNTS: ArrayInt_t := (0, (CLOCK_RATE/INITIAL_SPEED)-1,
										  (CLOCK_RATE/(INITIAL_SPEED+1))-1,
										  (CLOCK_RATE/(INITIAL_SPEED+2))-1,
										  (CLOCK_RATE/(INITIAL_SPEED+3))-1,
										  (CLOCK_RATE/(INITIAL_SPEED+4))-1,
										  (CLOCK_RATE/(INITIAL_SPEED+5))-1,
										  (CLOCK_RATE/(INITIAL_SPEED+6))-1);
	signal speedRstMode: std_logic;
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
		speedRstMode <= ACTIVE;
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
				speedRstMode <= not ACTIVE;

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
				speedRstMode <= not ACTIVE;

				if (ballPosNum=15) then
					nextState <= LEFT_HITZONE;
				end if;
				if ((ballPosNum/=15) and (leftPaddle=ACTIVE)) then
					nextState <= RIGHT_ROUND_OVER;
				end if;

			when RIGHT_HITZONE =>
				receivingPlayerMode <= RIGHT;
				speedRstMode <= not ACTIVE;

				if ((ballPosNum=0) and (rightPaddle=ACTIVE)) then
					nextState <= LEFT_MOVING;
				end if;
				if (ballPosNum=-1) then
					nextState <= LEFT_ROUND_OVER;
				end if;

			when LEFT_HITZONE =>
				speedRstMode <= not ACTIVE;
				if ((ballPosNum=15) and (leftPaddle=ACTIVE)) then
					nextState <= RIGHT_MOVING;
				end if;
				if (ballPosNum=16) then
					nextState <= RIGHT_ROUND_OVER;
				end if;

			when RIGHT_ROUND_OVER =>
				if (currentState/=prevState) then
					rightWinEn <= ACTIVE;
					startTimerEn <= ACTIVE;
				end if;
				patternMode <= ACTIVE;
				winMode <= RIGHT;

				if (timerDoneEn=ACTIVE) then
					if ((rightScoreSignal>=MIN_WIN_SCORE) and
						(rightScoreSignal-leftScoreSignal>=WIN_BY_SCORE)) then
						nextState <= RIGHT_GAME_OVER;
					else
						nextState <= LEFT_SERVE;
					end if;
				end if;

			when LEFT_ROUND_OVER =>
				if (currentState/=prevState) then
					leftWinEn <= ACTIVE;
					startTimerEn <= ACTIVE;
				end if;
				patternMode <= ACTIVE;

				if (timerDoneEn=ACTIVE) then
					if ((leftScoreSignal>=MIN_WIN_SCORE) and
						(leftScoreSignal-rightScoreSignal>=WIN_BY_SCORE)) then
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
	-- Timer process that starts counting on startTimerEn
	-- until PATTERN_PERIOD_COUNT and pulses timerDoneEn after
	-- finishing.
	----------------------------------------------------------
	PATTERN_TIMER: process(reset, clock)
		variable countMode: std_logic;
		variable counter: integer range 0 to PATTERN_PERIOD_COUNT;
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
				if (counter=PATTERN_PERIOD_COUNT) then
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
	-- is reset by speedRstMode and incremented by speedIncEn.
	-- The available speeds are described by SPEED_COUNTS.
	----------------------------------------------------------
	SPEED_CONTROL: process(reset, clock)
		variable speedLevel: integer range 0 to 7;
		variable counter: integer range 0 to SPEED_COUNTS(1); -- Level 1 requires the longest count
	begin
		if (reset=ACTIVE) then
			rateEn <= not ACTIVE;
			speedLevel := 0;
			counter := 0;
		elsif (rising_edge(clock)) then
			rateEn <= not ACTIVE;

			if (speedRstMode=ACTIVE) then
				speedLevel := 0;
				counter := 0;
			elsif (speedIncEn=ACTIVE) then
				rateEn <= ACTIVE; -- immediately move ball on successful hit
				if (speedLevel<7) then
					speedLevel := speedLevel+1;
					counter := 0;
				end if;
			elsif (counter=SPEED_COUNTS(speedLevel)) then
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
