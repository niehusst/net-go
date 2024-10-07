package types

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
)

// / custom type to json encode since gorm doesn't like 2d array of Pieces
type PlayArea [][]Piece

func (p PlayArea) Value() (driver.Value, error) {
	return json.Marshal(p)
}

func (p *PlayArea) Scan(value interface{}) error {
	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to unmarshal JSON value: %v", value)
	}
	return json.Unmarshal(bytes, p)
}

type Board struct {
	Size BoardSize `json:"size"`
	Map  PlayArea  `json:"map" gorm:"type:json"`
}

func BoardFromArray(size BoardSize, board1d []Piece) (*Board, error) {
	intSize := int(size.ToUint())
	if intSize == 0 {
		return nil, errors.New("BoardSize must be greater than 0")
	}
	boardLen := len(board1d)
	if boardLen%intSize != 0 {
		return nil, errors.New("provided 1D board does not fit provided BoardSize")
	}

	rows := boardLen / intSize
	newBoard := make([][]Piece, rows)

	for i := 0; i < rows; i++ {
		start := i * intSize
		end := start + intSize
		newBoard[i] = board1d[start:end]
	}

	return &Board{
		Size: size,
		Map:  newBoard,
	}, nil
}
