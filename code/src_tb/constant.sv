/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: constant.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 20.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Contient toutes les constantes utilisées pour le projet
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 20.05.2018		JMI							Création
------------------------------------------------------------------------------*/
`ifndef CONSTANT_SV
`define CONSTANT_SV

`define TAILLE_PREAMBULE			8		// bits
`define TAILLE_ADRESSE				32	// bits
`define TAILLE_ENTETE					16	// bits
`define TAILLE_DEVICE_ADDR		32	// bits
`define TAILLE_MAX_DATA				(63*8)	// bits
`define TAILLE_SIZE_BLE				6	// bits
`define TAILLE_RSSI						8	// bits

`define TAILLE_SIZE_USB				8	// bits
`define TAILLE_CHANNEL				7	// bits
`define TAILLE_RESERVED				8	// bits

`define OCTET									8	// bits
`define NB_OCTET_AVANT_DATA		10	// bytes

`define NB_FREQ	79

`define PREAMBULE							8'b01010101
`define FAUX_PREAMBULE				8'b00110011
`define ADDRESS_ADVERTISING		32'h12345678

`define NB_MAX_ADRESSE				16

`define NB_MAX_SIM_CAN				40

`define TAILLE_DATA_O					8	// bits

typedef logic[`TAILLE_ADRESSE-1:0] address_t;

`endif // CONSTANT_SV
