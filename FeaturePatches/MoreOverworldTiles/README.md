# More Overworld Tiles

Fully implements Lunar Magic's "more levels and overworld events" feature. This increases the amount of translevels on the overworld
to 256 (up from 96) and the amount of overworld events to 255 (up from 128).

## Prerequisites

* Lunar Magic 3.10 and up (Earlier versions are not supported);
* Lunar Magic overworld expansion hijack (press shift + ctrl + alt + F8 while on the overworld editor);
* Lunar Magic overworld teleport hijack (set the transfer index for a pipe or star to 0x1B or higher);
* Lunar Magic overworld path hijack (set the transfer index for a red path tile to 0x0E or higher);
* Some form of SRAM expansion that provides at least 318 bytes of total SRAM (per save, excluding optional checksum);
* Some form of ASM that has reclaimed offset $7E1F49 (141 bytes).

## Required SRAM expansion

For the last two points of the prerequisites, I only "officially" support using my `MoreSram.asm` solution, which you can also find
in this repository. You're on your own when using another solution ;-)

## Notes

* This patch may change the intro stage to 0x1C5.
* You will need to reapply this patch if you later switch to Lunar Magic's `LC_LZ3` compression.
