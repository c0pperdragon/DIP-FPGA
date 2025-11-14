library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity VideoPLL is	
	port (
		CLK10        : in std_logic;   -- reference clock
		CSYNC        : in std_logic;   -- csync input detected 
		VID1         : in std_logic;   -- video signal reaches level 1 
		VID2         : in std_logic;   -- video signal reaches level 2 
		VID3         : in std_logic;   -- video signal reaches level 3 
		SELECTOR     : in std_logic;
		OUTPATTERN   : out std_logic_vector(7 downto 0) -- generated pattern for debugging
	);	
	
	ATTRIBUTE IO_TYPES : string;
	ATTRIBUTE IO_TYPES OF VID1: SIGNAL IS "LVDS,-";
	ATTRIBUTE IO_TYPES OF VID2: SIGNAL IS "LVDS,-";
	ATTRIBUTE IO_TYPES OF VID3: SIGNAL IS "LVDS,-";
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
	
	signal a:integer range 0 to 2**11-1;
	signal CLK0,CLK1,CLK2,CLK3:std_logic;
	signal PIXELCLK:std_logic;
begin
	
	pll0: PLL_8x120 port map ( CLK10, CLK0, CLK1, CLK2, CLK3 );
	
	process (SELECTOR)
	variable ax:integer range 0 to 2**11-1;
	begin
		if SELECTOR='0' then
			a <= 1368;
		else
			a <= 1008;
		end if;
	end process;
	
	process (CSYNC,VID1,VID2,VID3,PIXELCLK)
	variable t:std_logic := '0';
	begin
		if rising_edge(PIXELCLK) then
			t := not t;
		end if;
		OUTPATTERN(0) <= CSYNC;
		OUTPATTERN(1) <= VID1;
		OUTPATTERN(2) <= VID2;
		OUTPATTERN(3) <= VID3;
		OUTPATTERN(4) <= '0';
		OUTPATTERN(5) <= PIXELCLK;
		OUTPATTERN(6) <= '0';
		OUTPATTERN(7) <= t;
	end process;
				
	-- subdivide to pixels
	process (CLK0,CLK1,CLK2,CLK3, CSYNC) 
	
	variable x:std_logic_vector(7 downto 0);
	variable inputhalf:std_logic_vector(3 downto 0);
	variable incomming:std_logic_vector(7 downto 0);
	variable outgoing:std_logic_vector(7 downto 0);
	variable outputhalf:std_logic_vector(3 downto 0);
	variable y:std_logic_vector(7 downto 0);
	
	variable ticker:integer range 0 to 2**20-1 := 0;	
	variable thisedgetime:integer range 0 to 2**20-1;
	type edgetimes_t is array (0 to 7) of integer range 0 to 2**20-1;
	variable edgetimes:edgetimes_t;
	variable fallingedge:boolean := false;
	variable edgeoffset:integer range 0 to 7 := 0;
	variable prev_incomming:std_logic_vector(7 downto 0);
	
	variable accu:integer range 0 to 2**20-1 := 0;
	variable b:integer range 0 to 2**20-1 := 0;
	
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
		
		-- do processing in one clock domain
		if rising_edge(CLK0) then
			-- determine when clock pulses need to be sent
			outgoing := "00000000";
			if (accu<a*1*8) then outgoing(0) := '1'; end if;
			if (accu<a*2*8) then outgoing(1) := '1'; end if;
			if (accu<a*3*8) then outgoing(2) := '1'; end if;
			if (accu<a*4*8) then outgoing(3) := '1'; end if;
			if (accu<a*5*8) then outgoing(4) := '1'; end if;
			if (accu<a*6*8) then outgoing(5) := '1'; end if;
			if (accu<a*7*8) then outgoing(6) := '1'; end if;
			if (accu<a*8*8) then outgoing(7) := '1'; end if;
			
			-- processing after edge was detected
			if fallingedge then
				-- reset bresenheim
				case edgeoffset is
				when 0 => accu := b/2 + (0)*8;
				when 1 => accu := b/2 + (a) * 8;
				when 2 => accu := b/2 + (2*a) * 8;
				when 3 => accu := b/2 + (a+2*a) * 8;
				when 4 => accu := b/2 + (4*a) * 8;
				when 5 => accu := b/2 + (4*a+a) * 8;
				when 6 => accu := b/2 + (4*a+2*a) * 8;
				when 7 => accu := b/2 + (4*a+2*a+a) * 8;
				end case;
				-- use total time of last 8 lines and compute bresenheim value 
				thisedgetime := ticker + edgeoffset;
				b := (thisedgetime - edgetimes(7)) mod (2**20);				
				edgetimes(1 to 7) := edgetimes(0 to 6);
				edgetimes(0) := thisedgetime;
			-- when no edge, run the bresenheim algorithm 		
			elsif accu>=a*8*8 then
				accu := accu-a*8*8;
			else
				accu := accu+b-a*8*8;
			end if;
		
			-- detect falling edge and determine the exact time shift of the edge
			if prev_incomming = "11111111" and incomming/="11111111" then
				if incomming(0)='0' then edgeoffset:=0; 
				elsif incomming(1)='0' then edgeoffset:=1;
				elsif incomming(2)='0' then edgeoffset:=2;
				elsif incomming(3)='0' then edgeoffset:=3;
				elsif incomming(4)='0' then edgeoffset:=4;
				elsif incomming(5)='0' then edgeoffset:=5;
				elsif incomming(6)='0' then edgeoffset:=6;
				else edgeoffset:=7; 
				end if;
				fallingedge := true;
			else
				fallingedge := false;
			end if;
			prev_incomming := incomming;

			-- tick up time with overflow
			ticker := (ticker+8) mod (2**20);
		end if;
		
		-- aquire finely timed samples of the input signal for lower-frequency main processing
		if falling_edge(CLK0) then 
			inputhalf := x(3 downto 0);
			x(0) := CSYNC; 
		end if;
		if falling_edge(CLK1) then x(1) := CSYNC; end if;
		if falling_edge(CLK2) then x(2) := CSYNC; end if;
		if falling_edge(CLK3) then x(3) := CSYNC; end if;
		if rising_edge(CLK0) then 
			incomming := x(7 downto 4) & inputhalf;
			x(4) := CSYNC; 
		end if;
		if rising_edge(CLK1) then x(5) := CSYNC; end if;
		if rising_edge(CLK2) then x(6) := CSYNC; end if;
		if rising_edge(CLK3) then x(7) := CSYNC; end if;
		
		-- combinational logic from various clock domains
		PIXELCLK <= y(0) or y(1) or y(2) or y(3) or y(4) or y(5) or y(6) or y(7);
	end process;
	
	
end immediate;
