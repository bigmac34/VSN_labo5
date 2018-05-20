/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: sequencer.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Sequencer de la structure de test envoit au scoreboard et au driver
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef SEQUENCER_SV
`define SEQUENCER_SV

class Sequencer;
		///< VKR exp: pas besoin de setter la valeur, ça vient de l'environment
		int testcase;

		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;

		///< VKR exp: tâche lancée dans l'environment
		task run;
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
        automatic BlePacket packet;
        $display("Sequencer : start");

        packet = new;
        packet.isAdv = 1;
				///< VKR exp: void' bit de status retourné par randomize() casté en void car ignoré (il dit si la rando. c'est bien passée)
        void'(packet.randomize());

				///< VKR exp: mise dans les fifo pour le driver et le scoreboard (opérations bloquantes)
        sequencer_to_driver_fifo.put(packet);
        sequencer_to_scoreboard_fifo.put(packet);

        $display("I sent an advertising packet!!!!");

				///< VKR exp: envoit d'un packet random encore 9 fois (10 au total)
        for(int i=0;i<9;i++) begin

            packet = new;								// Il ne faut pas réutiliser celui qui est dans la mailbox
            packet.isAdv = 0;
            void'(packet.randomize());

            sequencer_to_driver_fifo.put(packet);
            sequencer_to_scoreboard_fifo.put(packet);

            $display("I sent a packet!!!!");
						$display(packet.psprint());
				end
        $display("Sequencer : end");
    endtask : run

		///< JMI: Ajout pour la création
/*		task test_dirige()
			automatic BlePacket packet;
			$display("Sequencer : start test_dirige ");

			packet = new;
			// Advertising
			packet.isAdv 		= 1;
			packet.header 	= 32'hFFFFFFFF
			packet.rawData 	= 512'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
			packet.size 		=

			// Data
			packet.isAdv 		= 0;
			packet.addr 		= 32'hFFFFFFFF
			packet.header 	= 32'hFFFFFFFF
			packet.rawData 	= 512'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF
			packet.size 		=

		endtask : test_dirige()
*/

endclass : Sequencer


`endif // SEQUENCER_SV
