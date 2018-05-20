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
`define TAILLE_PREAMBULE			8		// bits
`define TAILLE_ADRESSE				32	// bits
`define TAILLE_ENTETE					16	// bits
`define TAILLE_DEVICE_ADDR		32	// bits
`define TAILLE_MAX_DATA				512	// bits

`define PREAMBULE							8'b01010101
`define ADDRESS_ADVERTISING		32'h12345678

`define NB_MAX_ADRESSE				16
