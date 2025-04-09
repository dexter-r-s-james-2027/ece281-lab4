library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    
    signal clock_reset : std_logic; 
    signal fsm_reset : std_logic; 
    
    signal slow_clock: std_logic; 
    signal fast_clock: std_logic; 

    
    signal w_floor1 : std_logic_vector(3 downto 0); 
    signal w_floor2 : std_logic_vector(3 downto 0);  
    signal seg_houser: std_logic_vector(6 downto 0); 
    signal w_TDM4_o   : std_logic_vector(3 downto 0);
    signal w_F       : std_logic_vector(3 downto 0);
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
	
	elevator_controller_fsm_inst : elevator_controller_fsm
		port map (
            i_clk => slow_clock,     
            i_reset => fsm_reset, 
            is_stopped => sw(0),
            go_up_down => sw(1),
            o_floor => w_floor1 
		 );
		 
    elevator_controller_fsm_inst_2 : elevator_controller_fsm
		port map (
            i_clk => slow_clock,     
            i_reset => fsm_reset, 
            is_stopped => sw(14),
            go_up_down => sw(15),
            o_floor => w_floor2 
		 );
		 
	clkdiv_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 25000000 ) -- 2 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => clock_reset,
            o_clk   => slow_clock
        ); 
   
        
    clkdiv_inst_tdm : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 50000 ) -- 2 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => clock_reset,
            o_clk   => fast_clock
        ); 
        
    TDM_4 : TDM4
	   generic map (k_WIDTH => 4)
	   port map(
	       i_reset     => btnU,
	       i_clk       => fast_clock,
	       i_D0        => w_floor1,
	       i_D1        => w_F,
	       i_D2        => w_floor2,
	       i_D3        => w_F,
	       o_data      => w_TDM4_o,
	       o_sel       => an
	       );
	       
        
        
    sevenseg_decoder_inst : sevenseg_decoder
        port map (
            i_Hex => w_TDM4_o,     
            o_seg_n => seg_houser
        );
    
  
	-- CONCURRENT STATEMENTS ----------------------------

	seg <= seg_houser; 
	
	w_F <= x"F"; 
		
	

	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	
	led <= slow_clock & fast_clock &(13 downto 0 => '0'); 
	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.

	-- reset signals
	
	clock_reset <= btnU or btnL;
	fsm_reset <= btnU or btnR; 
	
end top_basys3_arch;


-- 
--    tdm_inst : TDM4
--        generic map (k_width => 4)
--        port map(
--            i_reset => 
--            i_D3 => 
        
        
--        );
