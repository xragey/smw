# More SRAM

Increases the SRAM capacity of Super Mario World to 339 bytes (up from 140) by
extending the length of the RAM array that is transferred to and from SRAM.

This patch differs from similar patches in that it retains the original game's
logic in handling saving and loading, which means it should be compatible with
all emulators and most other patches.

## Reclaimed RAM

Installing this patch reclaims $7E1F49 (141 bytes).

## Notes

This patch was tested with Lunar Magic 3.20.

Keep in mind that, with default settings, this patch frees area ($1F49-$1FD5)
but transfers area ($1EA2-$1FF5) to and from SRAM. Any other vanilla uses of
this range are not cleaned up by this patch.
