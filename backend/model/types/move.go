package types

type Coord struct {
	x uint
	y uint
}

type Move struct {
	Piece *Piece // nil counts as Pass
	Coord *Coord // nil when Piece is nil
}

func (m Move) IsPass() bool {
	return m.Piece == nil
}
