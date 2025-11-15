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
	signal syncshift:integer range 0 to 255;
	
	signal CLK0,CLK1,CLK2,CLK3:std_logic;
	signal PIXELCLK:std_logic;
begin
	
	pll0: PLL_8x120 port map ( CLK10, CLK0, CLK1, CLK2, CLK3 );
	
	process (SELECTOR)
	variable ax:integer range 0 to 2**11-1;
	begin
		if SELECTOR='0' then
			a <= 1368;
			syncshift <= 10;
		else
			a <= 1008;
			syncshift <= 5;
		end if;
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
	variable edgecountdown:integer range 0 to 255 := 0;
	variable fallingedge:boolean := false;
	variable edgeoffset:integer range 0 to 7 := 0;
	variable prev_incomming:std_logic_vector(7 downto 0);
	
	variable accu:integer range 0 to 2**20-1 := 0;
	variable b:integer range 0 to 2**20-1 := 0;
	constant accustart:integer := 262144; -- about half of b, using only one 1-bit
	
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
				-- use total time of last 8 lines and compute bresenheim value 
				thisedgetime := ticker + edgeoffset;
				b := (thisedgetime - edgetimes(7)) mod (2**20);				
				edgetimes(1 to 7) := edgetimes(0 to 6);
				edgetimes(0) := thisedgetime;
				-- reset bresenheim
				case edgeoffset is
				when 0 => accu := accustart + (0)*8;
				when 1 => accu := accustart + (a) * 8;
				when 2 => accu := accustart + (2*a) * 8;
				when 3 => accu := accustart + (a+2*a) * 8;
				when 4 => accu := accustart + (4*a) * 8;
				when 5 => accu := accustart + (4*a+a) * 8;
				when 6 => accu := accustart + (4*a+2*a) * 8;
				when 7 => accu := accustart + (4*a+2*a+a) * 8;
				end case;
			-- when no edge, run the bresenheim algorithm 		
			elsif accu>=a*8*8 then
				accu := accu-a*8*8;
			else
				accu := accu+b-a*8*8;
			end if;
		
			-- detect falling edge and determine the exact time shift of the edge
			fallingedge := false;
			if prev_incomming = "11111111" and incomming/="11111111" then
				if incomming(0)='0' then edgecountdown := 1+syncshift; 
				elsif incomming(1)='0' then edgecountdown := 2+syncshift;
				elsif incomming(2)='0' then edgecountdown := 3+syncshift;
				elsif incomming(3)='0' then edgecountdown := 4+syncshift;
				elsif incomming(4)='0' then edgecountdown := 5+syncshift;
				elsif incomming(5)='0' then edgecountdown := 6+syncshift;
				elsif incomming(6)='0' then edgecountdown := 7+syncshift;
				else edgecountdown := 9+syncshift; 
				end if;
			elsif edgecountdown>=9 then
				edgecountdown := edgecountdown-8;
			elsif edgecountdown>=1 then
				edgeoffset := edgecountdown-1;
				edgecountdown := 0;
				fallingedge := true;
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
	
	
	process (CSYNC,VID1,VID2,VID3,PIXELCLK)
	variable t:std_logic := '0';
	variable x:integer range 0 to 7 := 0;
	variable data:std_logic_vector(11 downto 0) := "000000000000";
	variable in_csync:std_logic;
	variable in_vid:std_logic_vector(3 downto 1);
	begin
		if rising_edge(PIXELCLK) then
			data := data(9 downto 0) & in_vid(2) & (in_vid(3) or (in_vid(1) and not in_vid(2)));
			
			if in_csync='0' then
				x := 5;
			elsif x<5 then
				x := x+1;
			else
				x := 0;
			end if;
			
			OUTPATTERN(1) <= t;
			OUTPATTERN(2) <= '0';
			OUTPATTERN(3) <= in_csync;
			if x=3 then
				OUTPATTERN(7 downto 4) <= data(3 downto 0);
			elsif x=0 then
				OUTPATTERN(7 downto 4) <= data(5 downto 2);
			end if;
			
			in_csync := CSYNC;
			in_vid := VID3 & VID2 & VID1;			
			t := not t;
		end if;		
		
		OUTPATTERN(0) <= CSYNC;
	end process;
	
	
end immediate;
