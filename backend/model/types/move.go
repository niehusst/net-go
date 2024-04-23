package types

type MoveType uint

const (
	Pass      MoveType = 0
	PlayPiece MoveType = 1
)

type Move struct {
	MoveType MoveType
	Piece    Piece
	Coord    uint // 0 when MoveType is Pass
}

func (m Move) IsPass() bool {
	return m.MoveType == Pass
}
