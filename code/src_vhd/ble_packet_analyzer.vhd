-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : ble_packet_analyzer.vhd
-- Description  : Analyseur de paquet BLE non synthétisable pour le laboratoire
--                de vérification SystemVerilog
--
-- Auteur       : Yann Thoma
-- Date         : 18.05.2017
-- Version      : 0.1
--
-- Utilise      :
--
--| Modifications |------------------------------------------------------------
-- Version   Auteur Date               Description
--
-------------------------------------------------------------------------------

-- TODO : Si un paquet de données est envoyé juste avant un advertizing
--        correspondant, il sera détecté dès que l'advertizing est arrivé.
--        Il faudrait flusher les paquets potentiellement existants si
--        nécessaire. Mais embêtant à coder...
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ble_packet_analyzer is
generic (
    ERRNO : integer := 0;
    VERBOSITY : integer := 0
);
port (
	clk_i     : in  std_logic;
	rst_i     : in  std_logic;
	serial_i  : in  std_logic;
    valid_i   : in  std_logic;
    channel_i : in std_logic_vector(6 downto 0);
	rssi_i    : in  std_logic_vector(7 downto 0);
	data_o    : out std_logic_vector(7 downto 0);
    valid_o   : out std_logic;
	frame_o   : out std_logic
);
end ble_packet_analyzer;

architecture behave of ble_packet_analyzer is

    constant ERRNO_OK                  : integer := 0;
    constant ERRNO_OK_SERIES           : integer := 1;
    constant ERRNO_RSSI                : integer := 2;
    constant ERRNO_ADDRESS_1           : integer := 3;
    constant ERRNO_ADDRESS_2           : integer := 4;
    constant ERRNO_ADV_INSTEAD_OF_DATA : integer := 5;
    constant ERRNO_LOST                : integer := 6;
    constant ERRNO_BUFSIZE             : integer := 7;

    -- Si ERRNO_BUFSIZE, alors le buffer n'a que 100 octets à disposition
	constant BUFSIZE: integer:= 10000; -- - ERRNO_BUFSIZE * 128;

	constant PREAMBLESIZE: integer := 8;
	constant PREAMBLE: std_logic_vector(PREAMBLESIZE-1 downto 0):=X"55";
	constant MAXDATASIZE: integer := 8*64;
	constant ADDRSIZE: integer := 32;
	constant HEADERSIZE: integer := 16;
	constant REGSIZE: integer:= MAXDATASIZE+HEADERSIZE+PREAMBLESIZE+ADDRSIZE;
	constant OUTPUTHEADERSIZE: integer := 4;
	constant ADV_ADDR: std_logic_vector(ADDRSIZE-1 downto 0):=X"12345678";

	constant ADDRMEMSIZE: integer := 16;

    constant NB_CHANNELS : integer := 79;

    type inreg_t is array(NB_CHANNELS-1 downto 0) of std_logic_vector(REGSIZE-1 downto 0);
	signal inreg_s: inreg_t;

	type rssi_reg_t is array(REGSIZE-1 downto 0) of std_logic_vector(7 downto 0);
    type rssi_full_reg_t is array(NB_CHANNELS-1 downto 0) of rssi_reg_t;
	signal rssi_reg_s: rssi_full_reg_t;

    type outbuf_data_t is record
        data : std_logic_vector(7 downto 0);
        start : boolean;
        endpacket : boolean;
    end record;

	type outbuf_t is array(BUFSIZE-1 downto 0) of outbuf_data_t;
	signal outbuf_s: outbuf_t;

	type addrmem_t is array(ADDRMEMSIZE-1 downto 0) of std_logic_vector(ADDRSIZE-1 downto 0);
	signal addrmem_s: addrmem_t;

	signal addrmem_valid_s: std_logic_vector(ADDRMEMSIZE-1 downto 0);

	signal bufcounter_s : integer:=0;

    signal channel_s : integer;

    signal last_channel_s : integer := -1;

    function isAdvChannel(channel : integer) return boolean is
    begin
        if (channel = 0) or (channel = 24) or (channel = 78) then
            return true;
        else
            return false;
        end if;
    end isAdvChannel;

    function isDataChannel(channel : integer) return boolean is
    begin
        return (not isAdvChannel(channel)) and ((channel mod 2) = 0);
    end isDataChannel;

begin


    channel_s <= to_integer(unsigned(channel_i));

	process(clk_i,rst_i)
		variable buf_in_counter_v: integer:=0;
		variable header_v: std_logic_vector(HEADERSIZE-1 downto 0);
		variable addr_v: std_logic_vector(ADDRSIZE-1 downto 0);
		variable data_v: std_logic_vector(MAXDATASIZE-1 downto 0);
		variable size_v: integer;
		variable rssi_v: integer;
		variable bufcounter_v: integer:=0;
		variable addrmem_counter_v: integer:=0;

		variable buf_out_counter_v: integer:=0;

        variable adv_bit : std_logic;

        variable loop_index : integer;
        variable high_index : integer;
        variable current_reg_v : std_logic_vector(REGSIZE-1 downto 0);
    	variable current_rssi_v : rssi_reg_t;

        variable packet_counter : integer := 0;

        variable outbuf_data_v : outbuf_data_t;
        variable output_enable_v : boolean := true;

		impure function addr_valid(addr: std_logic_vector(ADDRSIZE-1 downto 0)) return boolean is
		begin
			if ERRNO = ERRNO_ADDRESS_1 then
				return true;
			end if;
            if ERRNO = ERRNO_ADDRESS_2 then
                return false;
            end if;
			for i in 0 to ADDRMEMSIZE-1 loop
				if addrmem_valid_s(i)='1' and (addr=addrmem_s(i)) then
					return true;
				end if;
			end loop;
			return false;
		end function;


		impure function readwordp return outbuf_data_t is
			variable result_v: outbuf_data_t;
		begin
			result_v:=outbuf_s(buf_out_counter_v);
			buf_out_counter_v:=buf_out_counter_v+1;
			if buf_out_counter_v=BUFSIZE then
				buf_out_counter_v:=0;
			end if;
			bufcounter_v:=bufcounter_v-1;
            assert (bufcounter_v >= 0) report "Error in the DUT output buffer: less than empty" severity failure;
			return result_v;
        end function;

		impure function readword return std_logic_vector is
			variable result_v: std_logic_vector(7 downto 0);
		begin
			result_v:=outbuf_s(buf_out_counter_v).data;
			buf_out_counter_v:=buf_out_counter_v+1;
			if buf_out_counter_v=BUFSIZE then
				buf_out_counter_v:=0;
			end if;
			bufcounter_v:=bufcounter_v-1;
            assert (bufcounter_v >= 0) report "Error in the DUT output buffer: less than empty" severity failure;
			return result_v;
		end function;

		procedure writeword(value: in std_logic_vector(7 downto 0); startpacket : boolean := false; endpacket: boolean := false) is
		begin
			outbuf_s(buf_in_counter_v)<=(value, startpacket, endpacket);
			buf_in_counter_v:=buf_in_counter_v+1;
			if buf_in_counter_v=BUFSIZE then
				buf_in_counter_v:=0;
			end if;
			bufcounter_v:=bufcounter_v+1;
            assert (bufcounter_v <= BUFSIZE) report "Error in the DUT output buffer: more than full" severity failure;
		end procedure;

	begin
		if rst_i='1' then
			inreg_s<=(others=>(others=>'0'));
			rssi_reg_s<=(others=>(others=>(others=>'0')));

			buf_in_counter_v:=0;
			addrmem_s<=(others=>(others=>'0'));
			addrmem_valid_s<=(others=>'0');

			data_o<=(others=>'0');
            valid_o <= '0';
			frame_o<='0';
            last_channel_s <= -1;

		elsif rising_edge(clk_i) then

            -- output management

			bufcounter_v:=bufcounter_s;
			if (bufcounter_v>0) and output_enable_v then
                outbuf_data_v := readwordp;
                data_o <= outbuf_data_v.data;
                if outbuf_data_v.endpacket then
                    output_enable_v := false;
                end if;
                valid_o <= '1';
				frame_o<='1';
			else
				data_o<="UUUUUUUU";
                valid_o <= '0';
				frame_o<='0';
                output_enable_v := true;
			end if;




            -- input management

            if ((valid_i = '1') and ((ERRNO /= ERRNO_OK_SERIES) or (channel_s = (last_channel_s + 1) mod 79))) then
                last_channel_s <= channel_s;

                -- shift the registers
			    inreg_s(channel_s)<= inreg_s(channel_s)(REGSIZE-2 downto 0) & serial_i;
			    rssi_reg_s(channel_s)<= rssi_reg_s(channel_s)(REGSIZE-2 downto 0) & rssi_i;

                current_reg_v := inreg_s(channel_s)(REGSIZE-2 downto 0) & serial_i;
                current_rssi_v := rssi_reg_s(channel_s)(REGSIZE-2 downto 0) & rssi_i;

                high_index := -1;
                for i in REGSIZE-1 downto PREAMBLESIZE + ADDRSIZE + HEADERSIZE loop
        			if (current_reg_v(i downto i-PREAMBLESIZE+1)=PREAMBLE) then
                        -- report "Detected preamble";
                        -- report to_hstring(current_reg_v(i downto 0));
        				addr_v:=current_reg_v(i-PREAMBLESIZE downto i-PREAMBLESIZE-ADDRSIZE+1);
                        header_v:=current_reg_v(i-PREAMBLESIZE-ADDRSIZE downto i-PREAMBLESIZE-ADDRSIZE-HEADERSIZE+1);
        				if (addr_v=ADV_ADDR and isAdvChannel(channel_s)) or (addr_valid(addr_v) and isDataChannel(channel_s)) then
                            -- report "Detected address";
            				if addr_v=ADV_ADDR then -- Advertising
                                size_v:=to_integer(unsigned(header_v(3 downto 0)));
        					else -- Data
                                size_v:=to_integer(unsigned(header_v(5 downto 0)));
        					end if;
                            -- report "Size : " & integer'image(size_v);
                            -- report "Rest : " & integer'image(i - PREAMBLESIZE - ADDRSIZE - HEADERSIZE - 8* size_v + 1);
                            if (i - PREAMBLESIZE - ADDRSIZE - HEADERSIZE - 8* size_v + 1 >= 0) then
                                -- report "Detected packet";
                				high_index := i;
                                exit;
                            end if;
                        end if;
                    end if;
                end loop;

                if high_index /= -1 then
                    loop_index := 0;
                    for i in high_index-HEADERSIZE-PREAMBLESIZE-ADDRSIZE downto 0 loop
					    data_v(MAXDATASIZE-1-loop_index):=current_reg_v(i);
                        loop_index := loop_index + 1;
                    end loop;

                    inreg_s(channel_s)<=(others=>'0');

                    if (ERRNO /= ERRNO_LOST) then
					    if addr_v=ADV_ADDR then -- Advertising
                            if (VERBOSITY > 0) then
                                report "Dut detected advertising with address " & to_hstring(data_v(MAXDATASIZE-1 downto MAXDATASIZE-32));
						    end if;
						    writeword(std_logic_vector(to_unsigned(size_v+OUTPUTHEADERSIZE+2+4,8)));
					    else -- Data
                            if (VERBOSITY > 0) then
                                report "Dut detected data packet with address " & to_hstring(addr_v);
						    end if;
						    writeword(std_logic_vector(to_unsigned(size_v+OUTPUTHEADERSIZE+2+4,8)));
					    end if;

					    if addr_v=ADV_ADDR then
						    addrmem_valid_s(addrmem_counter_v)<='1';
						    addrmem_s(addrmem_counter_v)<=data_v(MAXDATASIZE-1 downto MAXDATASIZE-32);
						    addrmem_counter_v:=addrmem_counter_v+1;
						    if (addrmem_counter_v=ADDRMEMSIZE) then
							    addrmem_counter_v:=0;
						    end if;
					    end if;


    					rssi_v:=0;
    					for i in high_index downto high_index-size_v*8-ADDRSIZE-PREAMBLESIZE-HEADERSIZE+1 loop
    						rssi_v:=rssi_v+to_integer(unsigned(current_rssi_v(i)));
    					end loop;
    					rssi_v:=rssi_v/(size_v*8+ADDRSIZE+PREAMBLESIZE+HEADERSIZE);
                        if ERRNO = ERRNO_RSSI then
                            rssi_v := rssi_v + 1;
                        end if;
    					writeword(std_logic_vector(to_unsigned(rssi_v,8)));

    					if (addr_v=ADV_ADDR) then
                            adv_bit := '1';
    					else
    						adv_bit := '0';
                            if ERRNO = ERRNO_ADV_INSTEAD_OF_DATA then
                                adv_bit := '1';
                            end if;
    					end if;
                        writeword(channel_i & adv_bit);

    					writeword(X"00");

    					writeword(addr_v(7 downto 0));
    					writeword(addr_v(15 downto 8));
    					writeword(addr_v(23 downto 16));
    					writeword(addr_v(31 downto 24));

                        writeword(header_v(7 downto 0));
    					writeword(header_v(15 downto 8));
    					for i in 0 to size_v-1 loop
                            if i = size_v -1 then
                                writeword(data_v(MAXDATASIZE-1-8*i downto MAXDATASIZE-8*(i+1)), false, true);
                            else
                                writeword(data_v(MAXDATASIZE-1-8*i downto MAXDATASIZE-8*(i+1)));
                            end if;
					    end loop;
                    end if;
				end if;
			end if;
            bufcounter_s<=bufcounter_v;
		end if;
	end process;

end behave;
