package types

// TODO: gorm doesn't like custom type?? kill enum and just make it a raw int??
type Piece int

const (
	None       Piece = 0
	BlackStone Piece = 1
	WhiteStone Piece = -1
)
