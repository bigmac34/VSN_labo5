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

///< VKR exp: la solution des class paramétrées paraît pas mal, mais là on utilise des mailbox, je cois que c'est dans le même but !?!
class Scoreboard;

		///< VKR exp: pas besoin de setter la valeur, ça vient de l'environment
    int testcase;
		virtual usb_itf vif;

		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

		///< fonction de comparaison des packets
		function logic comparePackets(AnalyzerUsbPacket usb_packet, BlePacket ble_packet);
				logic isOk = 1;
				if(usb_packet.size-10 != ble_packet.size) begin					// Se les tailles des datas sont différentes
					$display("Bad size on comparison\n");
					isOk = 0;
				end
				if(usb_packet.isAdv != ble_packet.isAdv) begin				// Si les flag ne sont pas les mêmes
					$display("Bad flag on comparison\n");
					isOk = 0;
				end
				if(usb_packet.address != ble_packet.addr)	begin			// Si les adresses ne sont pas les mêmes
					$display("Bad address on comparison\n");
					isOk = 0;
				end
				if(usb_packet.data != ble_packet.data) begin					// Si les datas ne sont pas les mêmes
					$display("Bad data on comparison\n");
					isOk = 0;
				end
				return isOk;
		endfunction

		///< VKR exp: tâche lancée dans l'environment
    task run;
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
        //automatic BlePacket ble_packet = new;
				BlePacket tab_packet[40];
				int inc = 0;
				int i = 0;
        AnalyzerUsbPacket usb_packet = new;
				logic isOk = 0;

				$display("Scoreboard : Start");

				// De base, le champ valid est libre
				for(int i=0;i<40;i++) begin
						tab_packet[i] = new;
				end





				///< VKR exp: je sais pas si c'est optimal de faire avec un for, même problème que dans le dernier
				///< VKR exp: est-ce qu'il y a un moyen de faire sans savoir le nombre qu'on en envoit ??
        /*for(int i=0; i< 10; i++) begin
            sequencer_to_scoreboard_fifo.get(ble_packet);
            monitor_to_scoreboard_fifo.get(usb_packet);
            // Check that everything is fine
						$display("The scoreboard compare a %s", ble_packet.psprint());
						usb_packet.getFields();										// Pour setter les attributs de la class (affichage)
						$display("The scoreboard compare a %s", usb_packet.psprint());
						comparePackets(usb_packet, ble_packet, i);
        end*/

				while(1) begin
						inc = 0;
						// On vient chercher le premier emplacement libre
						while (tab_packet[inc].valid == 1) begin
								inc = inc + 1;
						end
						tab_packet[inc] = new;
						// On check pour voir si on a reçu un nouveau packet du sequencer
						if(sequencer_to_scoreboard_fifo.try_get(tab_packet[inc])) begin
							// Si le packet est ajouté, on informe le champ valid
							$display("A blepacket is recieved in the scoreboard, put in %d\n", inc);
							tab_packet[inc].valid = 1;
							//$display("valid = %d at inc %d", tab_packet[inc].valid, inc);
						end
						//$display("valid = %d", tab_packet[inc].valid);
						// On check pour voir si on a reçu un nouveau packet du monitor
						if(monitor_to_scoreboard_fifo.try_get(usb_packet)) begin
								$display("An usbpacket is recieved in the scoreboard\n");
								i = 0;
								isOk = 0;
								while(isOk == 0 && i < 40) begin
										//$display("i = %d", i);
										//$display("valid = %d", tab_packet[i].valid);
										if (tab_packet[i].valid == 1) begin
												// Check that everything is fine
												$display("The scoreboard compare a %s", tab_packet[i].psprint());
												usb_packet.getFields();										// Pour setter les attributs de la class (affichage)
												$display("The scoreboard compare a %s", usb_packet.psprint());
												isOk = comparePackets(usb_packet, tab_packet[i]);
												if (isOk == 1) begin
														tab_packet[i].valid = 0;
														$display("I found it !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
												end
										end
										i = i+1;
								end
						end
						@(posedge vif.clk_i);
				end
        $display("Scoreboard : End");
    endtask : run

endclass : Scoreboard

`endif // SCOREBOARD_SV
