/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: sequencer.sv
-- Authors	: Jérémie Macchi
--			  Vivien Kaltenrieder
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
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
--------------------------------------------------------------------------------
-- TESTCASE:
-- 		0: Fonctionnement classique, tout les advertising puis tout les data
--			1: Envoie de paquets de données avec une taille minimale
--			2: Envoie de paquets de données avec une taille maximale
--			3: Envoie de paquets de données sans paquet d'avertising avant
--			4: Envoie de paquets dont le préambule est incorrect
--		5: Envoie de paquets sur plus de 16 addresse
--		6: Envoie d'un advertising puis d'une data, ainsi de suite
------------------------------------------------------------------------------*/
`ifndef SEQUENCER_SV
`define SEQUENCER_SV

`include "constant.sv"

class Sequencer;
	// Pas besoin de setter la valeur, elles viennet de l'environment
	int testcase;
	virtual ble_itf vif;

	int nbPaquetSend = 0;	// Initialisation du nombre de paquet envoyé à 0

	// Pas besoin d'instancier les fifos, elles viennent de l'environment
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;

	/*---------------
	-- printStatus --
	----------------*/
	// Fonction eventuellement appellée par le watchdog (seulement si la task ne se termine pas)
	function void printStatus();
		$info("The sequencer send %0d BlePackets \n", nbPaquetSend);
	endfunction

	/*-----------------
	-- sendBlePacket --
	-----------------*/
	// Envoi d'un paquet BLE aux FIFOs
	task sendBlePacket(int testcase, logic isAdv, logic[`TAILLE_ADRESSE-1:0] addr,int numPaquet);

		automatic BlePacket packet, packet2;

		// Initialisation du packet
		packet = new;					// Il ne faut pas réutiliser celui qui est dans la mailbox
		packet.testcase = testcase;
		packet.isAdv = isAdv;
		packet.addr = addr;
		packet.numPaquet = numPaquet;

		void'(packet.randomize());		// Randomisation du paquet
		packet2 = packet.copy();		// Copy profonde du paquet

		// Envoi dans les deux FIFOs
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

	/*-------
	-- run --
	-------*/
	// Tâche lancée dans l'environment
	task run;
		// Valeurs utilisée pour définir combien de packets vont être envoyé
		int nbPacket = 10;
		int nbAdvertising = 0;
		int nbData = 9;

		$display("Sequencer : start");

		// Sequence d'envoie classique: advertising puis data
		if(testcase < 5) begin

			// Pas d'envoie de paquets d'advertising
			if(testcase == 3) begin
				nbAdvertising = 0;
			end
			// Nombres d'advertising inférieur à 16
			else begin
				nbAdvertising = 1;
			end

			// Envoie des Advertising
			for(int i=0;i<nbAdvertising;i++) begin
				sendBlePacket(testcase, 1, `ADDRESS_TEST, nbPaquetSend); // Envoie du paquet
				nbPaquetSend++;
			end

			// Envoie de packets de données random encore 9 fois (10 au total)
	        for(int i=0;i<nbData;i++) begin
				sendBlePacket(testcase, 0, `ADDRESS_TEST, nbPaquetSend); // Envoie du paquet
				nbPaquetSend++;
			end
		end

		// Envoie sur plus de 16 advertising
		else if(testcase == 5) begin
			logic[`TAILLE_ADRESSE-1:0] address[`NB_MAX_ADRESSE + 3];
			// Envoie des Advertising (plus que le maximum que peut enregistrer le DUT)
			for(int i=0;i<`NB_MAX_ADRESSE+3;i++) begin
				address[i] = $random;									// Adresse aléatoire
				sendBlePacket(testcase, 1, address[i], nbPaquetSend);	// Envoie du paquet
				nbPaquetSend++;
			end

			// Pour attendre que les advertising soient traité par le DUT avant d'envoyer les data
			//#((`TAILLE_PREAMBULE+`TAILLE_ADRESSE+`TAILLE_ENTETE+`TAILLE_MAX_DATA_ADVERTISING*`OCTET)*`NB_FREQ*10)ns; // 10 : periode
			#140us;

			// Envoie de packets de données (plus que le maximum que peut enregistrer le DUT)
			for(int i=0;i<`NB_MAX_ADRESSE+3;i++) begin
				sendBlePacket(testcase, 0, address[i], nbPaquetSend);	// Envoie du paquet
				nbPaquetSend++;											// Incrémentation du nombre de paquet envoyé
			end
		end

		// Envoie d'un advertising puis d'une data, ainsi de suite
		else if(testcase == 6) begin
			logic[`TAILLE_ADRESSE-1:0] address;
			for(int i=0;i<nbPacket;i++) begin
				address = $random;									// Adresse aléatoire
				sendBlePacket(testcase, 1, address, nbPaquetSend);	// Envoie de l'advertising
				nbPaquetSend++;										// Incrémentation du nombre de paquet envoyé
				// Pour attendre que les advertising soient traité par le DUT avant d'envoyer les data
				//#((`TAILLE_PREAMBULE+`TAILLE_ADRESSE+`TAILLE_ENTETE+`TAILLE_MAX_DATA_ADVERTISING*`OCTET)*`NB_FREQ*10)ns; // 10 : periode
				#140us;

				sendBlePacket(testcase, 0, address, nbPaquetSend); 	// Envoie du paquet de données
				nbPaquetSend++;										// Incrémentation du nombre de paquet envoyé
			end
		end

		// Si testcase est invalide
		else begin
			$error("Sequencer : testcase invalid");
		end

        $display("Sequencer : end");
    endtask : run

endclass : Sequencer

`endif // SEQUENCER_SV
