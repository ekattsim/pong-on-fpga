library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PongGame_TB is
end PongGame_TB;

architecture PongGame_TB_ARCH of PongGame_TB is

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

    -- Constants
    constant CLOCK_PERIOD : time := 10 ns; -- Corresponds to 100 MHz clock

    signal reset_s        : std_logic := '0';
    signal clock_s        : std_logic := '0';
    signal leftPaddle_s   : std_logic := '0';
    signal rightPaddle_s  : std_logic := '0';
    signal ledField_s     : std_logic_vector(15 downto 0);
    signal leftScore_s    : std_logic_vector(6 downto 0);
    signal rightScore_s   : std_logic_vector(6 downto 0);

begin

    UUT: PongGame
        port map (
            reset       => reset_s,
            clock       => clock_s,
            leftPaddle  => leftPaddle_s,
            rightPaddle => rightPaddle_s,
            ledField    => ledField_s,
            leftScore   => leftScore_s,
            rightScore  => rightScore_s
        );

    CLOCK: process
    begin
        clock_s <= '1';
        wait for CLOCK_PERIOD / 2;
        clock_s <= '0';
        wait for CLOCK_PERIOD / 2;
    end process CLOCK;

    INPUT_DRIVER: process
    begin
        report "Starting Pong Game Testbench...";

        -- === STEP 1: Apply Reset ===
        report "Applying reset...";
        reset_s <= '1';
        wait for CLOCK_PERIOD * 5;
        reset_s <= '0';
        wait for CLOCK_PERIOD;

        report "Reset complete. Game should be in RIGHT_SERVE state.";
        wait for CLOCK_PERIOD * 10; -- Let the system settle

        -- === STEP 2: Right Player Serves the Ball ===
        report "Right player serving...";
        rightPaddle_s <= '1';
        wait for CLOCK_PERIOD;
        rightPaddle_s <= '0';

        -- === STEP 3: Wait for ball to reach the Left Player ===
        report "Waiting for ball to reach the left side (LED 15)...";
        -- The ball's initial speed is two LEDs per second.
        wait until ledField_s(15) = '1';
        report "Ball has reached the left side.";

        -- === STEP 4: Left Player successfully hits the ball ===
        report "Left player hitting the ball...";
        wait for CLOCK_PERIOD; -- Give a small delay to ensure we are in the hitzone state
        leftPaddle_s <= '1';
        wait for CLOCK_PERIOD;
        leftPaddle_s <= '0';

        -- === STEP 5: Wait for ball to reach the Right Player ===
        report "Waiting for ball to return to the right side (LED 0)...";
        wait until ledField_s(0) = '1';
        report "Ball has reached the right side. Preparing for a miss.";

        -- === STEP 6: Right Player misses the ball ===
        -- We do nothing and let the ball pass. This should trigger a point for the left player. We can verify this by waiting for the score to change.
        report "Right player is missing the ball. Waiting for round to end...";
        wait until leftScore_s /= "0000000";

        -- === STEP 7: Verify Score and End Simulation ===
        report "Round over. Verifying score...";

        wait for CLOCK_PERIOD * 2; -- Allow final values to propagate

        assert leftScore_s = "0000001"
            report "FAIL: Left score is not 1." severity error;

        assert rightScore_s = "0000000"
            report "FAIL: Right score is not 0." severity error;

        report "Test finished." severity note;

        -- Halt the simulation
        wait;

    end process INPUT_DRIVER;

end PongGame_TB_ARCH;
