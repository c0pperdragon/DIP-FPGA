library ieee;
library machxo2;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use machxo2.all;

entity LedAnimation is	
	port (
		LED     : out std_logic_vector(17 downto 0)
	);	
end entity;


architecture immediate of LedAnimation is

COMPONENT OSCH
	GENERIC (NOM_FREQ: string);
	PORT (
		STDBY:IN std_logic;
		OSC:OUT std_logic;
		SEDSTDBY:OUT std_logic
	);
END COMPONENT;

signal CLKOSC : std_logic;

begin
	-- instantiate internal oscillator
	OSCInst0: OSCH
	GENERIC MAP( NOM_FREQ => "2.08" )
	PORT MAP ( STDBY=> '0', OSC => CLKOSC,	SEDSTDBY => open );

	-- implement led animation
	process (CLKOSC)
	variable ticker: integer range 0 to 1000000 := 0;
	variable phase: integer range 0 to 17 := 0;
	variable leds: std_logic_vector(17 downto 0) := "000000000000000000";
	begin
		if rising_edge(CLKOSC) then
			if ticker<500000 then
				ticker := ticker +1;
			else
				ticker := 0;
				if phase<4 then
					leds := leds(16 downto 0) & '1';
				else
					leds := leds(16 downto 0) & '0';
				end if;
				if phase<17 then
					phase := phase+1;
				else
					phase := 0;
				end if;				
			end if;		
		end if;
		LED <= leds;
	end process;
	
end immediate;
