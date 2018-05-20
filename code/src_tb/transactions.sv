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

	logic[31:0] fixed_address = 32'h12355678;
	logic[31:0] fixed_address2 = 32'h55555555;

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
    (isAdv == 1) -> size inside {[4:4]};
    (isAdv == 0) -> size inside {[0:63]};
  }

  function string psprint();
    $sformat(psprint, "BlePacket\nAdvert : %b\nAddress : %h\nSize : %d\nData : %h\n",
                                                       this.isAdv, this.addr, size, dataToSend);
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
            rawData[size*8-32+i] = fixed_address[i];
	end

	/* Cas de l'envoi d'un paquet de données */
    else if (isAdv == 0) begin
  	// Peut-être que l'adresse devra être définie d'une certaine manière
		addr = fixed_address;
    end


	/* Affectation des données à envoyer */
	for(int i=0;i<8;i++)
 		dataToSend[sizeToSend-8+i]=preamble[i];
	for(int i=0;i<32;i++)
		dataToSend[sizeToSend-8-32+i]=addr[i];
  $display("Sending packet with address %h\n",addr);
	for(int i=0;i<16;i++)
		dataToSend[sizeToSend-8-32-16+i]=0; // reseting the header
	for(int i=0;i<6;i++)
		dataToSend[sizeToSend-8-32-16+i]=size[i];	// Puting the size
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

// A écrire, c'est pour les packets USB
class AnalyzerUsbPacket;
	// Variable modifiée au niveau du monitor
	logic[(64*8+10*8)-1:0] dataToSend;		// pas plus de 64 byte de données

	// Les champs de la variable
	logic[7:0] size;
	logic[7:0] rssi;
	logic[6:0] channel;
	logic	isAdv;
	logic[31:0] address;
	logic[15:0] header;
	logic[(64*8-1):0] data;

	function void getFields();
		for(int i = 0; i < 8; i++)
			size[i] = dataToSend[i];
		for(int i = 0; i < 8; i++)
			rssi[i] = dataToSend[8+i];
		for(int i = 0; i < 7; i++)
			channel[i] = dataToSend[17+i];
		isAdv = dataToSend[16];
		for(int i = 0; i < 32; i++)
			address[i] = dataToSend[32+i];
		for(int i = 0; i < 16; i++)
			header[i] = dataToSend[64+i];
		data = 0;	// Pour éffacer où on va pas écrire
		for(int i = 0; i < (size-10)*8; i++)
			data[i] = dataToSend[80+i];

	endfunction

	function string psprint();
		$sformat(psprint, "USB Packet \nSize : %d\nRssi : %d\nChannel : %d\nAdvert : %b\nAddress : %h\nHeader : %h\nData : %h\n",
							size, rssi, channel, isAdv, address, header, data);
	endfunction : psprint
endclass : AnalyzerUsbPacket

/// VKR exp: pour déclarer une fifo contenant des paquets Ble
typedef mailbox #(BlePacket) ble_fifo_t;
/// VKR exp: pour déclarer une fifo contenant des paquets Usb
typedef mailbox #(AnalyzerUsbPacket) usb_fifo_t;

`endif // TRANSACTIONS_SV
