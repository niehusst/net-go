package types

import (
	"database/sql/driver"
	"errors"
	"fmt"
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

func (mt MoveType) Value() (driver.Value, error) {
	return mt.ToUint(), nil
}

func (mt *MoveType) Scan(value interface{}) error {
	if value == nil {
		*mt = Pass
		return nil
	}
	switch v := value.(type) {
	case uint:
		moveType, err := UintToMoveType(v)
		if err != nil {
			return err
		}
		*mt = moveType
	default:
		return fmt.Errorf("unsupported Scan value type for MoveType: %T", value)
	}
	return nil
}

type Move struct {
	MoveType MoveType
	Piece    Piece
	Coord    uint // 0 when MoveType is Pass
}

func (m Move) IsPass() bool {
	return m.MoveType == Pass
}
