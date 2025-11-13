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
	
	signal CLK0,CLK1,CLK2,CLK3:std_logic;
	
	signal a1:integer range 0 to 2**11-1;
	signal a2:integer range 0 to 2**12-1;
	signal a3:integer range 0 to 2**12-1;
	signal a4:integer range 0 to 2**13-1;
	signal a5:integer range 0 to 2**14-1;
	signal a6:integer range 0 to 2**14-1;
	signal a7:integer range 0 to 2**14-1;
	signal a8:integer range 0 to 2**14-1;
begin
	
	pll0: PLL_8x120 port map ( CLK10, CLK0, CLK1, CLK2, CLK3 );
	
	process (SELECTOR)
	variable ax:integer range 0 to 2**11-1;
	begin
		if SELECTOR='0' then
			ax := 1362;
		else
			ax := 1008;
		end if;
		a1 <= ax;
		a2 <= ax*2;	
		a3 <= ax*3;	
		a4 <= ax*4;	
		a5 <= ax*5;	
		a6 <= ax*6;	
		a7 <= ax*7;	
		a8 <= ax*8;	
	end process;
	
	process (CSYNC,VID1,VID2,VID3, CLK0)
	begin
		OUTPATTERN(6 downto 4) <= "000";
		OUTPATTERN(0) <= CSYNC;
		OUTPATTERN(1) <= VID1;
		OUTPATTERN(2) <= VID2;
		OUTPATTERN(3) <= VID3;
	end process;
		
	-- subdivide to pixels
	process (CLK0,CLK1,CLK2,CLK3, CSYNC) 
	
	variable x:std_logic_vector(7 downto 0);
	variable inputhalf:std_logic_vector(3 downto 0);
	variable incomming:std_logic_vector(7 downto 0);
	variable outgoing:std_logic_vector(7 downto 0);
	variable outputhalf:std_logic_vector(3 downto 0);
	variable y:std_logic_vector(7 downto 0);
	
	variable prev_incomming:std_logic_vector(7 downto 0);
	variable fallingedge:boolean := false;
	variable edgetime:integer range 0 to 7 := 0;
	variable rowcounter:integer range 0 to 2**16-1 := 0;
	
	variable accu:integer range 0 to 2**16-1 := 0;
	variable b:integer range 0 to 2**16-1 := 0;
	
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
			if (accu<a1) then outgoing(0) := '1'; end if;
			if (accu<a2) and not (accu<a1) then outgoing(1) := '1'; end if;
			if (accu<a3) and not (accu<a2) then outgoing(2) := '1'; end if;
			if (accu<a4) and not (accu<a3) then outgoing(3) := '1'; end if;
			if (accu<a5) and not (accu<a4) then outgoing(4) := '1'; end if;
			if (accu<a6) and not (accu<a5) then outgoing(5) := '1'; end if;
			if (accu<a7) and not (accu<a6) then outgoing(6) := '1'; end if;
			if (accu<a8) and not (accu<a7) then outgoing(7) := '1'; end if;
			
			-- run the bresenheim algorithm 
			if accu>=a8 then
				accu := accu-a8;
			else				
				accu := accu+b-a8;
			end if;
		
			-- processing after edge was detected
			if fallingedge then
				b := rowcounter + edgetime;
				case edgetime is
				when 0 => accu := a1;
				when 1 => accu := a2;
				when 2 => accu := a3;
				when 3 => accu := a4;
				when 4 => accu := a5;
				when 5 => accu := a6;
				when 6 => accu := a7;
				when 7 => accu := a8;
				end case;
				rowcounter := 8-edgetime;
			else
				rowcounter := rowcounter+8;
			end if;
		
			-- detect falling edge and determine the exact time shift of the edge
			if prev_incomming = "11111111" and incomming/="11111111" then
				fallingedge := true;
				if incomming(0)='0' then edgetime:=0; 
				elsif incomming(1)='0' then edgetime:=1;
				elsif incomming(2)='0' then edgetime:=2;
				elsif incomming(3)='0' then edgetime:=3;
				elsif incomming(4)='0' then edgetime:=4;
				elsif incomming(5)='0' then edgetime:=5;
				elsif incomming(6)='0' then edgetime:=6;
				else edgetime:=7; end if;
			else
				fallingedge := false;
				edgetime:=0;
			end if;
			prev_incomming := incomming;
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
		OUTPATTERN(7) <= y(0) or y(1) or y(2) or y(3) or y(4) or y(5) or y(6) or y(7);
	end process;
	
	
end immediate;
