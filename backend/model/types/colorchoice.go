package types

import (
	"database/sql/driver"
	"errors"
	"fmt"
)

type ColorChoice string

const (
	White ColorChoice = "white"
	Black ColorChoice = "black"
)

func (c ColorChoice) ToString() string {
	return string(c)
}

func StringToColorChoice(candidate string) (ColorChoice, error) {
	switch candidate {
	case White.ToString():
		return White, nil
	case Black.ToString():
		return Black, nil
	default:
		return "", errors.New("invalid string to convert to ColorChoice")
	}
}

func (c ColorChoice) Value() (driver.Value, error) {
	return c.ToString(), nil
}

func (c *ColorChoice) Scan(value interface{}) error {
	if value == nil {
		return errors.New("cannot Scan ColorChoice from nil")
	}
	switch v := value.(type) {
	case string:
		color, err := StringToColorChoice(v)
		if err != nil {
			return err
		}
		*c = color
	default:
		return fmt.Errorf("unsupported Scan value type for ColorChoice: %T", value)
	}
	return nil
}

func (ColorChoice) GormDataType() string {
	return "varchar"
}
