----------------------------------------------------------------------------------
-- Description: Ties the PongGame and SevenSegmentDriver components to the 
-- Basys3 board
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
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
	end component;

	-- constants
	constant ACTIVE: std_logic := '1';
	constant CLOCK_RATE: integer := 100000000;
	constant STABLE_CLOCKS: integer := 10;
	constant LEFT_WIN_PATTERN: std_logic_vector(15 downto 0) := "1111111100000000";
	constant RIGHT_WIN_PATTERN: std_logic_vector(15 downto 0) := "0000000011111111";
	constant PATTERN_PERIOD: integer := 1;
	constant INITIAL_SPEED: integer := 2;
	constant MIN_WIN_SCORE: integer := 7;
	constant WIN_BY_SCORE: integer := 2;
	
	-- internal signals
	signal leftCleanButton: std_logic;
	signal rightCleanButton: std_logic;
	signal leftPaddle_s: std_logic;
	signal rightPaddle_s: std_logic;
	signal leftScore_s: std_logic_vector(6 downto 0);
	signal rightScore_s: std_logic_vector(6 downto 0);
	signal digit3_s: std_logic_vector(3 downto 0);
	signal digit2_s: std_logic_vector(3 downto 0);
	signal digit1_s: std_logic_vector(3 downto 0);
	signal digit0_s: std_logic_vector(3 downto 0);
	signal blank3_s: std_logic;
	signal blank1_s: std_logic;

begin

	LEFT_DEBOUNCE: ButtonDebouncer
		generic map (STABLE_PERIOD => STABLE_CLOCKS)
		port map (
			reset => reset,
			clock => clk,
			asyncButton => btnL,
			cleanButton => leftCleanButton
		);

	RIGHT_DEBOUNCE: ButtonDebouncer
		generic map (STABLE_PERIOD => STABLE_CLOCKS)
		port map (
			reset => reset,
			clock => clk,
			asyncButton => btnR,
			cleanButton => rightCleanButton
		);

	LEFT_PULSER: ButtonPulser
		port map (
			reset => reset,
			clock => clk,
			syncedButton => leftCleanButton,
			buttonPulse => leftPaddle_s
		);

	RIGHT_PULSER: ButtonPulser
		port map (
			reset => reset,
			clock => clk,
			syncedButton => rightCleanButton,
			buttonPulse => rightPaddle_s
		);

	UUT: PongGame
		generic map (
			CLOCK_RATE => CLOCK_RATE,
			LEFT_WIN_PATTERN => LEFT_WIN_PATTERN,
			RIGHT_WIN_PATTERN => RIGHT_WIN_PATTERN,
			PATTERN_PERIOD => PATTERN_PERIOD,
			INITIAL_SPEED => INITIAL_SPEED,
			MIN_WIN_SCORE => MIN_WIN_SCORE,
			WIN_BY_SCORE => WIN_BY_SCORE
		)
		port map (
			reset => reset,
			clock => clk,
			leftPaddle => leftPaddle_s,
			rightPaddle => rightPaddle_s,

			ledField => led,
			leftScore => leftScore_s,
			rightScore => rightScore_s
		);

	LEFT_BCD: process(leftScore_s)
		variable temp: std_logic_vector(7 downto 0);
	begin
		temp := to_bcd_8bit(to_integer(unsigned(leftScore_s)));

		digit3_s <= temp(7 downto 4);
		digit2_s <= temp(3 downto 0);

		if (temp(7 downto 4)="0000") then
			blank3_s <= ACTIVE;
		else
			blank3_s <= not ACTIVE;
		end if;
	end process;

	RIGHT_BCD: process(rightScore_s)
		variable temp: std_logic_vector(7 downto 0);
	begin
		temp := to_bcd_8bit(to_integer(unsigned(rightScore_s)));

		digit1_s <= temp(7 downto 4);
		digit0_s <= temp(3 downto 0);

		if (temp(7 downto 4)="0000") then
			blank1_s <= ACTIVE;
		else
			blank1_s <= not ACTIVE;
		end if;
	end process;

	SEGMENT_DRIVER: SevenSegmentDriver
		port map (
			reset => reset,
			clock => clk,
			digit3 => digit3_s,
			digit2 => digit2_s,
			digit1 => digit1_s,
			digit0 => digit0_s,
			blank3 => blank3_s,
			blank2 => not ACTIVE,
			blank1 => blank1_s,
			blank0 => not ACTIVE,
			sevenSegs => seg,
			anodes => an
		);

end PongGame_Basys3_ARCH;
