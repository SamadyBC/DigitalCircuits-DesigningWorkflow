library ieee;
    use ieee.std_logic_1164.all;

entity voter is
    port(
        input1 : in std_logic_vector(7 downto 0);
        input2 : in std_logic_vector(7 downto 0);
        input3 : in std_logic_vector(7 downto 0);
        r_output : out std_logic_vector(7 downto 0)
    );
end voter;

architecture voter of voter is

signal S1 : std_logic_vector(7 downto 0);
signal S2 : std_logic_vector(7 downto 0);
signal S3 : std_logic_vector(7 downto 0);

begin

    S1 <= input1;
    S2 <= input2;
    S3 <= input3;

    r_output <= (S1 and S2) or (S1 and S3) or (S2 and S3);

end;
