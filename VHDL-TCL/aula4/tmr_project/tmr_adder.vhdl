library ieee;
    use ieee.std_logic_1164.all;

entity tmr_adder is 
    port(
        a : in std_logic_vector(7 downto 0);
        b : in std_logic_vector(7 downto 0);
        r : out std_logic_vector(7 downto 0)
    );
end tmr_adder;

architecture tmr_adder of tmr_adder is

signal w_s1 :std_logic_vector(7 downto 0);
signal w_s2 :std_logic_vector(7 downto 0);
signal w_s3 :std_logic_vector(7 downto 0);


begin 

    adder1 : entity work.adder
        port map ( 
            a => a,
            b => b,
            sum => w_s1
        );

    adder2 : entity work.adder
        port map ( 
            a => a,
            b => b,
            sum => w_s2
        );

    adder3 : entity work.adder
        port map ( 
            a => a,
            b => b,
            sum => w_s3
        );

    voter : entity work.voter
        port map (
            input1 => w_s1,
            input2 => w_s2,
            input3 => w_s3,
            r_output => r
        );

end tmr_adder;
