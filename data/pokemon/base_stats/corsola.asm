	db 0 ; species ID placeholder
	
	db  55,  55,  85,  35,  65,  85
	evs  0,   0,   1,   0,   1,   0
	;   hp  atk  def  spd  sat  sdf
	
	db WATER, ROCK ; type
	db 60 ; catch rate
	db 113 ; base exp
	db NO_ITEM, NO_ITEM ; items
	db GENDER_F75 ; gender ratio
	db 20 ; step cycles to hatch
	INCBIN "gfx/pokemon/corsola/front.dimensions"
	db GROWTH_FAST ; growth rate
	dn EGG_WATER_1, EGG_WATER_3 ; egg groups
	
	; tm/hm learnset
	tmhm HEADBUTT, CURSE, ROLLOUT, TOXIC, ROCK_SMASH, HIDDEN_POWER, SUNNY_DAY, ICE_BEAM, PROTECT, RAIN_DANCE, ENDURE, FRUSTRATION, EARTHQUAKE, RETURN, PSYCHIC_M, MUD_SLAP, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, SANDSTORM, TELEPORT, REST, ATTRACT, SURF, STRENGTH, WHIRLPOOL, HYDRO_PUMP
	; end
