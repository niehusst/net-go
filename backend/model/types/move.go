package types

type MoveType uint

const (
	Pass      = 0
	PlayPiece = 1
)

type Move struct {
	MoveType MoveType
	Piece    Piece
	Coord    uint // 0 when MoveType is Pass
}

func (m Move) IsPass() bool {
	return m.MoveType == Pass
}
