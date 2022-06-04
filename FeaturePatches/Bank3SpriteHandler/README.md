# Bank 3 Sprite Handler

Sprites that run from bank $03 are handled with an awkward if-then-else chain, which runs slow
and takes more ROM than is necessary. This patch rewrites the routine in-place to use a faster
algorithm that saves both cycles and space in ROM.

This patch requires no free space and frees 190 bytes starting at $03A19B.
