hirom

incsrc "multitap-jp.asm"

PlayersTxt: dw $3E0F : db "Players",$00
PlayersLblPtr: dw #PlayersTxt

PrintPlayers:
  JSR $712C               ; Draw Cursor, Contr.
  LDX #PlayersLblPtr      ; Text ptr loc
  LDY #$0002              ; Strings: 1
  JSR $712C               ; Draw Players
  RTS

org $C339BB
  JSR PrintPlayers