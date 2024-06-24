library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity PLLtolerance is	
	port (
		CLK          : out std_logic;
		PLLCLK       : out std_logic;
		PLL3CLK      : out std_logic
	);	
end entity;

 
architecture immediate of PLLtolerance is

	signal OSCCLK : std_logic;

	COMPONENT OSCH
	GENERIC (NOM_FREQ: string);
	PORT (
		STDBY:IN std_logic;
		OSC:OUT std_logic;
		SEDSTDBY:OUT std_logic
	);
	END COMPONENT;
	component PLL is
    port (
        CLKI: in  std_logic; 
        CLKOP: out  std_logic; 
        CLKOS: out  std_logic);
	end component;
	
begin

	OSCInst0: OSCH
	GENERIC MAP( NOM_FREQ => "10.23" )   -- 10.23  13.3  14.78  20.46  26.6  29.56  33.25  38.0  44.33 
	PORT MAP ( STDBY=> '0', OSC => OSCCLK, SEDSTDBY => open );
	
	pll0: PLL port map ( OSCCLK, PLLCLK, PLL3CLK );

	process (OSCCLK) 
	begin
		CLK <= OSCCLK;
	end process;
end immediate;
