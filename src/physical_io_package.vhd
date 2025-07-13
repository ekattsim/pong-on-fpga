library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--**********************************************************************************
--*
--*  Name: physical_io_package
--*  Designer: Scott Tippens
--*
--*      This package contains convenient interface elements for physically
--*      interfacing components to external hardware such as buttons and multiplexed
--*      seven-segment displays.
--*
--**********************************************************************************
package physical_io_package is

    -----------------------------------------------------------------------FUNCTIONS
	function to_bcd_8bit( inputValue: integer) return std_logic_vector;


    ----------------------------------------------------------------------PROCEDURES
	procedure count_to_99( signal  reset:    in     std_logic;
						   signal  clock:    in     std_logic;
						   signal  countEn:  in     std_logic;
						   signal  count:    inout  integer);


    --==================================================SevenSegmentDriver COMPONENT
	component SevenSegmentDriver is
		port (
			reset: in std_logic;
			clock: in std_logic;
			digit3: in std_logic_vector(3 downto 0);
			digit2: in std_logic_vector(3 downto 0);
			digit1: in std_logic_vector(3 downto 0);
			digit0: in std_logic_vector(3 downto 0);
			blank3: in std_logic;
			blank2: in std_logic;
			blank1: in std_logic;
			blank0: in std_logic;
			sevenSegs: out std_logic_vector(6 downto 0);
			anodes:    out std_logic_vector(3 downto 0)
		);
	end component SevenSegmentDriver;


	--=====================================================ButtonDebouncer COMPONENT
	component ButtonDebouncer is
		generic (STABLE_PERIOD: positive);
		port (
			reset:     in  std_logic;
			clock:     in  std_logic;
			asyncButton:   in  std_logic;
			cleanButton:  out std_logic
		);
	end component ButtonDebouncer;


	--========================================================ButtonPulser COMPONENT
	component ButtonPulser is
		port (
			reset: in std_logic;
			clock: in std_logic;
			syncedButton: in std_logic;
			buttonPulse: out std_logic
		);
	end component ButtonPulser;


end package;


package body physical_io_package is

	constant ACTIVE: std_logic := '1';


	--======================================================================FUNCTION
	--  to_bcd_8bit()
	--      Convert the input integer value to a two digit BCD representation.
	--      This function limits the return value to 99.
	--==============================================================================
	function to_bcd_8bit( inputValue: integer) return std_logic_vector is
		variable tensValue: integer;
		variable onesValue: integer;
	begin
		if (inputValue < 99) then
			tensValue := inputValue  /  10;
			onesValue := inputValue mod 10;
		else
			tensValue := 9;
			onesValue := 9;
		end if;

		return std_logic_vector(to_unsigned(tensValue, 4)) &  std_logic_vector(to_unsigned(onesValue, 4));
	end function to_bcd_8bit;


	--=====================================================================PROCEDURE
	--  count_to_99()
	--      Implements a counter that will count from 0 to 99.  Once the count
	--      reaches 99 it must be reset to return to 0.
	--==============================================================================
	procedure count_to_99( signal  reset:    in  std_logic;
						   signal  clock:    in  std_logic;
						   signal  countEn:  in std_logic;
						   signal  count:    inout integer) is
	begin
		if (reset=ACTIVE) then
			count <= 0;
		elsif (rising_edge(clock)) then
			if (countEn=ACTIVE) then
				if (count>=0 and count<99) then
					count <= count + 1;
				else
					count <= 99;
				end if;
			end if;
		end if;

	end procedure count_to_99;


end package body physical_io_package;
