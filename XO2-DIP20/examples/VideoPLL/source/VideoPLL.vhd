library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity VideoPLL is	
	port (
		CLK10        : in std_logic;   -- reference clock
		CSYNC        : out std_logic;  -- synthethic sync train
		
		VIDEO        : in std_logic;   -- csync input of input video signal 
		PIXELCLK     : out std_logic;
		
		TESTCLK      : out std_logic_vector(3 downto 0)
	);	
	
	ATTRIBUTE IO_TYPES : string;
	ATTRIBUTE IO_TYPES OF VIDEO: SIGNAL IS "LVDS,-";
end entity;

 
architecture immediate of VideoPLL is

	component PLL_8x120 is
    port (
        CLKI: in  std_logic; 
        CLKOP: out  std_logic; 
        CLKOS: out  std_logic; 
        CLKOS2: out  std_logic; 
        CLKOS3: out  std_logic);
	end component;
	
	signal CLK0,CLK1,CLK2,CLK3:std_logic;
begin
	
	pll0: PLL_8x120 port map ( CLK10, CLK0, CLK1, CLK2, CLK3 );
	
	-- create synthetic csync pulses
	process (CLK10)
	variable x: integer range 0 to 1023 := 0;
	variable y: integer range 0 to 511 := 0;
	begin
		if rising_edge(CLK10) then
			CSYNC <= '1';
			if y<3 then
				if x<47 then
					CSYNC <= '0';
				end if;
			else
				if x<640-47 then
					CSYNC <= '0';
				end if;
			end if;
				
			if x<640-1 then
				x := x+1;
			else
				x := 0;
				if y<312-1 then
					y := y+1;
				else
					y := 0;
				end if;
			end if;		
		end if;	
	end process;
	
	-- subdivide to pixels
	process (CLK0) 
	begin
		if rising_edge(CLK0) then
			PIXELCLK <= VIDEO;
		end if;
	end process;
	
	process (CLK0,CLK1,CLK2,CLK3)
	begin
		TESTCLK <= CLK3 & CLK2 & CLK1 & CLK0;
	end process;
	
end immediate;
