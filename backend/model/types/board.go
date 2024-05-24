package types

import (
	"errors"
)

type Board struct {
	Size BoardSize
	Map  [][]Piece
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
