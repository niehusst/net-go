package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
)

type BoardSize uint

const (
	Undefined BoardSize = 0
	Full      BoardSize = 19
	// TODO: the rest
)

func (bs BoardSize) ToUint() uint {
	return uint(bs)
}

func UintToBoardSize(candidate uint) (BoardSize, error) {
	switch candidate {
	case Undefined.ToUint():
		return Undefined, nil
	case Full.ToUint():
		return Full, nil
	default:
		return 0, errors.New("invalid uint to convert to BoardSize")
	}
}

/// JSON CODERS ///

func (bs *BoardSize) UnmarshalJSON(data []byte) error {
	// Unmarshal the data into a temporary uint
	var size uint
	if err := json.Unmarshal(data, &size); err != nil {
		return err
	}

	boardSize, err := UintToBoardSize(size)
	if err != nil {
		return err
	}
	*bs = boardSize

	return nil
}

func (bs *BoardSize) MarshalJSON() ([]byte, error) {
	return json.Marshal(bs.ToUint())
}

/// DATABASE CODERS ///

// Implement the driver.Valuer interface
func (bs BoardSize) Value() (driver.Value, error) {
	// has to be int bcus gorm doesnt recognize uint as a sql type
	return int64(bs), nil
}

// Implement the sql.Scanner interface
func (bs *BoardSize) Scan(value interface{}) error {
	if value == nil {
		*bs = Undefined
		return nil
	}
	switch v := value.(type) {
	case uint:
		boardSize, err := UintToBoardSize(v)
		if err != nil {
			return err
		}
		*bs = boardSize
	default:
		return fmt.Errorf("unsupported Scan value type for BoardSize: %T", value)
	}
	return nil
}

func (BoardSize) GormDataType() string {
	return "integer"
}
