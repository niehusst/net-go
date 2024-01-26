package services

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type IMigratable interface {
	// utility method for Repository types db setup/migration
	MigrateAll() error
}

type BaseRepository struct {
	Db *gorm.DB
}

type BaseRepoDeps struct {
	// auth/location string for connecting to db
	DbString string
	Config   *gorm.Config
}

func OpenDbConnection(dbConnectionString string, config *gorm.Config) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(dbConnectionString), config)
	if err != nil {
		panic("Failed to connect to database!")
	}
	return db
}
