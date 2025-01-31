
.macro l_BNE dest
    BEQ after
    JMP dest
after:
.endm

.macro l_BEQ dest
    BNE after
    JMP dest
after:
.endm

.macro l_BCC dest
    BCS after
    JMP dest
after:
.endm

.macro l_BCS dest
    BCC after
    JMP dest
after:
.endm

.db 'NES', $1A, 2, 1, %00000011, 0, 0, 0, 0, 0, 0, 0, 0, 0

.enum $0000
oam          = $0200    ; shadow oam
drawingbuf   = $0500    ; buffer for PPU drawing

lm0:                .dsb 1
lm1:                .dsb 1
lm2:                .dsb 1
lm3:                .dsb 1
gamepad:            .dsb 1
lastframe_gamepad:  .dsb 1

soft2000:           .dsb 1
soft2001:           .dsb 1

needdma:            .dsb 1 ; nonzero if NMI should perform sprite DMA
needdraw:           .dsb 1 ; nonzero if NMI needs to do drawing from the buffer
needppureg:         .dsb 1 ; nonzero if NMI should update $2000/$2001/$2005
sleeping:           .dsb 1 ; nonzero if main thread is waiting for VBlank

main_addr:          .dsb 2
timer:              .dsb 1
player_status:      .dsb 1
special:            .dsb 1
seed:               .dsb 2
nasu_status:        .dsb 1
pnasu_status:       .dsb 1
other_flags:        .dsb 1
score:              .dsb 3
t1:                 .dsb 1
t2:                 .dsb 1
.ende

.enum $6000
hi_score:           .dsb 3
.ende

.base $8000

FAMISTUDIO_CFG_EXTERNAL       = 1
FAMISTUDIO_CFG_DPCM_SUPPORT   = 1
FAMISTUDIO_CFG_SFX_SUPPORT    = 1 
FAMISTUDIO_CFG_SFX_STREAMS    = 2
FAMISTUDIO_CFG_EQUALIZER      = 1
FAMISTUDIO_USE_VOLUME_TRACK   = 1
FAMISTUDIO_USE_PITCH_TRACK    = 1
FAMISTUDIO_USE_SLIDE_NOTES    = 1
FAMISTUDIO_USE_VIBRATO        = -1
FAMISTUDIO_USE_ARPEGGIO       = 10
FAMISTUDIO_CFG_SMOOTH_VIBRATO = 1
FAMISTUDIO_USE_RELEASE_NOTES  = 1
FAMISTUDIO_DPCM_OFF           = $e000

; ASM6-specific config.
FAMISTUDIO_ASM6_ZP_ENUM   = $00b4
FAMISTUDIO_ASM6_BSS_ENUM  = $0300

.db "NASU by KikiYama"
.db "Port by GiAnMMV "
.db "(Giammaria      "
.db "       Angeloni)"

FAMISTUDIO_ASM6_CODE_BASE:
.include famistudio_asm6.asm


reset:  
   LDX #<music_data_nasu
   LDY #>music_data_nasu
   LDA #$01 ; NTSC
   JSR famistudio_init

   LDX #<sounds
   LDY #>sounds
   JSR famistudio_sfx_init

   LDA #$00
   STA timer
   STA special
   STA player_status
   STA pnasu_status
   STA other_flags
   JSR famistudio_music_play

   LDX #$00
-  LDA palettes, X
   STA drawingbuf, X
   INX
   TXA
   CMP #$24
   BNE -
   LDA #$01
   STA needdraw

   LDX #$00
-  LDA start_oam, X
   STA oam, X
   INX
   TXA
   CMP #(4*21)
   BNE -

   LDA #$88
   STA soft2000
   STA $2000

   LDA #$00
   STA soft2001

   LDA #<map_title
   LDX #>map_title
   JSR LoadMap
   
   JSR hiscore_update

   LDA #$0A
   STA soft2001
   INC needppureg
   JSR WaitFrame

   LDA #<main_menu
   STA main_addr
   LDA #>main_menu
   STA main_addr+1

main_menu:
   LDA lastframe_gamepad
   AND #PAD_START
   BNE +
   LDA gamepad
   AND #PAD_START
   BEQ +
    JSR famistudio_music_stop
   
    LDA #<written_READY
    LDX #>written_READY
    JSR BlackScreen
    
    LDA special
    AND #%10000000
    STA special
    
    LDA #$10
    STA nasu_status
    
    LDA #$00
    STA score
    STA score+1
    STA score+2

    LDA #$50
    STA timer
    LDA #<main_menu_2
    STA main_addr
    LDA #>main_menu_2
    STA main_addr+1
    JMP (main_addr)

    LDA seed
    BNE + 
    LDA seed+1
    BNE +
     INC seed+1

+  LDX special
   CPX #$08
   BCS +
   LDA lastframe_gamepad
   AND #PAD_Arrows
   BNE +
   LDA gamepad
   AND #PAD_Arrows
   BEQ +
    LDA gamepad
    AND Sequence, X
    BEQ ++
     INC special
     CPX #$07
     BNE +
      LDA #$03
      LDX #FAMISTUDIO_SFX_CH0
      JSR famistudio_sfx_play
      
      LDA #%10000000
      STA special

      LDA #$00
      JSR LoadSprite

      INC $21C+2
      INC $220+2
      INC $224+2
      INC $228+2
    JMP +
 ++  LDX #$00
     STX special
+  JSR WaitFrameSeed
   JMP (main_addr)

main_menu_2:
   DEC timer
   BNE +
    LDA #<map_game
    LDX #>map_game
    JSR LoadMap
    LDA #<main_game_init
    STA main_addr
    LDA #>main_game_init
    STA main_addr+1
    
    LDA #$01
    JSR famistudio_music_play
    LDA #%00011110
    STA soft2001
    LDA #$01
    STA needppureg
    STA needdma
    LDA #$50
    STA timer
+  JSR WaitFrame
   JMP (main_addr)

main_game_init:
   DEC timer
   BNE main_game
    LDA #<main_game
    STA main_addr
    LDA #>main_game
    STA main_addr+1
    
    LDA written_READY
    STA drawingbuf
    LDA written_READY+1
    STA drawingbuf+1
    LDA written_READY+2
    STA drawingbuf+2
    LDA #$00
    STA drawingbuf+3
    STA drawingbuf+4
    STA drawingbuf+5
    STA drawingbuf+6
    STA drawingbuf+7
    LDA #$FF
    STA drawingbuf+8
    INC needdraw
    
    JMP main_game

main_game_bonus:
   DEC timer
   BNE main_game
    LDA #<main_game
    STA main_addr
    LDA #>main_game
    STA main_addr+1

    LDA #$FF
    STA $22C
    STA $230
    STA $234
    STA $238
    STA $23C
    STA $240
    STA $244
    STA $248
    STA $24C
    STA $250

main_game:
   JSR WaitFrame

   LDA player_status
   AND #%01100000
   BNE +
    LDA gamepad
    AND #PAD_L
    BEQ ++
     LDA player_status
     BMI +++
     JMP ++++
 ++ LDA gamepad
    AND #PAD_R
    BEQ +
     LDA player_status
     BMI ++++
 +++ LDX #$00
   -  LDA $214+2, X
      EOR #%01000000
      STA $214+2, X
      STA $214+6, X
      LDA $214+3, X
      TAY
      LDA $214+7, X
      STA $214+3, X
      TYA
      STA $214+7, X
      INX
      INX
      INX
      INX
      INX
      INX
      INX
      INX
      CPX #$18
      BNE -
      LDA player_status
      EOR #%10000000
++++ ORA #%01000000
     AND #%11000000
     STA player_status


+  LDA lastframe_gamepad
   AND #PAD_A + PAD_B
   BNE +
   LDA gamepad
   AND #PAD_A + PAD_B
   BEQ +
   LDA player_status
   AND #%00100000
   BNE +
    LDA player_status
    AND #%10000000
    CLC
    ADC #%00100000
    STA player_status
    
    LDA #$03
    JSR LoadSprite
    
    LDA #$02
    LDX #FAMISTUDIO_SFX_CH1
    JSR famistudio_sfx_play
   
+  LDA player_status
   AND #%00100000
   BEQ +
    LDA player_status
    AND #%00011111
    TAX
    LDY #$00
-   CLC
    LDA Mov_JumpY, X
    ADC $214, Y
    STA $214, Y
    INY
    INY
    INY
    INY
    CPY #$18
    BNE -
    INC player_status
    
    LDA gamepad
    AND #PAD_R
    BEQ ++
    LDA $214+4+3
    CMP #$F0
    BEQ ++
     LDX #$00
 -   INC $217, X
     INX
     INX
     INX
     INX
     CPX #$18
     BNE -

++  LDA gamepad
    AND #PAD_L
    BEQ ++
    LDA $214+3
    BEQ ++
     LDX #$00
 -   DEC $217, X
     INX
     INX
     INX
     INX
     CPX #$18
     BNE -

++  LDA player_status
    AND #%00011111
    CMP #$1A
    BNE +
     LDA player_status
     AND #%10000000
     STA player_status

     LDA #$00
     JSR LoadSprite

     LDA other_flags
     AND #%10111111
     STA other_flags

     LDA #$05
     LDX #FAMISTUDIO_SFX_CH1
     JSR famistudio_sfx_play


+   LDA player_status
    AND #%01000000
    BNE ++
    JMP +
  ++ LDA player_status
     AND #%00011111
     BNE ++
      LDA #$01
      JSR LoadSprite

      LDA #$04
      LDX #FAMISTUDIO_SFX_CH1
      JSR famistudio_sfx_play
    
  ++ LDA player_status
     AND #%00011111
     CMP #$0C
     BNE ++
      LDA #$02
      JSR LoadSprite

      LDA #$05
      LDX #FAMISTUDIO_SFX_CH1
      JSR famistudio_sfx_play

  ++ LDA player_status
     AND #%10000000
     BEQ +++
      LDA $214+4+3
      CMP #$F0
      BEQ ++++
       LDX #$00
   -   INC $214+3, X
       INX
       INX
       INX
       INX
       CPX #$18
       BNE -
 ++++ LDA gamepad
      AND #PAD_R
      BEQ +++++
     JMP ++
  +++ LDA $214+3
      BEQ ++++
       LDX #$00
   -   DEC $214+3, X
       INX
       INX
       INX
       INX
       CPX #$18
       BNE -
 ++++ LDA gamepad
      AND #PAD_L
      BNE ++

 +++++ LDA player_status
       AND #%10000000
       STA player_status
       
       LDA #$00
       JSR LoadSprite

  ++ INC player_status
     LDA player_status
     AND #%00011111
     CMP #$18
     BNE +
      LDA player_status
      AND #%11000000
      STA player_status

+  LDA player_status
   AND #%00100000
   l_BEQ +
   LDX #$00
   LDA player_status
   BPL ++
    LDX #$04
++ SEC
   LDY $214+3, X
   INY
   CPY $200+3
   l_BCS +
   INY
   INY
   INY
   INY
   INY
   INY
   INY
   CPY $200+3
   l_BCC +
   LDY $214
   DEY
   DEY
   CPY $200
   l_BCC +
   DEY
   DEY
   DEY
   DEY
   DEY
   DEY
   DEY
   CPY $200
   l_BCS +
    LDA #$FF
    STA $200
    
    JSR prng
    LDA seed
    STA $200+3
    TAX
    LDA seed+1
    STA t1
    TAY
    LDA #$00
    STA t2
    PHA
    .rept 3
    TYA
    ASL A
    TAY
    TXA
    ROL A
    TAX
    PLA
    ROL A
    PHA
    .endr
    TYA
    ADC t2
    STA t2
    TXA
    ADC t1
    STA t1
    PLA
    PHA
    ADC $200+3
    STA $200+3
    .rept 2
    TYA
    ASL A
    TAY
    TXA
    ROL A
    TAX
    PLA
    ROL A
    PHA
    .endr
    SEC
    TYA
    EOR #$FF
    ADC t2
    STA t2
    TXA
    EOR #$FF
    ADC t1
    STA t1
    PLA
    EOR #$FF
    ADC $200+3
    STA $200+3
    .rept 8
    INC $200+3
    .endr
    LDA t1
    BPL ++
     INC $200+3
    
 ++ LDA special
    BNE +++
    JSR prng
    SEC
    LDA #<($10000/50)
    SBC seed+1
    LDA #>($10000/50)
    SBC seed
    BCC ++
 +++ LDA other_flags
     ORA #%10000000
     STA other_flags
    
 ++ LDX #0
    LDA #1
    JSR score_add
    
    LDA #$40
    STA nasu_status

    LDA player_status
    AND #%10000000
    LSR
    LSR
    LSR
    LSR
    LSR
    TAX
    CLC
    LDA #$214+3, X
    ADC #$0C
    STA #$208+3
    SEC
    LDA #$214
    SBC #$0A
    STA #$208

    JSR get_nasu
    
+  LDA nasu_status
   BNE ++
    INC $200
   JMP +
 ++ CMP #$20
    BNE ++
     LDA #$FF
     STA $208
 ++ DEC nasu_status

+  LDX pnasu_status
   BEQ +++
    BMI ++++
     CLC
     LDA Mov_PinkNasuX-1, X
     ADC $207
     STA $207
     CLC
     LDA Mov_PinkNasuY-1, X
     ADC $204
     STA $204
     INC pnasu_status
     LDA pnasu_status
     CMP #$33
     BNE +++++
      LDA #$01
      STA pnasu_status
+++++
     LDA $204+3
     CMP #$FF
     l_BEQ ++++++
    JMP ++
++++ CPX #$30+%10000000
     BEQ ++++
      CPX #$60+%10000000
      BEQ +++++
       INC pnasu_status
      JMP ++
 +++++ LDA #$00
       STA pnasu_status

       LDA #$FF
       STA $20C
       STA $210
     JMP ++
 ++++ LDA #$01
      STA pnasu_status
   JMP ++
+++ LDA other_flags
    BPL ++
     EOR #%10000000
     STA other_flags
     LDA #%10000000
     STA pnasu_status

 ++ LDA player_status
    AND #%00100000
    BEQ +
    LDX #$00
    LDA player_status
    BPL ++
     LDX #$04
 ++ LDY $214+3, X
    INY
    CPY $204+3
    BCS +
    INY
    INY
    INY
    INY
    INY
    INY
    INY
    CPY $204+3
    BCC +
    LDY $214
    DEY
    DEY
    CPY $204
    BCC +
    DEY
    DEY
    DEY
    DEY
    DEY
    DEY
    DEY
    CPY $204
    BCS +
     LDX #0
     LDA #30
     JSR score_add

     LDA player_status
     AND #%10000000
     LSR
     LSR
     LSR
     LSR
     LSR
     TAX
     CLC
     LDA #$214+3, X
     ADC #$0C
     STA #$20C+3
     ADC #$08
     STA #$210+3
     SEC
     LDA #$214
     SBC #$0A
     STA #$20C
     STA #$210

     JSR get_nasu 
++++++
     LDA start_oam+4
     STA $204
     LDA start_oam+7
     STA $207

     LDA #$40+%10000000
     STA pnasu_status

+  LDA $200
   CMP #$99
   BNE +
    LDA #<main_lost_1
    STA main_addr
    LDA #>main_lost_1
    STA main_addr+1
    
    SEC
    LDA hi_score+2
    SBC score+2
    LDA hi_score+1
    SBC score+1
    LDA hi_score
    SBC score
    BCS ++
    LDA special
    BNE ++
     LDX #$00
   - TXA
     ASL
     ASL
     TAY
     LDA score
     STA hi_score, Y
     LDA score+1
     STA hi_score+1, Y
     LDA score+2
     STA hi_score+2, Y
     INX
     BNE -
    
 ++ JSR famistudio_music_stop
    LDA #$03
    LDX #FAMISTUDIO_SFX_CH0
    JSR famistudio_sfx_play
    
    LDA #$A0
    STA timer
    
    LDA #$04
    STA drawingbuf
    LDA #$3F
    STA drawingbuf+1
    LDA #$0D
    STA drawingbuf+2
    LDA #$FF
    STA drawingbuf+7
+  JMP (main_addr)

main_lost_1:
   LDA timer
+  AND #%00011111
   BNE ++
    LDA #$3F
    STA drawingbuf+3
    STA drawingbuf+4
    LDA #$16
    STA drawingbuf+5
    STA drawingbuf+6
    INC needdraw
    
    SEC
    LDA timer
    SBC #%00100000
    BNE +++
     LDA #$50
     STA timer
     LDA #<main_lost_2
     STA main_addr
     LDA #>main_lost_2
     STA main_addr+1
     JMP (main_addr)
+++ ORA #$14
    STA timer
   JMP +
++ CMP #$0A
   BNE +
    LDA palettes+3+$0D
    STA drawingbuf+3
    LDA palettes+3+$0E
    STA drawingbuf+4
    LDA palettes+3+$0F
    STA drawingbuf+5
    LDA palettes+3+$10
    STA drawingbuf+6
    INC needdraw
+  DEC timer
   JSR WaitFrame
   JMP (main_addr)
   
main_lost_2:
   DEC timer
   BNE +
    LDA #$0A
    STA soft2001
    LDA #$00
    STA needdma
    
    LDX #written_LOST_end - written_LOST
 -  DEX
    LDA written_LOST, X
    STA drawingbuf, X
    CPX #$00
    BNE -
    LDA #$01
    STA needdraw
    
    LDA #$02
    JSR famistudio_music_play
    
    LDX #$A0
    LDY #$01
    LDA #<main_lost_3
    STA main_addr
    LDA #>main_lost_3
    STA main_addr+1
+  JSR WaitFrame
   JMP (main_addr)

main_lost_3:
   DEX
   CPX #$FF
   BNE +
    DEY
    CPY #$FF
    BNE +
     BRK
+  JSR WaitFrame
   JMP (main_addr)

;;;;;;;;;;


WaitFrame:
   INC sleeping
-  LDA sleeping
   BNE -
   RTS

WaitFrameSeed:
   INC sleeping
-  INC seed
   BNE +
    INC seed+1
   
+  LDA sleeping
   BNE -
   CLD
   RTS

nmi:
   PHA
   TXA
   PHA
   TYA
   PHA

   LDA needdma
   BEQ +
    LDX #$00
    STX $2003
    LDA #>oam
    STA $4014

+  LDA needdraw
   BEQ +
    BIT $2002

    LDY #$00
 -  LDX drawingbuf, Y
    CPX #$FF
    BEQ ++
     INY
     LDA drawingbuf, Y
     STA $2006
     INY
     LDA drawingbuf, Y
     STA $2006
     INY
  -- LDA drawingbuf, Y
     STA $2007
     INY
     DEX
     BNE --
     BEQ -
 ++ DEC needdraw
    INC needppureg

+  LDA needppureg
   BEQ +
    LDA soft2001
    STA $2001
    LDA soft2000
    STA $2000
    BIT $2002
    LDA #$00
    STA $2005
    LDA #$00
    STA $2005
    STA needppureg

+  JSR famistudio_update
   JSR ReadJoy

   LDA #$00
   STA sleeping

   PLA
   TAY
   PLA
   TAX
   PLA
   RTI

LoadSprite:
   ASL
   ORA special
   ORA #$10   ; $1X
   STA $215
   ORA #$20   ; $3X
   STA $21D
   EOR #$10   ; $2X
   STA $225
   ORA #$01   ; $2Y
   STA $229
   ORA #$10   ; $3Y
   STA $221
   EOR #$20   ; $1Y
   STA $219
   RTS

LoadMap:
   STA lm0
   STX lm1

   LDX soft2001
   LDA #$00
   STA soft2001
   INC needppureg
   JSR WaitFrame
   STX soft2001

   LDA #$20
   STA $2006
   LDY #$00
   STY $2006
   STY lm2
   STY lm3
-  LDA (lm0),Y
   STA $2007
   CLC
   LDA #$01
   ADC lm0
   STA lm0
   BCC +
   INC lm1
+  INC lm2
   LDA lm2
   CMP #$00
   BNE -
   INC lm3
   LDA lm3
   CMP #$04
   BNE -
+  INC needppureg
   JSR WaitFrame
   RTS

BlackScreen:
   STA lm0
   STX lm1

   LDX soft2001
   LDA #$00
   STA soft2001
   INC needppureg
   JSR WaitFrame
   STX soft2001

   LDA #$20
   STA $2006
   LDA #$00
   STA $2006
   LDX #$79
   LDY #$03
   LDA #$01
-  STA $2007
   DEX
   CPX #$FF
   BNE -
   DEY
   CPY #$FF
   BNE -
   
   LDX #$40
   LDA #$23
   STA $2006
   LDA #$C0
   STA $2006
   LDA #$00
-  STA $2007
   DEX
   BNE -

   LDY #$00
   LDA (lm0), Y
   TAX
   INY
   LDA (lm0), Y
   STA $2006
   INY
   LDA (lm0), Y
   STA $2006
-  INY
   LDA (lm0), Y
   STA $2007
   DEX
   BNE -

   INC needppureg
   JSR WaitFrame
   RTS

ReadJoy:
   PAD_R      = %00000001
   PAD_L      = %00000010
   PAD_D      = %00000100
   PAD_U      = %00001000
   PAD_START  = %00010000
   PAD_SELECT = %00100000
   PAD_B      = %01000000
   PAD_A      = %10000000
   PAD_Arrows = %00001111

   LDA gamepad
   STA lastframe_gamepad
   LDA #$01
   STA $4016
   STA gamepad
   LSR A
   STA $4016
-  LDA $4016
   LSR A
   ROL gamepad
   BCC -
   RTS

prng:
   LDY #$08
   LDA seed
-  ASL
   ROL seed+1
   BCC +
    EOR #$39
+  DEY
   BNE -
   STA seed
   CMP #$00
   RTS

score_add: ;score + XA
   CLC
   ADC score+1
   CMP #100
   BCC +
    SBC #100
+  STA score+1
   TXA
   ADC score
   CMP #100
   BCC +
    LDA #99
    STA score+1
    STA score+2
+  STA score
   LDA #$05
   STA drawingbuf
   LDA #$23
   STA drawingbuf+1
   LDA #$7A
   STA drawingbuf+2
   LDX score
   LDA base_100, X
   LSR
   LSR
   LSR
   LSR
   ORA #$30
   STA drawingbuf+3
   LDA base_100, X
   AND #%00001111
   ORA #$30
   STA drawingbuf+4
   LDX score+1
   LDA base_100, X
   LSR
   LSR
   LSR
   LSR
   ORA #$30
   STA drawingbuf+5
   LDA base_100, X
   AND #%00001111
   ORA #$30
   STA drawingbuf+6
   LDX #$30
   LDA score+2
   BEQ +
    LDX #$39
+  STX drawingbuf+7
   LDA #$FF
   STA drawingbuf+8
   LDA #$01
   STA needdraw
   RTS
   
hiscore_update:
   LDA #$05
   STA drawingbuf
   LDA #$22
   STA drawingbuf+1
   LDA #$52
   STA drawingbuf+2
   LDX hi_score
   LDA base_100, X
   LSR
   LSR
   LSR
   LSR
   ORA #$30
   STA drawingbuf+3
   LDA base_100, X
   AND #%00001111
   ORA #$30
   STA drawingbuf+4
   LDX hi_score+1
   LDA base_100, X
   LSR
   LSR
   LSR
   LSR
   ORA #$30
   STA drawingbuf+5
   LDA base_100, X
   AND #%00001111
   ORA #$30
   STA drawingbuf+6
   LDX #$30
   LDA hi_score+2
   BEQ +
    LDX #$39
+  STX drawingbuf+7
   LDA #$FF
   STA drawingbuf+8
   LDA #$01
   STA needdraw
   RTS

get_nasu:
   LDA other_flags
   EOR #%01000000
   STA other_flags
   AND #%01000000
   BEQ ++
    LDA #$00
    LDX #FAMISTUDIO_SFX_CH0
    JSR famistudio_sfx_play
   JMP +
 ++ LDA #$01
    LDX #FAMISTUDIO_SFX_CH0
    JSR famistudio_sfx_play

    LDX #1
    LDA #0
    JSR score_add

    LDA #$6B
    STA $22C
    STA $230
    STA $234
    STA $238
    STA $23C
    LDA #$6B+8
    STA $240
    STA $244
    STA $248
    STA $24C
    STA $250

    LDA #$60
    STA timer
    LDA #<main_game_bonus
    STA main_addr
    LDA #>main_game_bonus
    STA main_addr+1
+  RTS

map_title:
.incbin map_title.bin
map_game:
.incbin map_game.bin

written_READY:
   .db @end-@beg, $21, ($20-@end+@beg+1)/2 + $A0
   @beg
    .db "READY"
   @end

written_LOST:
   @len1 = @end1 - @beg1
   .db @len1, $21, ($20-@len1+1)/2 + $A0
   @beg1
    .db "GAME OVER"
   @end1

   @len2 = 16
   .db @len2, $3F, $00
   rept @len2/4
    .db $3F, $3F, $3F, $30
   endr

   @len3 = 5
   .db @len3, $23, $74
   rept @len3
    .db $01
   endr

   .db $FF
written_LOST_end:

palettes:
.hex 20 3F 00
.hex 3F 3F 3F 30 3F 14 23 33 3F 0A 0A 30 3F 06 16 3F
.hex 3F 16 06 26 3F 04 05 14 3F 15 06 25 3F 3F 3F 30
.hex FF

start_oam:
.hex FF 18 01 84  97 18 02 FF  FF 1A 03 00  FF 1C 03 00
.hex FF 1D 03 00  97 10 00 80  97 11 00 88  94 30 00 80
.hex 94 31 00 88  8C 20 00 80  8C 21 00 88  FF 60 00 70
.hex FF 61 00 78  FF 62 00 80  FF 63 00 88  FF 64 00 90
.hex FF 70 00 70  FF 71 00 78  FF 72 00 80  FF 73 00 88
.hex FF 74 00 90

Mov_PinkNasuX:
.hex 01 00 00 00 01 00 00 00 01 00 00 00 01 00 00 00
.hex 01 00 00 00 01 00 00 00 01 00 00 00 01 00 00 00
.hex 01 00 00 00 01 00 00 00 01 00 00 00 01 00 00 00
.hex 01 00

Mov_PinkNasuY:
.hex FE 00 FE 00 FE 00 FE 00 FE 00 FF 00 FF 00 FF 00
.hex 00 00 00 00 FF 00 00 00 00 00 00 00 01 00 00 00
.hex 00 00 01 00 01 00 01 00 02 00 02 00 02 00 02 00
.hex 02 00

Mov_JumpY:
.hex FC 00 FC 00 FD 00 FE 00 00 00 FF 00 00 00 01 00
.hex 00 00 02 00 03 00 04 00 04 00

Sequence:
.db PAD_L, PAD_L, PAD_R, PAD_R, PAD_U, PAD_D, PAD_U, PAD_D

base_100:
  .hex 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19
  .hex 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39
  .hex 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59
  .hex 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79
  .hex 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99

.org $a000
songs:
  .include music.asm

  .include sfx.asm

.org $fffa

.dw nmi
.dw reset
.dw reset ;irq

.incbin graphics.chr