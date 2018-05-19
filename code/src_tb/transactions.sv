/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: transactions.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Implémentation des class pour les transactions, packet Ble et Usb
--							 Définition des fifos (mailbox)
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef TRANSACTIONS_SV
`define TRANSACTIONS_SV

/******************************************************************************
  Input transaction
******************************************************************************/
class BlePacket;

	///< VKR exp: le 64 c'est 2 puissance 6 (6 bits pour la taille des données)
  logic[(64*8+16+32+8):0] dataToSend;
  int sizeToSend;

  /* Champs generes aleatoirement */
  logic isAdv;
  logic dataValid = 1;
	///< VKR exp: avec le rand c'est ce qui va être randomisé à l'appel de .randomize() sur la class
  rand logic[31:0] addr;
  rand logic[15:0] header;
  rand logic[(64*8):0] rawData;
  rand logic[5:0] size;
  rand logic[7:0] rssi;

  /* Contrainte sur la taille des donnees en fonction du type de paquet */
  constraint size_range {
    (isAdv == 1) -> size inside {[4:15]};
    (isAdv == 0) -> size inside {[0:63]};
  }

  function string psprint();
    $sformat(psprint, "BlePacket, isAdv : %b, addr= %h, time = %t\nsizeSend = %d, dataSend = %h\n",
                                                       this.isAdv, this.addr, $time,sizeToSend,dataToSend);
  endfunction : psprint

	///< VKR exp: fonction appellée automatiquement après la randomisation
	///< VKR exp: en l'occurence construction d'un paquet
  function void post_randomize();

	logic[7:0] preamble=8'h55;   // 01010101 fixe

	/* Initialisation des données à envoyer */
  	dataToSend = 0;
  	sizeToSend=size*8+16+32+8;

	/* Cas de l'envoi d'un paquet d'advertizing */
	if (isAdv == 1) begin
		addr = 32'h12345678;
        // DeviceAddr = 0. Pour l'exemple
        for(int i=0; i<32;i++)
            rawData[size*8-1-i] = 0;
	end

	/* Cas de l'envoi d'un paquet de données */
    else if (isAdv == 0) begin
        // Peut-être que l'adresse devra être définie d'une certaine manière
		addr = 0;
    end


	/* Affectation des données à envoyer */
	for(int i=0;i<8;i++)
 		dataToSend[sizeToSend-8+i]=preamble[i];
	for(int i=0;i<32;i++)
		dataToSend[sizeToSend-8-32+i]=addr[i];
    $display("Sending packet with address %h\n",addr);
	for(int i=0;i<16;i++)
		dataToSend[sizeToSend-8-32-16+i]=0;
	for(int i=0;i<6;i++)
		dataToSend[sizeToSend-8-32-16+i]=size[i];
	for(int i=0;i<size*8;i++)
		dataToSend[sizeToSend-8-32-16-1-i]=rawData[size*8-1-i];
    if (isAdv) begin
        logic[31:0] ad;
        for(int i=0; i < 32; i++)
            ad[i] = dataToSend[sizeToSend-8-32-16-32+i];
        $display("Advertising with address %h\n",ad);
    end
  endfunction : post_randomize

endclass : BlePacket

class AnalyzerUsbPacket;

endclass : AnalyzerUsbPacket

/// VKR exp: pour déclarer une fifo contenant des paquets Ble
typedef mailbox #(BlePacket) ble_fifo_t;
/// VKR exp: pour déclarer une fifo contenant des paquets Usb
typedef mailbox #(AnalyzerUsbPacket) usb_fifo_t;

`endif // TRANSACTIONS_SV
