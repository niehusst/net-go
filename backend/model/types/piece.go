package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
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

/// JSON CODERS ///

func (p *Piece) UnmarshalJSON(data []byte) error {
	// Unmarshal the data into a temporary uint
	var piece int
	if err := json.Unmarshal(data, &piece); err != nil {
		return err
	}

	tPiece, err := IntToPiece(piece)
	if err != nil {
		return err
	}
	*p = tPiece

	return nil
}

func (p *Piece) MarshalJSON() ([]byte, error) {
	return json.Marshal(p.ToInt())
}

/// DATABASE CODERS ///

func (p Piece) Value() (driver.Value, error) {
	return p.ToInt(), nil
}

func (p *Piece) Scan(value interface{}) error {
	if value == nil {
		*p = None
		return nil
	}
	switch v := value.(type) {
	case int:
		piece, err := IntToPiece(v)
		if err != nil {
			return err
		}
		*p = piece
	default:
		return fmt.Errorf("unsupported Scan value type for Piece: %T", value)
	}
	return nil
}

func (Piece) GormDataType() string {
	return "integer"
}
