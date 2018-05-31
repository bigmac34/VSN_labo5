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
--------------------------------------------------------------------------------
-- TESTCASE:
-- 		0: Fonctionnement classique, advertising puis data
--		1: Envoie de paquets de données avec une taille minimale
--		2: Envoie de paquets de données avec une taille maximale
--		3: Envoie de paquets de données sans paquet d'avertising avant
--		4: Envoie de paquets dont le préambule est incorrect
--		5: Envoie de paquet sur plus de 16 addresse

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

		// Envoi d'un paquet BLE aux FIFOs
		task sendBlePacket(int testcase, logic isAdv, logic[`TAILLE_ADRESSE-1:0] addr,int numPaquet);
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
				automatic BlePacket packet, packet2;

				packet = new;								// Il ne faut pas réutiliser celui qui est dans la mailbox
				packet.testcase = testcase;
				packet.isAdv = isAdv;
				packet.addr = addr;
				packet.numPaquet = numPaquet;

				void'(packet.randomize());
				packet2 = packet.copy();

				sequencer_to_driver_fifo.put(packet);
				sequencer_to_scoreboard_fifo.put(packet2);

				//$display("The sequencer sent a %s", packet.psprint());
				if(isAdv) begin
						$display("The sequencer sent a advertising blepacket\n");
				end
				else begin
						$display("The sequencer sent a blepacket\n");
				end
		endtask;

		///< VKR exp: tâche lancée dans l'environment
		task run;
				int nbPacket = 10;
				int nbAdvertising = 0;
				int nbData = 9;

				$display("Sequencer : start");

				// Sequence d'envoie classique: advertising puis data
				if(testcase < 6) begin

						// Nombres d'advertising supérieur à 16
						if(testcase == 5) begin
								nbAdvertising = `NB_MAX_ADRESSE + 1;
						end
						// Pas d'envoie de paquets d'advertising
						else if(testcase == 3) begin
								nbAdvertising = 0;
						end
						// Nombres d'advertising inférieur à 16
						else begin
								nbAdvertising = 1;
						end

						// Envoie des Advertising
						for(int i=0;i<nbAdvertising;i++) begin
								sendBlePacket(testcase, 1, 32'h1234ABCD, nbPaquetSend);
								nbPaquetSend++;
						end

						//Envoie de packets de données random encore 9 fois (10 au total)
		        for(int i=0;i<nbData;i++) begin
								sendBlePacket(testcase, 0, 32'h1234ABCD, nbPaquetSend);
								nbPaquetSend++;
						end
				end

				// Envoie d'un advertising puis d'une data, ainsi de suite
				else if(testcase == 6) begin
						logic[`TAILLE_ADRESSE-1:0] address;
						for(int i=0;i<nbPacket;i++) begin
								address = $random;
								sendBlePacket(testcase, 1, address, nbPaquetSend);
								nbPaquetSend++;

								sendBlePacket(testcase, 0, address, nbPaquetSend);
								nbPaquetSend++;
						end
				end

				else begin
						$error("Sequencer : testcase invalid");
				end

        $display("Sequencer : end");
    endtask : run

endclass : Sequencer

`endif // SEQUENCER_SV
