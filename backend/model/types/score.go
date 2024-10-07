package types

type Score struct {
	ForfeitColor *ColorChoice `json:"forfeitColor"` // nil means game was not ended via forfeit
	BlackPoints  float32      `json:"blackPoints"`
	WhitePoints  float32      `json:"whitePoints"`
	Komi         float32      `json:"komi"`
}
