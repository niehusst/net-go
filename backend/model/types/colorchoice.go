package types

import (
	"errors"
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
