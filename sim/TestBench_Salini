----------------------------------------------------------------------------------
-- Name: PongGame
-- Designers: Abhijeet Surakanti, Salini Ambadapudi, Gurbir Singh
--
-- The testbench applies a sequence of test scenarios using an array of structured
-- test vectors. Each vector specifies the paddle inputs and wait time to emulate
-- real gameplay. 
--
-- Test Sequences:
--
-- 1. Right Serve - Left Misses:
--    - The right player serves the ball.
--    - The left player does not respond (misses).
--    - Result: Right player scores 1 point.
--
-- 2. Left Serve - Right Misses:
--    - The left player serves the ball.
--    - The right player does not respond (misses).
--    - Result: Left player scores 1 point.
--
-- 3. Right Serve - Left Hits - Right Misses:
--    - The right player serves the ball.
--    - The left player hits the ball back.
--    - The right player misses the return.
--    - Result: Left player scores 1 point.
--
-- Final Expected Score:
--    - leftScore  = 2 
--    - rightScore = 1 
----------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pongGame_TB is
--  Port ( );
end pongGame_TB;

architecture Behavioral of pongGame_TB is
	-- constants
    constant CLK_PERIOD : time := 10 ns;
    constant ACTIVE: std_logic := '1';

	-- signals
	signal leftPaddle: std_logic; 
	signal rightPaddle: std_logic; 
	signal reset: std_logic;
	signal clock: std_logic;
	signal ledField: std_logic_vector (15 downto 0); 
	signal leftScore: std_logic_vector (6 downto 0); 
	signal rightScore: std_logic_vector (6 downto 0); 
	
	
	-- component
	component pongGame is
	port (
        leftPaddle: in std_logic; 
        rightPaddle: in std_logic; 
        reset: in std_logic;
        clock: in std_logic;
        
        ledField: out std_logic_vector (15 downto 0); 
        leftScore: out std_logic_vector (6 downto 0); 
        rightScore: out std_logic_vector (6 downto 0)
	);
    end component;
    
        type testRecord_t is record
        leftPaddle    : std_logic;
        rightPaddle   : std_logic;
        waitCycles  : natural;
    end record;

    type testArray_t is array (natural range <>) of testRecord_t;
    -- Test Vectors (customize sequence as needed)
    constant TEST_VECTORS : testArray_t := (
    
        -- =======================
        -- ROUND 1: Right serves, Left misses → Right scores
        -- =======================
        ( '0', '0', 10 ),   -- Initial wait
        ( '0', '1', 1  ),   -- Right serves
        ( '0', '0', 500 ),  -- Ball travels to left
        ( '0', '0', 200 ),  -- Left misses
    
        -- Score: rightScore = 1
        ( '0', '0', 100 ),
    
        -- =======================
        -- ROUND 2: Left serves, Right misses → Left scores
        -- =======================
        ( '1', '0', 1  ),   -- Left serves
        ( '0', '0', 500 ),  -- Ball travels to right
        ( '0', '0', 200 ),  -- Right misses
    
        -- Score: leftScore = 1
        ( '0', '0', 100 ),
    
        -- =======================
        -- ROUND 3: Right serves, Left hits, Right misses → Left scores
        -- =======================
        ( '0', '1', 1  ),   -- Right serves
        ( '0', '0', 500 ),  -- Ball travels to left
        ( '1', '0', 1  ),   -- Left hits
        ( '0', '0', 300 ),  -- Ball travels to right
        ( '0', '0', 200 ),  -- Right misses
    
        -- Score: leftScore = 2
        ( '0', '0', 100 )
    
        -- Simulation ends 
    );



begin


    --============================================================================
	--  UUT
	--============================================================================
	
		UUT:
		pongGame port map(
			leftPaddle => leftPaddle,
			rightPaddle => rightPaddle,
			reset => reset,
			clock => clock,
			ledField => ledField,
			leftScore => leftScore, 
			rightScore => rightScore
		);
		
		
	--============================================================================
	--  Input Driver
	--============================================================================

    INPUT_DRIVER: process
        variable index : natural := 0;
    begin
        wait for 6 * CLK_PERIOD;  -- Wait until after reset is done
        for index in TEST_VECTORS'range loop
            leftPaddle  <= TEST_VECTORS(index).leftPaddle;
            rightPaddle <= TEST_VECTORS(index).rightPaddle;
            wait for TEST_VECTORS(index).waitCycles * CLK_PERIOD;
        end loop;
        wait;
    end process;
		

	--============================================================================
	--  Reset
	--============================================================================
	SYSTEM_RESET: process
	begin
		reset <= ACTIVE;
		wait for 15 ns;
		reset <= not ACTIVE;
		wait;
	end process SYSTEM_RESET;


	--============================================================================
	--  Clock
	--============================================================================
	SYSTEM_CLOCK: process
	begin
		clock <= not ACTIVE;
		wait for 5 ns;
		clock <= ACTIVE;
		wait for 5 ns;
	end process SYSTEM_CLOCK;



end Behavioral;
