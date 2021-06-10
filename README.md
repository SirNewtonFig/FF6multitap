# FF6 multitap patch

by Sir Newton Fig

sirnewtonfig@gmail.com

## Contents

1) Description
2) Files
3) Technical Bits
4) Thanks

## 1) Description

This patch expands FF6's 2-player support to allow up to 4 players using a multitap, by changing the `Controller: Single/Multiple` config switch to a `Players: 1/2/3/4` slider. It also expands upon the multiplayer aspect of the game, by granting control on the field/menu modes of the game to any connected controller (think Twitch Plays, but hopefully more civilized). Sounds a little chaotic, but the idea was to make it less like players 2-4 are just sitting around waiting for battle, allowing for easy handoff of control between friends and allowing players to handle their own character building and equipment.

## 2) Files
```
  |- asm/...
  |- ips/...
```

Headered and non-headered version of the ips patches are provided, in addition to the original asm source in case you need to tweak or move anything around.

## 3) Technical Bits

This hack was built 100% within the original space of the controller assignment input handlers and menu code, so if your ROM/hack is based on FF6us and has the `Controller: Single/Multiple` option with the assignment submenu (and aren't using C3 optimized), then this hack should probably be compatible. If your hack relocates any of the original code for these things, the patch can presumably still be made to work, but you will need to find the locations of the existing data and routines in your ROM and slice this stuff in accordingly.

## 4) Thanks

Thanks to Bropedio for optimizing the M mod N assignment loop for me, and big thanks to Vitor Vilela for showing me how to read inputs for P4 from the multitap (which is apparently not straightforward at all).
