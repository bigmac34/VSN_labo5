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

`include "constant.sv"

class Sequencer;
		///< VKR exp: pas besoin de setter la valeur, ça vient de l'environment
		int testcase;
		virtual ble_itf vif;


		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;

		///< VKR exp: tâche lancée dans l'environment
		task run;
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
        automatic BlePacket packet, packet2;
        $display("Sequencer : start");

        packet = new;
        packet.isAdv = 1;
				///< VKR exp: void' bit de status retourné par randomize() casté en void car ignoré (il dit si la rando. c'est bien passée)
        void'(packet.randomize());
				packet2 = packet.copy();

				///< VKR exp: mise dans les fifo pour le driver et le scoreboard (opérations bloquantes)
        sequencer_to_driver_fifo.put(packet);
        sequencer_to_scoreboard_fifo.put(packet2);
				$display("The sequencer sent a %s", packet.psprint());

				///< VKR exp: envoit d'un packet random encore 9 fois (10 au total)
        for(int i=0;i<9;i++) begin

            packet = new;								// Il ne faut pas réutiliser celui qui est dans la mailbox
						packet.isAdv = 0;
            void'(packet.randomize());
						packet2 = packet.copy();

            sequencer_to_driver_fifo.put(packet);
            sequencer_to_scoreboard_fifo.put(packet2);

						$display("The sequencer sent a %s", packet.psprint());
				end
        $display("Sequencer : end");
    endtask : run

endclass : Sequencer


`endif // SEQUENCER_SV
