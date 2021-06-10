hirom
header

table c3.tbl,rtl ; this is just your typical menu character encodings

!character_slot = $0201
!number_additional_players = $1D4F
!reclaimed = $C346AD

; =========================================
; =  Menu modifications for player count  =
; =========================================

org $C3235A
  dw #$2341      ; Neuter controller assignment submenu

org $C3490B
  dw $3D8F : db "Players",$00,$00,$00,$00 ; Formerly "Controller"

org $C34963
  NumPlayersSlider: dw $3DA5 : db "1 2 3 4",$00 ; Formerly "Multiple"

org $C33D06
; modeled after Draw Bat.Speed values at C3/3BB7
RedrawPlayers:
  LDA #$28                ; Palette 2
  STA $29                 ; Color: Gray
  LDY #NumPlayersSlider
  JSR $02F9               ; Draw 1-4 in gray
  LDA #$20                ; Palette 0
  STA $29                 ; Color: User's
  TDC
  LDA !number_additional_players
  PHA
  ASL A                   ; Double it
  TAX                     ; Index it
  REP #$20                ; 16-bit A
  LDA $C32379,X           ; Tilemap ptr
  STA $F7                 ; Set position
  SEP #$20                ; 8-bit A
  TDC
  PLA
  JMP $3C1D               ; Convert to text & draw

org $C33E86
PlayersHandler:
  JSR $0EA3               ; Sound: Cursor
  LDA !number_additional_players
  STA $E0                 ; Store it
  LDA $0B                 ; Semi-auto keys
  BIT #$01                ; Pushing right?
  BNE .right
.left
  JMP DecrementPlayers
.right
  JMP IncrementPlayers

org !reclaimed            ; Formerly controller assignment submenu
DecrementPlayers:
  LDA $E0
  BEQ StorePlayers_redraw ; Skip ahead if already min
  DEC $E0
  BRA StorePlayers
IncrementPlayers:
  LDA $E0
  CMP #$03
  BEQ StorePlayers_redraw ; Skip ahead if already max
  INC $E0
StorePlayers:             ; Store the tmp variable back to the config
  LDA $E0
  STA !number_additional_players
.redraw
  JMP RedrawPlayers

ReclaimedContinued:
  padbyte $FF
  pad $C348F7             ; Free up the rest of the controller menu space

org $C32379               ; The former handler for opening the assignment submenu
PlayerCountPtr:
  dw $3DA5                ; 1
  dw $3DA9                ; 2
  dw $3DAD                ; 3
  dw $3DB1                ; 4

  padbyte $FF
  pad $C32388             ; Free up whatever is left


; =========================================
; =  C3 battle joypad assignment routine  =
; =========================================
;
; Credit to Bropedio for the M mod N assignment loop

org $C3A445
DecodeBattleKeys:
  JSR BackupVars
  JSR ReadJoypads
  TDC
  LDA !character_slot
.loop
  CMP !number_additional_players
  BEQ .read_joypad                ; if player count = N, give control to joypad N
  BCC .read_joypad                ; if player count < N, give control to joypad N
  SBC !number_additional_players  ; otherwise, N = N - number of players and try again
  DEC                             ;
  BNE .loop                       ; This results in the following control schemes:
.read_joypad                      ; 1-player: 1,1,1,1
  ASL                             ; 2-player: 1,2,1,2
  TAX                             ; 3-player: 1,2,3,1
  REP #$20                        ;
  LDA $F0,X                       ; Load inputs for joypad N
  SEP #$20
  TAX
  JSR RestoreVars
  JMP DecodeBattleKeys2

; =========================================
; =  Merged input routine for field/menu  =
; =========================================

org $C3A46E      ; Decode joypads for field menu
  JSR MergeInputs

org $C3A47A      ; Decode joypads for field
  JSR MergeInputs

org $C3A4B2      ; Scrap the old "merged inputs" behaviour that was located here
  LDA $EB        ; It used to merge P1+P2 inputs together, and was read during
  STA $04        ; Blitz inputs (?), allowing P2 to screw up P1's Blitzes, and
  BRA $02        ; vice versa. This just makes $04 a copy of the current inputs.

org ReclaimedContinued
MergeInputs:
  JSR BackupVars
  JSR ReadJoypads
  REP #$20
  LDA $F0        ; Joypad 1 inputs
  ORA $F2        ; Joypad 2 inputs
  ORA $F4        ; Joypad 3 inputs
  ORA $F6        ; Joypad 4 inputs
  TAX
  SEP #$20
  JSR RestoreVars
  RTS

; =============================================
; =  Custom multitap-enabled joypad decoding  =
; =============================================

BackupVars:
  PHX
  PHA
  REP #$20
  LDX #$0006
- LDA $F0,X         ; Reserve $F0-F7 for P1-4 inputs
  STA $0250,X       ; Backup old values to $0250-$0257
  DEX
  DEX
  BNE -
  SEP #$20
  PLA
  PLX
  RTS

RestoreVars:
  PHX
  LDX #$0006
- LDY $0250,X       ; Put old $F0-F7 values back together
  STY $F0,X
  DEX
  DEX
  BNE -
  PLX
  RTS

ReadJoypads: ; Credit to Vitor Vilela for the MP5 input decoding workaround
  REP #$20
  LDA $4218         ;\
  STA $F0           ; \
  LDA $421A         ;  Read joypads 1-3
  STA $F2           ;  and store to tmp
  LDA $421E         ; /
  STA $F4           ;/
  STZ $F6           ; Cannot read joypad 4 from Auto Joypad
  SEP #$20

  STZ $4201         ; I/O port 1->0
  LDA #$01
  STA $4016         ; Latch MP5 (controller 4)
  NOP
  NOP               ; I'm not sure if this waste time is required.
  STZ $4016

  LDX #$0010        ; Loop size.
- LDA $4017         ; Read controller 4 button
  REP #$20          ; and roll to $F6 (P4 tmp).
  LSR
  ROL $F6
  SEP #$20
  DEX
  BNE -             ; Loop for next input bit
  LDA #$80
  STA $4201         ; I/O port 0->1
  RTS

DecodeBattleKeys2:  ; Relocated from above to make space for extra routine calls
  JSR $A483         ; Decode keys
  JSR $A4BD         ; Do autofire
  JSR $A4F6         ; Adjust it
  JMP $A527         ; Restore $E0+

