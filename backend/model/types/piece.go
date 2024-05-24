package types

import (
	"errors"
)

type Piece int

const (
	None       Piece = 0
	BlackStone Piece = 1
	WhiteStone Piece = -1
)

func IntToPiece(candidate int) (Piece, error) {
	switch candidate {
	case int(None):
		return None, nil
	case int(BlackStone):
		return BlackStone, nil
	case int(WhiteStone):
		return WhiteStone, nil
	default:
		return 0, errors.New("invalid int to convert to Piece")
	}
}

func (p Piece) ToInt() int {
	return int(p)
}
