library ieee;
library machxo2;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use machxo2.all;

entity c64timers is	
	port (
	    TEST           : out std_logic;
		NTSC_SUBCARRIER : out std_logic;
		NTSC_PIXCLK    : out std_logic;
		PAL_SUBCARRIER : out std_logic;
		PAL_PIXCLK    : out std_logic
	);	
end entity;

architecture immediate of c64timers is

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
	GENERIC MAP( NOM_FREQ => "133" )
	PORT MAP ( STDBY=> '0', OSC => CLKOSC,	SEDSTDBY => open );

	-- generate output clock signals:
	process (CLKOSC)
	constant TEST_PERIOD:integer := 10;    -- 13.3 MHz 
	constant NTSC_SUB_PERIOD:integer := 37;    -- 14.31818/4 MHz
	constant NTSC_PIX_PERIOD:integer := 65;    -- 8.1818/4 MHz
	constant PAL_SUB_PERIOD:integer := 30;     -- 17.7344/4 MHz
	constant PAL_PIX_PERIOD:integer := 68;     -- 7.88199/4 MHz  
	constant p0:std_logic_vector(TEST_PERIOD-1 downto 0) := 
	"0000011111";
	constant p1:std_logic_vector(NTSC_SUB_PERIOD-1 downto 0) := 
	"0000011111000011111000011111000011111";
	constant p2:std_logic_vector(NTSC_PIX_PERIOD-1 downto 0) := 
	"00000000111111110000000011111111000000001111111100000000111111111";
	constant p3:std_logic_vector(PAL_SUB_PERIOD-1 downto 0) := 
	"000011100001111000011100001111";
	constant p4:std_logic_vector(PAL_PIX_PERIOD-1 downto 0) := 
	"00000000011111111000000001111111110000000011111111000000000111111111";
	
	variable t0: integer range 0 to TEST_PERIOD-1;
	variable t1: integer range 0 to NTSC_SUB_PERIOD-1;
	variable t2: integer range 0 to NTSC_PIX_PERIOD-1;
	variable t3: integer range 0 to PAL_SUB_PERIOD-1;
	variable t4: integer range 0 to PAL_PIX_PERIOD-1;
	
	begin
		if rising_edge(CLKOSC) then
			TEST <= p0(t0);
			NTSC_SUBCARRIER <= p1(t1);
			NTSC_PIXCLK <= p2(t2);
			PAL_SUBCARRIER <= p3(t3);
			PAL_PIXCLK <= p4(t4);

			if t0>0 then t0:=t0-1; else t0:=TEST_PERIOD-1; end if;
			if t1>0 then t1:=t1-1; else t1:=NTSC_SUB_PERIOD-1; end if;
			if t2>0 then t2:=t2-1; else t2:=NTSC_PIX_PERIOD-1; end if;
			if t3>0 then t3:=t3-1; else t3:=PAL_SUB_PERIOD-1; end if;
			if t4>0 then t4:=t4-1; else t4:=PAL_PIX_PERIOD-1; end if;
		end if;
	end process;
	
end immediate;
