library ieee;
library machxo2;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use machxo2.all;

entity SimpleADC is	
	port (
		CLK         : in std_logic;
		DIFFIN0     : in std_logic;		
		TRIGGER     : out std_logic;
		LED         : out std_logic_vector(8 downto 0)
	);	

	ATTRIBUTE IO_TYPES : string;
	ATTRIBUTE IO_TYPES OF DIFFIN0: SIGNAL IS "LVDS,-";
end entity;

architecture immediate of SimpleADC is

component PLL200 is
    port (
        CLKI: in  std_logic; 
        CLKOP: out  std_logic);
end component;

signal CLK200 : std_logic;

begin
	pll: PLL200
	PORT MAP ( CLKI => CLK, CLKOP => CLK200 );


	process (CLK)
	variable p:std_logic;
	begin
		if rising_edge(CLK) then
			if p='0' then
				TRIGGER <= '0';
			else
				TRIGGER <= 'Z';
			end if;			
			p := not p;
		end if;
		
	end process;
	
	process (CLK200)
	variable in0:std_logic;
	begin
		if rising_edge(CLK200) then
			LED(8 downto 0) <= "000000000";
			LED(0) <= in0;
			in0 := DIFFIN0;			
		end if;
	end process;
	
end immediate;
