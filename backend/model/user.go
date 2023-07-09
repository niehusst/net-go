package model

import (
	"gorm.io/gorm"
)

// backtick defines json and db key representations
type User struct {
	gorm.Model
	Username string `gorm:"uniqueIndex"`
	Password string
}
