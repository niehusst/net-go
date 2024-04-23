package model

import (
	"gorm.io/gorm"
)

// backtick contains meta info about how model data should be stored in db
type User struct {
	gorm.Model
	Username     string `gorm:"uniqueIndex"`
	Password     string // hashed password
	SessionToken string
	Games        []Game `gorm:"foreignKey:ID;"`
}
