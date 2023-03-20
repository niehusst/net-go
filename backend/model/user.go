package model

import (
	"github.com/google/uuid"
)

// backtick defines json and db key representations
type User struct {
	UID      uuid.UUID `db:"uid" json:"uid"`
	Username string    `db:"username" json:"username"`
	Password string    `db:"password" json:"password"`
}
