package types

import (
	"errors"
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
