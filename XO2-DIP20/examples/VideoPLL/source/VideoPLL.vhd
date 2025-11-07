library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity VideoPLL is	
	port (
		CLK10        : in std_logic;   -- reference clock
		VIDEO        : in std_logic;   -- video signal (using differencial pair to detect sync)
		PIXELCLK     : out std_logic
	);	
	
	ATTRIBUTE IO_TYPES : string;
	ATTRIBUTE IO_TYPES OF VIDEO: SIGNAL IS "LVDS,-";
end entity;

 
architecture immediate of VideoPLL is

	component PLL is
    port (
        CLKI: in  std_logic; 
        CLKOP: out  std_logic);
	end component;
	
	signal CLK120:std_logic;
begin
	
	pll0: PLL port map ( CLK10, CLK120 );

	process (CLK120) 
	begin
		if rising_edge(CLK120) then
			PIXELCLK <= VIDEO;
		end if;
	end process;
end immediate;
