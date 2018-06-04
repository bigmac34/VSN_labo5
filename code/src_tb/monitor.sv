/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: monitor.sv
-- Authors	: Jérémie Macchi
--	   		  Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Moniteur de la structure de test envoit au scoreboard et "reçoit" de l'interface de sortie
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef MONITOR_SV
`define MONITOR_SV

`include "constant.sv"

class Monitor;

	int bytePos;
	int nbUsbPacketSent = 0;

	logic watchdogBite = 0;

	///< VKR exp: les interfaces sont en virtual pour que tous les objets puissent y accéder (voir comme un bus)
	virtual usb_itf vif;

	///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
	usb_fifo_t monitor_to_scoreboard_fifo;

	/*---------------
	-- printStatus --
	---------------*/
	// Fonction eventuellement appellée par le watchdog (seulement si la task ne se termine pas)
	function void printStatus();
		$info("The monitor catch %0d UsbPackets\n", nbUsbPacketSent);
	endfunction

	/*-------
	-- run --
	-------*/
	// Tâche lancée dans l'environment
    task run();	// Pas forcéement besoin du watchdog (c'est le scoreboard qui arrête)

		automatic AnalyzerUsbPacket usb_packet;
		$display("Monitor : start");

		while (1) begin
			usb_packet = new;			// Nouveau paquet USB
			bytePos = 0;				// Position du byte à envoyé initialisé à 0
			@(posedge vif.frame_o);		// Attend un flanc montant du frame_o

			// Tant que la transmission n'est pas finie
			while (vif.frame_o == 1) begin
				@(negedge vif.clk_i);	// Attend un flanc descendant du clk
				// Si les data peuvent être envoyés
				if (vif.valid_o == 1) begin
					// Receptionne un byte de donnée et le met dans le paquet USB
					for (int y = 0; y < `OCTET; y++)
						usb_packet.dataToSend[bytePos*`OCTET+y] = vif.data_o[y];
					bytePos ++;			// Incrémentation de la prochaine postion du byte à envoyer
				end
			end
			usb_packet.getFields();						// Set les champs du paquet USB
			monitor_to_scoreboard_fifo.put(usb_packet);	// Envoi du paquet USB au scoreboard
			//$display("The monitor sent a %s", usb_packet.psprint());
			$display("The monitor sent an usbpacket\n");
			nbUsbPacketSent ++;							// Incrémentation du numéro de paquet SUB
		end
    $display("Monitor : end");
    endtask : run

	/*-------------------
	-- watchdogDisable --
	-------------------*/
	// Appellé par le watchdog pour arreter
 	task watchdogDisable;
		$display("The watchdog stopped the monitor");
		disable run;
	endtask : watchdogDisable;

endclass : Monitor

`endif // MONITOR_SV
