package services

import (
	"net-go/server/backend/instrumentation"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type IMigratable interface {
	// utility method for Repository types db setup/migration
	MigrateAll() error
}

var dbSingleton *gorm.DB

type BaseRepository struct {
	Db *gorm.DB
}

type BaseRepoDeps struct {
	// auth/location string for connecting to db
	DbString string
	Config   *gorm.Config
}

func NewBaseRepository(deps *BaseRepoDeps) BaseRepository {
	if dbSingleton == nil {
		dbSingleton = openDbConnection(deps.DbString, deps.Config)
	}
	return BaseRepository{Db: dbSingleton}
}

func openDbConnection(dbConnectionString string, config *gorm.Config) *gorm.DB {
	db, err := gorm.Open(mysql.Open(dbConnectionString), config)
	if err != nil {
		panic("Failed to connect to database!")
	}
	instrumentation.InstrumentDbConnection(db)
	return db
}
