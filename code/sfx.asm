; This file is for the FamiTone2 library and was generated by FamiStudio

sounds:
	dw @ntsc
	dw @ntsc
@ntsc:
	dw @sfx_ntsc_get
	dw @sfx_ntsc_get_special
	dw @sfx_ntsc_jump
	dw @sfx_ntsc_lost
	dw @sfx_ntsc_walk1
	dw @sfx_ntsc_walk2

@sfx_ntsc_get:
	db $81,$8e,$82,$00,$80,$bf,$89,$f0,$02,$81,$7e,$02,$81,$70,$02,$81
	db $6a,$02,$81,$5e,$02,$81,$54,$02,$00
@sfx_ntsc_get_special:
	db $81,$d5,$82,$00,$80,$bf,$89,$f0,$02,$81,$ab,$82,$01,$80,$ba,$01
	db $81,$bd,$82,$00,$80,$bf,$02,$81,$7c,$82,$01,$80,$ba,$01,$81,$a9
	db $82,$00,$80,$bf,$02,$81,$52,$82,$01,$80,$ba,$01,$81,$bd,$82,$00
	db $80,$bf,$02,$81,$7c,$82,$01,$80,$ba,$01,$81,$a9,$82,$00,$80,$bf
	db $02,$81,$52,$82,$01,$80,$ba,$01,$81,$9f,$82,$00,$80,$bf,$02,$81
	db $3f,$82,$01,$80,$ba,$01,$81,$a9,$82,$00,$80,$bf,$02,$81,$52,$82
	db $01,$80,$ba,$01,$81,$9f,$82,$00,$80,$bf,$02,$81,$3f,$82,$01,$80
	db $ba,$01,$81,$8e,$82,$00,$80,$bf,$02,$81,$1c,$82,$01,$80,$ba,$01
	db $81,$9f,$82,$00,$80,$bf,$02,$81,$3f,$82,$01,$80,$ba,$01,$81,$8e
	db $82,$00,$80,$bf,$02,$81,$1c,$82,$01,$80,$ba,$01,$81,$8e,$82,$00
	db $80,$bf,$02,$81,$1c,$82,$01,$80,$ba,$01,$81,$7e,$82,$00,$80,$bf
	db $02,$81,$fd,$80,$ba,$01,$81,$70,$80,$bf,$02,$81,$e1,$80,$ba,$01
	db $00
@sfx_ntsc_jump:
	db $81,$80,$82,$02,$80,$b5,$89,$f0,$01,$81,$ab,$82,$01,$80,$b6,$01
	db $81,$2d,$80,$b8,$01,$81,$ef,$82,$00,$80,$b9,$01,$81,$d5,$80,$bd
	db $01,$81,$bd,$80,$bf,$01,$81,$b3,$80,$be,$01,$81,$a9,$80,$bc,$01
	db $81,$b3,$80,$b9,$01,$80,$b7,$01,$00
@sfx_ntsc_lost:
	db $81,$b7,$82,$02,$80,$7f,$89,$f0,$01,$81,$bf,$80,$7d,$01,$81,$ec
	db $80,$7a,$01,$81,$db,$82,$03,$80,$70,$01,$81,$0a,$80,$7f,$01,$81
	db $12,$80,$7d,$01,$81,$44,$80,$7a,$01,$81,$50,$82,$04,$80,$70,$01
	db $81,$11,$82,$05,$01,$81,$85,$82,$04,$01,$81,$67,$82,$03,$80,$7f
	db $01,$81,$6f,$80,$7d,$01,$81,$a7,$80,$7a,$01,$81,$d4,$82,$04,$00
@sfx_ntsc_walk1:
	db $81,$50,$82,$01,$80,$7f,$89,$f0,$01,$81,$58,$80,$7d,$01,$81,$70
	db $80,$7a,$01,$81,$e0,$00
@sfx_ntsc_walk2:
	db $81,$1d,$82,$01,$80,$7f,$89,$f0,$01,$81,$25,$80,$7d,$01,$81,$3a
	db $80,$7a,$01,$81,$98,$00
