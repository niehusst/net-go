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
	Score         types.Score
	BlackPlayer   User `gorm:"foreignKey:ID;"`
	WhitePlayer   User `gorm:"foreignKey:ID;"`
}
