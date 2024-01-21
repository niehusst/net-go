package model

import (
	"gorm.io/gorm"
	"net-go/server/backend/model/types"
)

type Game struct {
	gorm.Model
	Board         types.Board
	LastMoveWhite *types.Move
	LastMoveBlack *types.Move
	History       []types.Move
	IsOver        bool
	Score         Score
	BlackPlayerID uint
	BlackPlayer   User `gorm:"foreignKey:BlackPlayerID"`
	WhitePlayerID uint
	WhitePlayer   User `gorm:"foreignKey:WhitePlayerID"`
}
