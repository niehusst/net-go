package model

import (
	"gorm.io/gorm"
)

type BoardSize uint

const (
	Undefined BoardSize = 0
	Full      BoardSize = 19
	// TODO: the rest
)

type Board struct {
	gorm.Model
	Size  BoardSize
	board [][]Piece
}
