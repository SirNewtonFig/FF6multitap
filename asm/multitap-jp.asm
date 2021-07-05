hirom

table c3-jp.tbl,rtl

!character_slot = $0201
!numplayers = $1D4F
!reclaimed = $C347E2

; =========================================
; =  Menu modifications for player count  =
; =========================================

org $C323BC      ; JP
  dw #$23A1      ; Neuter controller assignment submenu

org $C33E0B
RedrawPlayers:
  LDA #$28                ; Palette 2
  STA $29                 ; Color: Gray
  LDY #NumPlayersSlider
  JSR $02F9               ; Draw 1-4 in gray
  LDA #$20                ; Palette 0
  STA $29                 ; Color: User's
  TDC
  LDA !numplayers
  PHA
  ASL A                   ; Double it
  TAX                     ; Index it
  REP #$20                ; 16-bit A
  LDA $C323EC,X           ; Tilemap ptr
  STA $F7                 ; Set position
  SEP #$20                ; 8-bit A
  TDC
  PLA
  JMP $3CF1               ; Convert to text & draw

org $C33FA6
PlayersHandler:
  JSR $0EA3               ; Sound: Cursor
  LDA !numplayers
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
  STA !numplayers
.redraw
  JMP RedrawPlayers

ReclaimedContinued:
  padbyte $FF
  pad $C34A2C             ; Free up the rest of the controller menu space

org $C323EC               ; The former handler for opening the assignment submenu
PlayerCountPtr:
  dw $3E25                ; 1
  dw $3E29                ; 2
  dw $3E2D                ; 3
  dw $3E31                ; 4

  padbyte $FF
  pad $C323FB             ; Free up whatever is left

org $C3256B               ; Swap assigned joypad for switched members
  padbyte $FF
  pad $C325AA             ; Don't need this anymore!

org $C32527               ; Switch members in Order menu > Swap battle pads
  rep 3 : NOP             ; Just skip this step, unnecessary


; =========================================
; =  C3 battle joypad assignment routine  =
; =========================================
;
; Credit to Bropedio for the M mod N assignment loop

org $C3AC70
DecodeBattleKeys:
  JSR ReadJoypads
  JSR MergeBattleInputs           ; load merged inputs onto X if nobody is active
  BNE .done                       ; if merged inputs were not loaded, A will be clear
  LDA !character_slot             ; get index of current character
  JSR GetInputsForSlot            ; load joypad for character
.done
  JMP DecodeBattleKeys2           ; finish decoding buttons

GetInputsForSlot:
- CMP !numplayers
  BEQ +                           ; if player count = N, give control to joypad N
  BCC +                           ; if player count < N, give control to joypad N
  SBC !numplayers  ; otherwise, N = N - number of players and try again
  DEC                             ;
  BNE -                           ; This results in the following control schemes:
+ ASL                             ; 1-player: 1,1,1,1; 2-player: 1,2,1,2
  TAX                             ; 3-player: 1,2,3,1; 4-player: 1,2,3,4
  REP #$20                        ; 
  LDA $0250,X                     ; Load inputs for joypad N
  TAX
  SEP #$20
  RTS

; =========================================
; =  Merged input routine for field/menu  =
; =========================================

org $C3AC99      ; Decode joypads for field menu
  JSR MergeInputs

org $C3ACA5      ; Decode joypads for field
  JSR MergeInputs

org $C3ACDD      ; Scrap the old "merged inputs" behaviour that was located here
  LDA $EB        ; It used to merge P1+P2 inputs together, and was read during
  STA $04        ; Blitz inputs (?), allowing P2 to screw up P1's Blitzes, and
  BRA $02        ; vice versa. This just makes $04 a copy of the current inputs.

org ReclaimedContinued
MergeInputs:
  JSR ReadJoypads
  LDA !numplayers  ; A = N, where N is number of players
  ASL              ; input registers are 2 bytes each
  TAX              ; index offset
  REP #$20
  LDA $00
- ORA $0250,X      ; merge inputs from each pad
  DEX
  DEX
  BPL -            ; loop until all players' inputs are read, but don't read from pads above player count
  TAX              ; store in X for decoding
  TDC
  SEP #$20
  RTS

MergeBattleInputs:
  LDA $7E7B92             ; Current menu cursor state
  CMP #$05                ; 5 = regular command menu
  BEQ .mergePartial       ; allow start button from any valid pad
  CMP #$00                ; 0 = no active turn
  BNE .activePlayer       ; read from specific joypad if neither condition true
  JSR MergeInputs         ; allow inputs from anyone between turns
  LDA #$01                ; set flag to prevent regular input loading
  BRA .done               ; exit
.mergePartial
  JSR MergeInputs         ; load merged inputs from all pads
  PHX                     ; store it
  LDA !character_slot     ; get current character
  JSR GetInputsForSlot    ; get inputs for specific joypad
  STX $0258               ; store it
  REP #$20
  PLA                     ; retrieve stored merged inputs
  AND #$1000              ; just check for start button
  ORA $0258               ; merge with current player's inputs
  TAX                     ; store in X for decoding
  TDC
  SEP #$20
  LDA #$01                ; set flag to prevent regular input loading
  BRA .done               ; exit
.activePlayer
  TDC                     ; clear accumulator = proceed to decode inputs from specific joypad
.done
  RTS


; =============================================
; =  Custom multitap-enabled joypad decoding  =
; =============================================

ReadJoypads: ; Credit to Vitor Vilela for the MP5 input decoding workaround
  REP #$20
  LDA $4218         ;\
  STA $0250         ; \
  LDA $421A         ;  Read joypads 1-3
  STA $0252         ;  and store to tmp
  LDA $421E         ; /
  STA $0254         ;/
  STZ $0256         ; Cannot read joypad 4 from Auto Joypad
  STZ $0258         ; Used elsewhere, but need cleared between uses
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
  ROL $0256
  SEP #$20
  DEX
  BNE -             ; Loop for next input bit
  LDA #$80
  STA $4201         ; I/O port 0->1
  RTS

DecodeBattleKeys2:  ; Relocated from above to make space for extra routine calls
  JSR $ACAE         ; Decode keys
  JSR $ACE8         ; Do autofire
  JSR $AD21         ; Adjust it
  JMP $AD52         ; Restore $E0+

NumPlayersSlider: dw $3E25 : db "1 2 3 4",$00
