library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity TestPicture is	
	port (
		CLK10        : in std_logic;   -- reference clock
		R            : out std_logic_vector(1 downto 0);
		G            : out std_logic_vector(1 downto 0);
		B            : out std_logic_vector(1 downto 0);
		HS           : out std_logic;
		VS           : out std_logic
	);	
end entity;

 
architecture immediate of TestPicture is

	component PLL_25_175 is
    port (
        CLKI: in  std_logic; 
        CLKOP: out  std_logic; 
        CLKOS: out  std_logic);
	end component;
	
	signal CLK25:std_logic;
begin
	
	pll0: PLL_25_175 port map ( CLK10, open, CLK25 );

	process (CLK25) 
	constant left:integer := 96+48;
	constant top:integer := 2+31;
	variable x:integer range 0 to 1023 := 0;
	variable y:integer range 0 to 1023 := 0;
	variable rgb:std_logic_vector(5 downto 0);
	begin
		if rising_edge(CLK25) then
			if x<96 then
				HS <= '0';
			else
				HS <= '1';
			end if;
			if y<2 then
				VS <= '1';
			else
				VS <= '0';
			end if;

			rgb := "000000";
			if x>=left and x<left+640 and y>=top and y<top+480 then
				if x>=left+1 and x<left+640-1 and y>=top+1 and y<top+480-1 then
					if x>=left+20 and y>top+20 and x<left+20+512 and y<top+20+256 then
						rgb(5 downto 2) := std_logic_vector(to_unsigned( (x-(left+20)) / 32, 4 ));
						rgb(1 downto 0) := std_logic_vector(to_unsigned( (y-(top+20)) / 64, 2 ));
					end if;
				else
					rgb := "111111";
				end if;
			end if;
			R <= rgb(5 downto 4);
			G <= rgb(3 downto 2);
			B <= rgb(1 downto 0);
		
			if x<800-1 then
				x := x+1;
			else
				x := 0;
				if y<524-1 then
					y := y+1;
				else
					y := 0;
				end if;
			end if;
		end if;
	end process;
end immediate;
