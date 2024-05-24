package types

import (
	"errors"
)

type Board struct {
	Size uint
	Map  [][]int
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
	newBoard := make([][]int, rows)

	for i := 0; i < rows; i++ {
		start := i * intSize
		end := start + intSize
		// convert []Piece to []int
		boardRow := make([]int, intSize)
		for i, piece := range board1d[start:end] {
			boardRow[i] = piece.ToInt()
		}
		newBoard[i] = boardRow
	}

	return &Board{
		Size: size.ToUint(),
		Map:  newBoard,
	}, nil
}
