# Item Memory

Replaces the item memory system in Super Mario World with a different system
that assigns a bit to every individual tile in a stage, rather than having the
columns of a (sub)screen share the same bit. Also implements item memory 3, and
implements an independent flag that can be used to toggle the use of item
memory. Compatible with the ExLevel system implemented by recent versions of
Lunar Magic.

This patch frees RAM offset `$7E19F8` (384 bytes), but requires you to assign a
block of 7169 bytes elsewhere in RAM. The patch uses long addressing for this,
so this block can be anywhere in the `$7Exxxx` or `$7Fxxxx` range.

ASM programmers can leverage the `ReadItemMemory` and `WriteItemMemory` routines
in this patch to have other stuff hook into and use item memory as well. Review
the source code for details.

Special thanks to GreenHammerBro <https://smwc.me/u/18802> for his documentation
on the (Ex)Level file format.

**Note:** This is a rewrite of a patch that I have been hosting here since early
2020 to improve performance and code clarity. If you need the old version,
review the git history.
