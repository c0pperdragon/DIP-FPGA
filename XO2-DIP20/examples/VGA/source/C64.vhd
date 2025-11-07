library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity C64 is	
	port (
		CLK10        : in std_logic;   -- reference clock
		R            : out std_logic_vector(1 downto 0);
		G            : out std_logic_vector(1 downto 0);
		B            : out std_logic_vector(1 downto 0);
		HS           : out std_logic;
		VS           : out std_logic
	);	
end entity;

 
architecture immediate of C64 is

	component PLL_15_76 is
    port (
        CLKI: in  std_logic; 
        CLKOP: out  std_logic; 
        CLKOS: out  std_logic);
	end component;
	
	signal CLK16:std_logic;
begin
	
	pll0: PLL_15_76 port map ( CLK10, open, CLK16 );

	process (CLK16) 
	constant left:integer := 126;
	constant top:integer := 48;
	variable phase:integer range 0 to 1:=0;
	variable x:integer range 0 to 1023 := 0;
	variable y:integer range 0 to 1023 := 0;
	variable rgb:std_logic_vector(5 downto 0);
	begin
		if rising_edge(CLK16) then

			VS <= '1';
			HS <= '1';
			if y<3 and x<504-32 then
				HS <= '0';
			elsif y>=3 and	x<32 then
				HS <= '0';
			end if;

			rgb := "000000";
			if x>=left and x<left+320 and y>=top and y<top+240 then
				if x>=left+1 and x<left+320-1 and y>=top+1 and y<top+240-1 then
					if x>=left+20 and y>top+20 and x<left+20+256 and y<top+20+128 then
						rgb(5 downto 2) := std_logic_vector(to_unsigned( (x-(left+20)) / 16, 4 ));
						rgb(1 downto 0) := std_logic_vector(to_unsigned( (y-(top+20)) / 32, 2 ));
					end if;
				else
					rgb := "111111";
				end if;
			end if;
			R <= rgb(5 downto 4);
			G <= rgb(3 downto 2);
			B <= rgb(1 downto 0);
		
			if x<504-1 then
				x := x+1;
			else
				x := 0;
				if phase<1 then
					phase:=phase+1;
				else
					phase:=0;
					if y<312-1 then
						y := y+1;
					else
						y := 0;
					end if;
				end if;
			end if;
		end if;
	end process;
end immediate;
