/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: scoreboard.sv
-- Authors	: Jérémie Macchi
--			  Vivien Kaltenrieder
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
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "constant.sv"

class Scoreboard;

	virtual usb_itf vif;		// Interface l'USB
	virtual run_itf wd_sb_itf;	// Interface pour le watchdog

	// Initialisation des variables
	int nbBleIgnored = 0;
	int nbUsbPacketNotFound = 0;
	int nbUsbPacketReceived = 0;
	int nbBlePacketConsidered = 0;
	int nbBadPreambule = 0;
	int advBleTabPos = 0;
	logic advFound = 0;
	int nbUSBRecievedWithoutAdv = 0;
	string remainingBlePaquets = "Remaining BlePaquets ";
	string buffer = "";

	// Pour stocker les paquets en tout genre
	BlePacket bleTab[`NB_MAX_PAQUET_SEND];

	// Pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

	/*---------------
	-- printStatus --
	---------------*/
	// Fonction eventuellement appellée par le watchdog (seulement si la task ne se termine pas)
	function void printStatus();
		if ((nbBlePacketConsidered == nbUsbPacketReceived) && (nbUsbPacketNotFound == 0) && (nbUSBRecievedWithoutAdv == 0)) begin
			$info("The scoreboard :\n         %0d BlePacket from the sequencer were considered\n         %0d UsbPackets from the monitor were received\n         %0d UsbPackets with no matching BlePaquet were received\n         %0d BlePacket were ignored because no advertising was sent before\n         %0d BlePacket were ignored because of a bad preambule\n         %0d UsbPacket without corresponding BlePacket advertising were recieved \n", nbBlePacketConsidered, nbUsbPacketReceived, nbUsbPacketNotFound, nbBleIgnored, nbBadPreambule, nbUSBRecievedWithoutAdv);
		end
		else begin
			// Récupération des paquets ble qui n'ont aucune correspondance
			for(int i = 0; i < `NB_MAX_ADRESSE; i++) begin
				if (bleTab[i] != null) begin
					if (bleTab[i].isAdv == 1) begin
						$sformat(buffer, " %0d (Adv) ", bleTab[i].numPaquet);
					end
					else begin
						$sformat(buffer, " %0d (Data) ", bleTab[i].numPaquet);
					end
					remainingBlePaquets = {remainingBlePaquets, buffer};
				end
			end
			$error("The scoreboard :\n         %0d BlePacket from the sequencer were considered\n         %0d UsbPackets from the monitor were received\n         %0d UsbPackets with no matching BlePaquet were received\n         %0d BlePacket were ignored because no advertising was sent before\n         %0d BlePacket were ignored because of a bad preambule\n         %0d UsbPacket without corresponding BlePacket advertising were recieved \n         %s\n",
								nbBlePacketConsidered, nbUsbPacketReceived, nbUsbPacketNotFound, nbBleIgnored, nbBadPreambule,nbUSBRecievedWithoutAdv, remainingBlePaquets);
		end
	endfunction

	/*------------------
	-- comparePackets --
	------------------*/
	///< fonction de comparaison des packets
	function logic comparePackets(AnalyzerUsbPacket usb_packet, BlePacket ble_packet, int compNumb);
		logic isOk = 1;
		// Si les tailles des datas sont différentes
		if(usb_packet.size-10 != ble_packet.size) begin
			//$display("The scoreboard sees a bad size on comparison number %d\n", compNumb);  // dispaly error fatal
			isOk = 0;
		end
		// Si le rssi jouée n'est pas le même que celui reçu dans le packet_usb
		if(usb_packet.rssi != ble_packet.rssi) begin
			//$display("The scoreboard sees a bad rssi on comparison number %d\n", compNumb);
			isOk = 0;
		end
		// Si les flag ne sont pas les mêmes
		if(usb_packet.isAdv != ble_packet.isAdv) begin
			//$display("The scoreboard sees a bad flag on comparison number %d\n", compNumb);
			isOk = 0;
		end
		// Si les adresses ne sont pas les mêmes
		if(usb_packet.address != ble_packet.addr)	begin
			//$display("The scoreboard sees a bad address on comparison number %d\n", compNumb);
			isOk = 0;
		end
		// Si les datas ne sont pas les mêmes
		if(usb_packet.data != ble_packet.data) begin
			//$display("The scoreboard sees a bad data on comparison number %d\n", compNumb);
			isOk = 0;
		end
		return isOk;
	endfunction

	/*-------
	-- run --
	-------*/
	///< VKR exp: tâche lancée dans l'environment
    task run();

		// Pour stocker les advertising
		address_t advTab[`NB_MAX_ADRESSE];

		AnalyzerUsbPacket usb_packet;	// Pas forcément besoin du new, il est déjà créé

		// Initialisation des variables
		int findFirstEmpty = 0;			// Pour trouver la première case vide
		int findInBleTab = 0;
		logic paquetFound = 0;
		int compNumb = 0;

		$display("Scoreboard : Start");

		// On set tout le tableau à null pour trouver les cases vide par la suite
		for(int i=0;i<`NB_MAX_PAQUET_SEND;i++) begin
			bleTab[i] = null;
		end

		// Va être stopper par le watchdog
		while(1) begin
			findFirstEmpty = 0;
			// On vient chercher le premier emplacement libre
			while (bleTab[findFirstEmpty] != null) begin
				findFirstEmpty = findFirstEmpty + 1;
			end
			// On check pour voir si on a reçu un nouveau packet du sequencer
			if(sequencer_to_scoreboard_fifo.try_get(bleTab[findFirstEmpty])) begin
				// On dit au watchdog que ça bouge tjrs
				wd_sb_itf.isRunning = 1;

				// Si le prea est le bon, on continue
				if (bleTab[findFirstEmpty].preamble == `PREAMBULE) begin
					// Si ce n'est pas un advertising, on regarde si on a reçu un advertising correspondant avant
					if (bleTab[findFirstEmpty].isAdv == 0) begin
						advFound = 0;
						for(int i = 0; i < `NB_MAX_ADRESSE; i++) begin
							if (bleTab[findFirstEmpty].addr == advTab[i]) begin
								advFound = 1;
							end
						end
						// S'il n'y a pas paquet Ble correspondant envoyer par le sequencer
						if (advFound == 0) begin
							$info("The scoreboard ignored the BlePacket number %0d, no corresponding advertising sent before by the sequencer\n", bleTab[findFirstEmpty].numPaquet);
							bleTab[findFirstEmpty] = null; // On remet à null pour que la case puisse être prise par la suite
							nbBleIgnored++;
						end
						// S'il a un paquet Ble correspondant envoyer par le sequencer
						else begin
							$display("The scoreboard recieved a data BlePacket\n");
							nbBlePacketConsidered ++;
					  	end
					end
					// Sinon si c'est un advertising on l'ajoute simplement
					else begin
						nbBlePacketConsidered ++;	// Incrémentation du nombre de d'advertizing considéré
						$display("The scoreboard recieved an advertising BlePacket\n");
						advTab[advBleTabPos] = bleTab[findFirstEmpty].getDeviceAdd();
						advBleTabPos = (advBleTabPos + 1) % `NB_MAX_ADRESSE;
					end
					//$display("valid = %d at findFirstEmpty %d", tab_packet[findFirstEmpty].valid, findFirstEmpty);
				end
				// Si le préambule du paquet est incorrect
				else begin
					$info("The scoreboard ignored the BlePacket number %0d beacause of a bad preambule\n", bleTab[findFirstEmpty].numPaquet);
					nbBadPreambule++;
				end
			end
			//$display("valid = %d", tab_packet[findFirstEmpty].valid);

			// On check pour voir si on a reçu un nouveau packet usb du monitor
			if(monitor_to_scoreboard_fifo.try_get(usb_packet)) begin
				// On dit au watchdog que ça bouge tjrs
				wd_sb_itf.isRunning = 1;

				nbUsbPacketReceived ++;
				usb_packet.getFields();										// Pour setter les attributs de la class (affichage)
				findInBleTab = 0;
				paquetFound = 0;
				compNumb = 0;

				// Si c'est pas un advertising, on regarde dans un premier temps s'il a été enregistrer dans le scoreboard
				if (usb_packet.isAdv == 0) begin
					advFound = 0;
					for(int i = 0; i < `NB_MAX_ADRESSE; i++) begin
						if (usb_packet.address == advTab[i]) begin
							advFound = 1;
						end
					end
					if (advFound == 0) begin
						$error("No advertising received by the sequencer for the UsbPacket received by the scoreboard");
						nbUSBRecievedWithoutAdv++;
					end
				end

				// Si c'est un paquet de données ou qu'un advertising à été trouvé
				if (usb_packet.isAdv == 1 || advFound == 1) begin
					// Si c'est un paquet de données
					if (usb_packet.isAdv == 0) begin
						$display("The scoreboard recieved a valid data UsbPacket, tries to find a corresponding BlePacket\n");
					end
					// Si c'est un advertsing
					else begin
						$display("The scoreboard recieved an advertising UsbPacket, tries to find a corresponding BlePacket\n");
					end

					paquetFound = 0;
					findInBleTab = 0;
					// Tant qu'une correspondance avec un paquet n'a pas été trouvé et que tout les paquets n'ont pas été comparé
					while(paquetFound == 0 && findInBleTab < `NB_MAX_PAQUET_SEND) begin
						// S'il y a un paquet Ble
						if (bleTab[findInBleTab] != null) begin
							paquetFound = comparePackets(usb_packet, bleTab[findInBleTab], compNumb);	// test si le paquet correspond
							compNumb = compNumb + 1;
						end
						//$display("The scoreboard compare two packets\n");
						//$display("The scoreboard compare a %s", usb_packet.psprint());
						//$display("The scoreboard compare a %s", bleTab[findInBleTab].psprint());
						// Si un paquet a été trouvé
						if (paquetFound == 1) begin
							bleTab[findInBleTab] = null;
							$info("The scoresboard found a corresponding BlePacket to the UsbPacket \n");
						end
						findInBleTab++;		// Incrémentation de la postion du paquet à comparé
					end
				end
				// S'il n'y pas de paquet qui a été trouvée mais qu'il y a eu un advertising avant
				if (paquetFound == 0 && advFound == 1) begin
					$error("The scoresboard found no corresponding blePacket to the UsbPacket\n");
					nbUsbPacketNotFound++;
				end
			end
			@(posedge vif.clk_i);	// Attend un flanc montant sur le clk
		end
        $display("Scoreboard : End");
    endtask : run


	/*-------------------
	-- watchdogDisable --
	-------------------*/
	// Appellé par le watchdog pour arreter
	task watchdogDisable;
		$display("The watchdog stopped the scoreboard");
		disable run;
	endtask : watchdogDisable;

endclass : Scoreboard

`endif // SCOREBOARD_SV
