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
	
	
	process (CLK0,CLK1,CLK2,CLK3)
	begin
		TESTCLK <= "0000"; -- CLK3 & CLK2 & CLK1 & CLK0;
	end process;
	
	-- subdivide to pixels
	process (CLK0,CLK1,CLK2,CLK3) 
	variable x:std_logic_vector(7 downto 0);
	variable inputhalf:std_logic_vector(3 downto 0);
	
	variable incomming:std_logic_vector(7 downto 0);
	variable outgoing:std_logic_vector(7 downto 0);
	
	variable outputhalf:std_logic_vector(3 downto 0);
	variable y:std_logic_vector(7 downto 0);
	
	begin
		-- send out data finely staggered by clocks
		if falling_edge(CLK0) then 
			outputhalf := outgoing(7 downto 4);
			y(0) := outgoing(0); 
		end if;
		if falling_edge(CLK1) then y(1) := outgoing(1); end if;
		if falling_edge(CLK2) then y(2) := outgoing(2); end if;
		if falling_edge(CLK3) then y(3) := outgoing(3); end if;
		if rising_edge(CLK0) then y(4) := outputhalf(0); end if;
		if rising_edge(CLK1) then y(5) := outputhalf(1); end if;
		if rising_edge(CLK2) then y(6) := outputhalf(2); end if;
		if rising_edge(CLK3) then y(7) := outputhalf(3); end if;
		PIXELCLK <= y(0) or y(1) or y(2) or y(3) or y(4) or y(5) or y(6) or y(7);
		
		-- do processing in one clock domain
		if rising_edge(CLK0) then
			outgoing := incomming;
		end if;
		
		-- aquire finely timed samples of the input signal for lower-frequency main processing
		if falling_edge(CLK0) then 
			inputhalf := x(3 downto 0);
			x(0) := VIDEO; 
		end if;
		if falling_edge(CLK1) then x(1) := VIDEO; end if;
		if falling_edge(CLK2) then x(2) := VIDEO; end if;
		if falling_edge(CLK3) then x(3) := VIDEO; end if;
		if rising_edge(CLK0) then 
			incomming := x(7 downto 4) & inputhalf;
			x(4) := VIDEO; 
		end if;
		if rising_edge(CLK1) then x(5) := VIDEO; end if;
		if rising_edge(CLK2) then x(6) := VIDEO; end if;
		if rising_edge(CLK3) then x(7) := VIDEO; end if;
	end process;
	
	
end immediate;
