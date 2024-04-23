package model

import (
	"gorm.io/gorm"
	"net-go/server/backend/model/types"
)

type Game struct {
	gorm.Model
	Board         types.Board  `gorm:"embedded;embeddedPrefix:board_"`
	LastMoveWhite *types.Move  `gorm:"embedded;embeddedPrefix:lmw_"`
	LastMoveBlack *types.Move  `gorm:"embedded;embeddedPrefix:lmb_"`
	History       []types.Move `gorm:"embedded;embeddedPrefix:history_"`
	IsOver        bool
	Score         types.Score `gorm:"embedded;embeddedPrefix:score_"`
	BlackPlayer   User        `gorm:"foreignKey:ID;"`
	WhitePlayer   User        `gorm:"foreignKey:ID;"`
}
