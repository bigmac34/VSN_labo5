/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: scoreboard.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Scoreboard de la structure de test (reçoit du sequencer et du moniteur)
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "constant.sv"

///< VKR exp: la solution des class paramétrées paraît pas mal, mais là on utilise des mailbox, je cois que c'est dans le même but !?!
class Scoreboard;

		///< VKR exp: pas besoin de setter la valeur, ça vient de l'environment
    int testcase;
		virtual usb_itf vif;

		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

		///< fonction de comparaison des packets
		function logic comparePackets(AnalyzerUsbPacket usb_packet, BlePacket ble_packet, int compNumb);
				logic isOk = 1;
				if(usb_packet.size-10 != ble_packet.size) begin					// Si les tailles des datas sont différentes
						//$display("The scoreboard sees a bad size on comparison number %d\n", compNumb);  // dispaly error fatal
						isOk = 0;
				end
				if(usb_packet.rssi != ble_packet.rssi) begin						// Si le rssi jouée n'est pas le même que celui reçu dans le packet_usb
						//$display("The scoreboard sees a bad rssi on comparison number %d\n", compNumb);
						isOk = 0;
				end
				if(usb_packet.isAdv != ble_packet.isAdv) begin				// Si les flag ne sont pas les mêmes
						//$display("The scoreboard sees a bad flag on comparison number %d\n", compNumb);
						isOk = 0;
				end
				if(usb_packet.address != ble_packet.addr)	begin			// Si les adresses ne sont pas les mêmes
						//$display("The scoreboard sees a bad address on comparison number %d\n", compNumb);
						isOk = 0;
				end
				if(usb_packet.data != ble_packet.data) begin					// Si les datas ne sont pas les mêmes
						//$display("The scoreboard sees a bad data on comparison number %d\n", compNumb);
						isOk = 0;
				end
				return isOk;
		endfunction

		///< VKR exp: tâche lancée dans l'environment
    task run;
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
        // automatic BlePacket ble_packet = new;

				// Pour stocker les paquets en tout genre
				BlePacket bleTab[40];		// 40, nombre maximum de canaux

				AnalyzerUsbPacket usb_packet = new;		// Pas forcément besoin du new, il est déjà créé normalement

				int findFirstEmpty = 0;				// Pour trouver la première case vide
				int findInBleTab = 0;
				int nbUsbPacketReceived = 0;
				logic paquetFound = 0;
				int compNumb = 0;

				$display("Scoreboard : Start");

				// De base, le champ valid est libre
				for(int i=0;i<40;i++) begin
						bleTab[i] = new;
				end

				while(nbUsbPacketReceived < 10) begin
						findFirstEmpty = 0;
						// On vient chercher le premier emplacement libre
						while (bleTab[findFirstEmpty].valid == 1) begin
								findFirstEmpty = findFirstEmpty + 1;
						end
						bleTab[findFirstEmpty] = new;
						// On check pour voir si on a reçu un nouveau packet du sequencer
						if(sequencer_to_scoreboard_fifo.try_get(bleTab[findFirstEmpty])) begin
							// Si le packet est ajouté, on informe le champ valid
							//$display("A blepacket is recieved in the scoreboard, put in %d\n", findFirstEmpty);
							$display("The scoreboard recieved a blepacket\n");
							bleTab[findFirstEmpty].valid = 1;
							//$display("valid = %d at findFirstEmpty %d", tab_packet[findFirstEmpty].valid, findFirstEmpty);
						end
						//$display("valid = %d", tab_packet[findFirstEmpty].valid);
						// On check pour voir si on a reçu un nouveau packet du monitor
						if(monitor_to_scoreboard_fifo.try_get(usb_packet)) begin
								nbUsbPacketReceived = nbUsbPacketReceived + 1;
								$display("The scoreboard recieved an usbpacket, tries to find a corresponding blePacket\n");
								findInBleTab = 0;
								paquetFound = 0;
								compNumb = 0;
								while(paquetFound == 0 && findInBleTab < 40) begin
										//$display("i = %d", i);
										//$display("valid = %d", tab_packet[i].valid);
										if (bleTab[findInBleTab].valid == 1) begin
												// Check that everything is fine
												//$display("The scoreboard compare a %s", tab_packet[i].psprint());
												usb_packet.getFields();										// Pour setter les attributs de la class (affichage)
												//$display("The scoreboard compare a %s", usb_packet.psprint());
												//$display("The scoreboard compare two packets\n");
												paquetFound = comparePackets(usb_packet, bleTab[findInBleTab], compNumb);
												if (paquetFound == 1) begin
														bleTab[findInBleTab].valid = 0;							// The packet will no more be taken in next comparisons
														$display("The scoresboard found a corresponding blePacket to the UsbPacket \n");
												end
												compNumb = compNumb + 1;
										end
										findInBleTab = findInBleTab+1;
								end
								if (paquetFound == 0) begin
										$error("The scoresboard found no corresponding blePacket to the UsbPacket\n");
								end
						end
						@(posedge vif.clk_i);
				end
        $display("Scoreboard : End");
    endtask : run

endclass : Scoreboard

`endif // SCOREBOARD_SV
