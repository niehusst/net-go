package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
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

// / JSON CODERS ///
func (mt *MoveType) UnmarshalJSON(data []byte) error {
	// Unmarshal the data into a temporary uint
	var move uint
	if err := json.Unmarshal(data, &move); err != nil {
		return err
	}

	moveType, err := UintToMoveType(move)
	if err != nil {
		return err
	}
	*mt = moveType

	return nil
}

func (mt *MoveType) MarshalJSON() ([]byte, error) {
	return json.Marshal(mt.ToUint())
}

/// DATABASE CODERS ///

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

func (MoveType) GormDataType() string {
	return "integer"
}

type Move struct {
	MoveType MoveType `json:"moveType"`
	Piece    Piece    `json:"piece"`
	Coord    uint     `json:"coord"` // 0 when MoveType is Pass
}

func (m Move) IsPass() bool {
	return m.MoveType == Pass
}

/// DATABASE CODERS ///

func (m Move) Value() (driver.Value, error) {
	return json.Marshal(m)
}

func (m *Move) Scan(value interface{}) error {
	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to unmarshal JSON value: %v", value)
	}
	return json.Unmarshal(bytes, m)
}

func (Move) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	switch db.Dialector.Name() {
	case "mysql", "sqlite":
		return "JSON"
	case "postgres":
		return "JSONB"
	}
	// fallback hope it's json
	return "JSON"
}
