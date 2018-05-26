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
		int nbPaquetSend = 0;

		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;

		// Fonction eventuellement appellée par le watchdog (seulement si la task ne se termine pas)
		function void printStatus();
				$info("The sequencer send %0d BlePackets \n", nbPaquetSend);
		endfunction

		///< VKR exp: tâche lancée dans l'environment
		task run;
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
				automatic BlePacket packet, packet2;
				$display("Sequencer : start");

				// Envoie de paquets d'advertising
				if(testcase != 3) begin
						// Nombres d'advertising supérieur à 16
						int nbAdvertising;
						if(testcase == 5) begin
								nbAdvertising = `NB_MAX_ADRESSE + 1;
						end
						// Nombres d'advertising inférieur à 16
						else begin
								nbAdvertising = 1;
						end

						// Envoie des Advertising
						for(int i=0;i<nbAdvertising;i++) begin
				        packet = new;
								packet.testcase = testcase;
				        packet.isAdv = 1;
								packet.addr = 32'h1234ABCD;
								packet.numPaquet = nbPaquetSend;
								///< VKR exp: void' bit de status retourné par randomize() casté en void car ignoré (il dit si la rando. c'est bien passée)
				        void'(packet.randomize());
								packet2 = packet.copy();

								///< VKR exp: mise dans les fifo pour le driver et le scoreboard (opérations bloquantes)
				        sequencer_to_driver_fifo.put(packet);
				        sequencer_to_scoreboard_fifo.put(packet2);
								nbPaquetSend++;
								//$display("The sequencer sent a %s", packet.psprint());
								$display("The sequencer sent a advertising blepacket\n");
						end
				end

				//Envoie de packets de données random encore 9 fois (10 au total)
        for(int i=0;i<9;i++) begin

            packet = new;								// Il ne faut pas réutiliser celui qui est dans la mailbox
						packet.testcase = testcase;
						packet.isAdv = 0;
						packet.addr = 32'h1234ABCD;
						packet.numPaquet = nbPaquetSend;

            void'(packet.randomize());
						packet2 = packet.copy();

            sequencer_to_driver_fifo.put(packet);
            sequencer_to_scoreboard_fifo.put(packet2);
						nbPaquetSend++;

						//$display("The sequencer sent a %s", packet.psprint());
						$display("The sequencer sent a blepacket\n");
				end

        $display("Sequencer : end");
    endtask : run

endclass : Sequencer


`endif // SEQUENCER_SV
