/* sd2snes - SD card based universal cartridge for the SNES
   Copyright (C) 2009-2010 Maximilian Rehkopf <otakon@gmx.net>
   AVR firmware portion

   Inspired by and based on code from sd2iec, written by Ingo Korb et al.
   See sdcard.c|h, config.h.

   FAT file system access based on code by ChaN, Jim Brain, Ingo Korb,
   see ff.c|h.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License only.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

   memory.h: RAM operations
*/

#ifndef MEMORY_H
#define MEMORY_H

#define SRAM_ROM_ADDR (0x000000L)
#define SRAM_SAVE_ADDR (0x600000L)

#define SRAM_MENU_ADDR (0x600000L)
#define SRAM_DB_ADDR (0x620000L)
#define SRAM_DIR_ADDR (0x610000L)
#define SRAM_CMD_ADDR (0x7F1004L)
#define SRAM_FD_ADDR (0x7F1000L)
#define SRAM_MENU_SAVE_ADDR (0x7F0000L)
#define SRAM_SCRATCHPAD (0x7FFF00L)
#define SRAM_DIRID (0x7FFFF0L)
#define SRAM_RELIABILITY_SCORE (0x100)

	uint32_t load_rom(uint8_t* filename, uint32_t base_addr);
	uint32_t load_sram(uint8_t* filename, uint32_t base_addr);
	void sram_hexdump(uint32_t addr, uint32_t len);
	uint8_t sram_readbyte(uint32_t addr);
	uint16_t sram_readshort(uint32_t addr);
	uint32_t sram_readlong(uint32_t addr);
	void sram_writebyte(uint8_t val, uint32_t addr);
	void sram_writeshort(uint16_t val, uint32_t addr);
	void sram_writelong(uint32_t val, uint32_t addr);
	void sram_readblock(void* buf, uint32_t addr, uint16_t size);
	void sram_writeblock(void* buf, uint32_t addr, uint16_t size);
	void save_sram(uint8_t* filename, uint32_t sram_size, uint32_t base_addr);
	uint32_t calc_sram_crc(uint32_t base_addr, uint32_t size);
	uint8_t sram_reliable(void);

#include "smc.h"
	snes_romprops_t romprops;
#endif
