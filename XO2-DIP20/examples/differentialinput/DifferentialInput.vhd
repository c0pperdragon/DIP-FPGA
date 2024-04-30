library ieee;
library machxo2;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use machxo2.all;

entity DifferentialInput is	
	port (
		DIFFIN0     : in std_logic;
		PHASE0      : out std_logic;
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
signal CLEANOSC: std_logic;

begin
	-- instantiate internal oscillator
	OSCInst0: OSCH
	GENERIC MAP( NOM_FREQ => "133" )
	PORT MAP ( STDBY=> '0', OSC => CLKOSC,	SEDSTDBY => open );

	process (CLKOSC)
	variable phaseA:integer range 0 to 7 := 0;
	variable phaseB:integer range 0 to 7 := 0;
	variable inA:std_logic;
	variable inB:std_logic;
	variable outA:std_logic;
	variable outB:std_logic;
	begin
		if rising_edge(CLKOSC) then
			if phaseA<2 then
				outA := '1';
			else	
				outA := '0';
			end if;
			if phaseA<3 then
				phaseA := phaseA+1;
			elsif inA = '1' then
				phaseA := 0;
			end if;		
			inA := DIFFIN0;
		end if;
		if falling_edge(CLKOSC) then
			if phaseB<2 then
				outB := '1';
			else	
				outB := '0';
			end if;
			if phaseB<3 then
				phaseB := phaseB+1;
			elsif inB = '1' then
				phaseB := 0;
			end if;		
			inB := DIFFIN0;
		end if;
		CLEANOSC <= outA or outB;
	end process;
	
	process (CLEANOSC)
	variable phase:integer range 0 to 7 := 0;
	begin
		if rising_edge(CLEANOSC) then
			phase := (phase+1) mod 5;
			if phase=0 then
				PHASE0 <= '1';
			else
				PHASE0 <= '0';
			end if;
		end if;
		
		LED <= "00";
	end process;
	
end immediate;
