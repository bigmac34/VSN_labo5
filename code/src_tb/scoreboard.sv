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
	int nbBleIgnored = 0;				// Nombre de paquets ignorés car aucun advertising envoyé avant
	int nbUsbPacketNotFound = 0;		// Nombre de paquets USB pas trouvés dans la liste des paquets BLE
	int nbUsbPacketReceived = 0;		// Nombre de paquets USB reçus
	int nbBlePacketConsidered = 0;		// Nombre de paquets BLE considérés
	int nbBadPreamble = 0;				// Nombre de paquets BLE détectés avec un mauvais préambule
	int advBleTabPos = 0;				// Position de la prochaine case vide dans le tableau d'adresses advertisées
	logic advFound = 0;					// Flag indiquant si un advertising est trouvé (pour Ble et USB)
	int nbUSBRecievedWithoutAdv = 0;	// Nombre de paquets USB reçus avec aucun Advertising du séquenceur reçu
	string remainingBlePaquets = "Remaining BlePaquets ";
	string buffer = "";					// Pour afficher les paquets Ble qui n'ont pas reçus de paquets USB correspondant

	// Pour stocker les paquets Ble
	BlePacket bleTab[`NB_MAX_BLE_PAQUET];

	// Pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

	/*---------------
	-- printStatus --
	---------------*/
	// Fonction appellée dans l'environment
	function void printStatus();
		// Si il y a aucune erreur
		if ((nbBlePacketConsidered == nbUsbPacketReceived) && (nbUsbPacketNotFound == 0) && (nbUSBRecievedWithoutAdv == 0)) begin
			$info("The scoreboard :\n         %0d BlePacket from the sequencer were considered\n         %0d UsbPackets from the monitor were received\n         %0d UsbPackets with no matching BlePaquet were received\n         %0d BlePacket were ignored because no advertising was sent before\n         %0d BlePacket were ignored because of a bad preamble\n         %0d UsbPacket without corresponding BlePacket advertising were recieved \n", nbBlePacketConsidered, nbUsbPacketReceived, nbUsbPacketNotFound, nbBleIgnored, nbBadPreamble, nbUSBRecievedWithoutAdv);
		end
		// Sinon, il y a des erreurs (affichage différent)
		else begin
			// Récupération des paquets Ble qui n'ont aucune correspondance
			for(int i = 0; i < `NB_MAX_ADDRESS; i++) begin
				// Si il y a un paquet à cette position dans le tableau
				if (bleTab[i] != null) begin
					if (bleTab[i].isAdv == 1) begin
						$sformat(buffer, " %0d (Adv) ", bleTab[i].numPaquet);
					end
					else begin
						$sformat(buffer, " %0d (Data) ", bleTab[i].numPaquet);
					end
					remainingBlePaquets = {remainingBlePaquets, buffer};  // COnstruction d'une string pour affichés les IDs des paquets restants
				end
			end
			$error("The scoreboard :\n         %0d BlePacket from the sequencer were considered\n         %0d UsbPackets from the monitor were received\n         %0d UsbPackets with no matching BlePaquet were received\n         %0d BlePacket were ignored because no advertising was sent before\n         %0d BlePacket were ignored because of a bad preamble\n         %0d UsbPacket without corresponding BlePacket advertising were recieved \n         %s\n",
								nbBlePacketConsidered, nbUsbPacketReceived, nbUsbPacketNotFound, nbBleIgnored, nbBadPreamble,nbUSBRecievedWithoutAdv, remainingBlePaquets);
		end
	endfunction

	/*------------------
	-- comparePackets --
	------------------*/
	// fonction de comparaison des paquets
	function logic comparePackets(AnalyzerUsbPacket usb_packet, BlePacket ble_packet, int compNumb);
		logic isOk = 1;				// 1 = pas de différences
		// Si les tailles des datas sont différentes
		if(usb_packet.size-10 != ble_packet.size) begin
			//$display("The scoreboard sees a bad size on comparison number %d\n", compNumb);  // dispaly error fatal
			isOk = 0;
		end
		// Si le rssi joué n'est pas le même que celui reçu dans le packet_usb
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
	// Tâche lancée dans l'environment
    task run();

		// Tableau pour stocker les adresses advertisées
		address_t advTab[`NB_MAX_ADDRESS];

		AnalyzerUsbPacket usb_packet;

		int findFirstEmpty = 0;			// Pour trouver la première case vide dans le tableau de paquet Ble
		int findInBleTab = 0;			// Pour la recherche d'un paquet Ble correspondant à un paquet USB
		logic paquetFound = 0;			// Pou indiquer si un paquet correspondant est trouvé
		int compNumb = 0;				// Compteur pour le nombre de comparaison réalisée

		$display("Scoreboard : Start");

		// On set tout le tableau à null pour trouver les cases vides par la suite
		for(int i=0;i<`NB_MAX_BLE_PAQUET;i++) begin
			bleTab[i] = null;
		end

		// Boucle infinie stoppée par le watchdog
		while(1) begin

			// ------------ Traitement des paquets Ble ------------ //
			// On vient chercher le premier emplacement libre
			findFirstEmpty = 0;
			while (bleTab[findFirstEmpty] != null) begin
				findFirstEmpty = findFirstEmpty + 1;
			end
			// On check pour voir si on a reçu un nouveau paquet du sequencer
			if(sequencer_to_scoreboard_fifo.try_get(bleTab[findFirstEmpty])) begin
				// On dit au watchdog que ça bouge tjrs
				wd_sb_itf.isRunning = 1;

				// Si le préambule est le bon, on continue
				if (bleTab[findFirstEmpty].preamble == `PREAMBLE) begin
					// Si ce n'est pas un advertising, on regarde si on a reçu un advertising correspondant avant
					if (bleTab[findFirstEmpty].isAdv == 0) begin
						advFound = 0;
						// Passage au travers de tout le tableau d'adresses
						for(int i = 0; i < `NB_MAX_ADDRESS; i++) begin
							// Si on a trouvé un advertising correspondant
							if (bleTab[findFirstEmpty].addr == advTab[i]) begin
								advFound = 1;
							end
						end
						// S'il n'y a pas d'advertising correspondant, le paquet est ignoré
						if (advFound == 0) begin
							$info("The scoreboard ignored the BlePacket number %0d, no corresponding advertising sent before by the sequencer\n", bleTab[findFirstEmpty].numPaquet);
							bleTab[findFirstEmpty] = null; 	// On remet à null pour que la case puisse être prise par la suite
							nbBleIgnored++;
						end
						// S'il y a un d'advertising correspondant
						else begin
							$display("The scoreboard recieved a data BlePacket\n");
							nbBlePacketConsidered ++;
					  	end
					end
					// Sinon si c'est un advertising on l'ajoute simplement
					else begin
						nbBlePacketConsidered ++;	// Incrémentation du nombre d'advertizing considérés
						$display("The scoreboard recieved an advertising BlePacket\n");
						advTab[advBleTabPos] = bleTab[findFirstEmpty].getDeviceAdd();	// On place l'adresse advertisée dans le tableau
						advBleTabPos = (advBleTabPos + 1) % `NB_MAX_ADDRESS;			// Incrémentation de la position de la prochaine adresse
					end
					//$display("valid = %d at findFirstEmpty %d", tab_packet[findFirstEmpty].valid, findFirstEmpty);
				end
				// Le préambule n'est pas valide
				else begin
					$info("The scoreboard ignored the BlePacket number %0d beacause of a bad preamble\n", bleTab[findFirstEmpty].numPaquet);
					nbBadPreamble++;
				end
			end
			//$display("valid = %d", tab_packet[findFirstEmpty].valid);


			// ------------ Traitement des paquets USB ------------ //
			// On check pour voir si on a reçu un nouveau packet usb du monitor
			if(monitor_to_scoreboard_fifo.try_get(usb_packet)) begin
				// On dit au watchdog que ça bouge tjrs
				wd_sb_itf.isRunning = 1;

				nbUsbPacketReceived ++;				// Incrémentation du nombre de paquets USB reçue

				//usb_packet.getFields();			// Fait dans le driver

				findInBleTab = 0;
				paquetFound = 0;
				compNumb = 0;

				// Si c'est pas un advertising, on regarde dans un premier temps si l'adresse est advertisée dans le scoreboard
				if (usb_packet.isAdv == 0) begin
					advFound = 0;
					// Passage au travers de tout le tableau d'adresses
					for(int i = 0; i < `NB_MAX_ADDRESS; i++) begin
						// Si on a trouvé un advertising correspondant
						if (usb_packet.address == advTab[i]) begin
							advFound = 1;
						end
					end
					// S'il y a un d'advertising correspondant, c'est un paquet USB sans advertising
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

					// Tant qu'une correspondance avec un paquet n'a pas été trouvée et que tous les paquets n'ont pas été comparés
					while(paquetFound == 0 && findInBleTab < `NB_MAX_BLE_PAQUET) begin
						// S'il y a un paquet Ble à cet emplacement
						if (bleTab[findInBleTab] != null) begin
							paquetFound = comparePackets(usb_packet, bleTab[findInBleTab], compNumb);	// test si le paquet correspond
							compNumb = compNumb + 1;			// Incérementation du nombre de comparaison (debug)
						end
						//$display("The scoreboard compare two packets\n");
						//$display("The scoreboard compare a %s", usb_packet.psprint());
						//$display("The scoreboard compare a %s", bleTab[findInBleTab].psprint());
						// Si un paquet a été trouvé
						if (paquetFound == 1) begin
							bleTab[findInBleTab] = null;  // On supprime le paquet Ble du tableau
							$info("The scoresboard found a corresponding BlePacket to the UsbPacket \n");
						end
						findInBleTab++;		// Incrémentation de la postion du paquet à comparer
					end
				end
				// S'il n'y pas de paquet qui a été trouvé mais qu'il y a eu un advertising avant
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
	// Appellé par le watchdog pour arreter la tâche run()
	task watchdogDisable;
		$display("The watchdog stopped the scoreboard");
		disable run;
	endtask : watchdogDisable;

endclass : Scoreboard

`endif // SCOREBOARD_SV
