library ieee;
library machxo2;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use machxo2.all;

entity DifferentialInput is	
	port (
		DIFFIN0     : in std_logic;
		LED         : out std_logic_vector(1 downto 0)
	);	

	ATTRIBUTE IO_TYPES : string;
	ATTRIBUTE IO_TYPES OF DIFFIN0: SIGNAL IS "LVDS,-";
end entity;

architecture immediate of DifferentialInput is

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

	process (CLKOSC)
	variable x:std_logic := '0';
	begin
		if rising_edge(CLKOSC) then
			x := DIFFIN0;
		end if;
		LED(0) <= x;
		LED(1) <= not x;
	end process;
end immediate;
