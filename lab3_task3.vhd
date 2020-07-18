-- Filename: lab3_task3
-- Author 1: Harry Gong
-- Author 1 Student #:301223952
-- Author 2:He Sun
-- Author 2 Student #:301243992
-- Group Number:42
-- Lab Section
-- Lab:
-- Task Completed: lines without delay
-- Date: 21/02/2017
------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3_task3 is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab3_task3;

architecture rtl of lab3_task3 is


 --Component from the Verilog file: vga_adapter.v

  component vga_adapter
    generic(RESOLUTION : string);
    port (resetn                                       : in  std_logic;
          clock                                        : in  std_logic;
          colour                                       : in  std_logic_vector(2 downto 0);
          x                                            : in  std_logic_vector(7 downto 0);
          y                                            : in  std_logic_vector(6 downto 0);
          plot                                         : in  std_logic;
          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
  end component;

  signal x      : std_logic_vector(7 downto 0);
  signal y      : std_logic_vector(6 downto 0);
  signal colour : std_logic_vector(2 downto 0);
  signal plot   : std_logic;
  signal Reduced_output : std_logic;
  signal Counter: std_logic_vector (25 downto 0);
  signal current_state : std_logic_vector(1 downto 0);
  signal x_1 : std_logic_vector(7 downto 0);
  signal y_1 : std_logic_vector(6 downto 0);
  signal clr_scr : std_logic;
  signal increment : std_logic;
  signal line_drawn :std_logic;
  signal delete_line : std_logic;
begin

  -- includes the vga adapter, which should be in your project

  vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120")
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => x,
             y         => y,
             plot      => plot,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);


  -- rest of your code goes here, as well as possibly additional files
process(current_state)
begin
        case current_state is
			when "00" => --preset state        
							increment<='0';
							line_drawn<='1';
							delete_line <= '1';
							plot<='1';
			 when "01" => -- draw line state
							increment<='1';
					   line_drawn<='0';
							delete_line <= '1';
						 plot<='1';
			 when "10" => -- done state      
							increment<='1';
							line_drawn<='1';
							delete_line <= '0';
							plot<='0';
			 when others => -- done state
							increment<='1';
						line_drawn<='1';
					   plot<='0';
			 end case;
        end process;

process(clock_50,key(3))
variable x0,y0, x1, y1, sx,sy ,dx, dy ,loop_count, e2,err: integer;
begin
if(key(3) = '0') then
        current_state<="00"; -- go the preset state and clear all registers
        colour<="000";
        x0:=0;
        y0:=0;
        x1:=0;
        y1:=0;
        sx:=0;
        sy:=0;
        dx:=0;
        dy:=0;
        loop_count:=1; -- reset loop count to 1
        e2:=0;
        err:=0;
elsif(rising_edge(clock_50)) then
        if( increment ='0') then -- preset algorithm
                if(loop_count>14) then
                        current_state<="11";
                else
                        if (loop_count mod 8 = 0) then
                                colour<="000"; -- grey code of colour
                        elsif(loop_count mod 8  = 1) then
                                colour<="001";
                        elsif (loop_count mod 8 = 2) then
                                colour<="011";
                        elsif (loop_count mod 8 = 3) then
                                colour<="010";
                        elsif (loop_count mod 8 = 4) then
                                colour<="110";
                        elsif (loop_count mod 8 = 5) then
                                colour<="111";
                        elsif (loop_count mod 8= 6) then
                                colour<="101";
                        elsif (loop_count mod 8= 7) then
                                colour<="100";
                        end if;
                        x0 := 0;
                        y0 := loop_count*8; -- determine the y0
                        x1 := 159;
                        y1 := 120-loop_count*8; --determine the y1
                        loop_count:=loop_count+1; -- find the next set of the start point and end point
                        if(x1>x0) then
                                dx:=x1-x0;
                        else
                                dx:=x0-x1;
                        end if;
                        if(y1>y0) then
                                dy:=y1-y0;
                        else
                                dy:=y0-y1;
                        end if;        
                        if (x0 < x1) then -- determine the line drawing of x axis from left to right or right to left
                                sx := 1;
                        else
                                sx := -1;
                        end if;
                        if (y0 < y1) then -- determine the line drawing of y axis from high to low or low to high
                                sy := 1;
                        else
                                sy := -1;
                        end if;
                        err := dx-dy;
                        
                        current_state<="01"; -- go to the draw line state
                end if;

        elsif(line_drawn ='0') then -- draw line algorithm
                if ((x0 = x1) and (y0 = y1)) then  -- when one draw line operation finished     
                                current_state<="00"; -- go to the preset state to prepare the next set of start and end point
                else
                        e2 := 2*err;
                        if (e2 > dy*(-1)) then
                                err:=err-dy;
                                x0:=x0+sx;
                        end if;
                        if (e2 < dx) then
                                err:=err+dx;
                                y0:=y0+sy;
                        end if;
                end if;        
                
        end if;
        
end if;
x<=std_logic_vector(to_unsigned(x0,x'length));
y<=std_logic_vector(to_unsigned(y0,y'length));
                        
end process;



end RTL;

