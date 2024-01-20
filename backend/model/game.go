package model

import (
	"gorm.io/gorm"
)

type Game struct {
	gorm.Model
	BoardSize     BoardSize
	Board         Board
	LastMoveWhite Move
	LastMoveBlack Move
	History       []Move
	IsOver        bool
	Score         Score
	BlackPlayerID uint
	BlackPlayer   User `gorm:"foreignKey:BlackPlayerID"`
	WhitePlayerID uint
	WhitePlayer   User `gorm:"foreignKey:WhitePlayerID"`
}
