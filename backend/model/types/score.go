package types

type Score struct {
	ForfeitColor *string // nil means game was not ended via forfeit
	BlackPoints  float32
	WhitePoints  float32
	Komi         float32
}
