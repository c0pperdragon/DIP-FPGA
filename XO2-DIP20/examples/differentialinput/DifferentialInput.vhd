library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity DifferentialInput is	
	port (
		DIFFIN0     : in std_logic;
		DIFFIN1     : in std_logic;
		DIFFIN2     : in std_logic;
		DIFFIN3     : in std_logic;
		
		LED     : out std_logic_vector(8 downto 0)
	);	

	ATTRIBUTE IO_TYPES : string;
	ATTRIBUTE IO_TYPES OF DIFFIN0: SIGNAL IS "LVDS,-";
	ATTRIBUTE IO_TYPES OF DIFFIN1: SIGNAL IS "LVDS,-";
	ATTRIBUTE IO_TYPES OF DIFFIN2: SIGNAL IS "LVDS,-";
	ATTRIBUTE IO_TYPES OF DIFFIN3: SIGNAL IS "LVDS,-";
end entity;


architecture immediate of DifferentialInput is
begin
	process (DIFFIN0,DIFFIN1,DIFFIN2,DIFFIN3)
	begin
		LED(0) <= DIFFIN0;
		LED(1) <= DIFFIN1;
		LED(2) <= DIFFIN2;
		LED(3) <= DIFFIN3;
		LED(4) <= '0';		
		LED(5) <= '0';
		LED(6) <= '0';
		LED(7) <= '0';
		LED(8) <= '0';
	end process;
end immediate;
