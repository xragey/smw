# More SRAM

Increases the SRAM capacity of Super Mario World from 140 bytes to 339 bytes by extending the RAM area that is transferred to and
from SRAM when saving or loading a game. This patch differs from other patches in that it retains the original game's logic in
handling SRAM and does not expand the physical SRAM area. This means that this solution is compatible with any emulator or hardware
solution.

## Reclaimed RAM

Installing this patch reclaims offset $7E1F49 (141 bytes), which (with default settings) is entirely located within the SRAM area.

## Notes

Note that this patch does not clean up the other uses of RAM within the new SRAM area. This results in some notable side-effects,
such as the "collected all Dragon Coins" flag now also saving to SRAM, as these flags are coincidentally stored within the new SRAM
area. Many other addresses in this area are useless to transfer to SRAM, so to take full advantage of the added SRAM, some manual
remapping of addresses is needed.
