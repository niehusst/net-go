package types

import (
	"errors"
)

type MoveType uint

const (
	Pass MoveType = iota
	PlayPiece
)

func UintToMoveType(candidate uint) (MoveType, error) {
	switch candidate {
	case uint(Pass):
		return Pass, nil
	case uint(PlayPiece):
		return PlayPiece, nil
	default:
		return 0, errors.New("invalid uint to convert to MoveType")
	}
}

func (mt MoveType) ToUint() uint {
	return uint(mt)
}

// can't use MoveType or Piece type aliases bcus gORM can't handle custom types
// in model defintions
type Move struct {
	MoveType uint
	Piece    int
	Coord    uint // 0 when MoveType is Pass
}

func (m Move) IsPass() bool {
	moveType, err := UintToMoveType(m.MoveType)
	if err != nil {
		return false
	}

	return moveType == Pass
}
