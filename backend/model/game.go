package model

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"gorm.io/gorm"
	"net-go/server/backend/model/types"
)

// / custom type for JSON encoding array of structs
type MoveSlice []types.Move

func (m MoveSlice) Value() (driver.Value, error) {
	return json.Marshal(m)
}

func (m *MoveSlice) Scan(value interface{}) error {
	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to unmarshal JSON value: %v", value)
	}
	return json.Unmarshal(bytes, m)
}

// struct sub-types get unpacked under the hood into the columns of Game, using the specified embeddedPrefix
type Game struct {
	gorm.Model
	History       MoveSlice   `gorm:"type:json"`
	Board         types.Board `gorm:"embedded;embeddedPrefix:board_"`
	IsOver        bool
	Score         types.Score `gorm:"embedded;embeddedPrefix:score_"`
	BlackPlayerId uint
	WhitePlayerId uint
	BlackPlayer   User `gorm:"foreignKey:BlackPlayerId;"`
	WhitePlayer   User `gorm:"foreignKey:WhitePlayerId;"`
}
