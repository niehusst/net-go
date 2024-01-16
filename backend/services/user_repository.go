package services

import (
	"context"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"net-go/server/backend/model"
)

/* interface */

// methods for interacting with the data layer
type IUserRepository interface {
	// utiltity method for db setup
	MigrateAll() error

	// db functionality abstractions
	FindByID(ctx context.Context, id uint) (*model.User, error)
	Create(ctx context.Context, u *model.User) error
	FindByUsername(ctx context.Context, username string) (*model.User, error)
	Update(ctx context.Context, user *model.User) error
}

/* implementation */

type UserRepository struct {
	db *gorm.DB
}

type UserRepoDeps struct {
	// auth/location string for connecting to db
	DbString string
	Config   *gorm.Config
}

func NewUserRepository(deps *UserRepoDeps) IUserRepository {
	db, err := gorm.Open(sqlite.Open(deps.DbString), deps.Config)
	if err != nil {
		panic("Failed to connect to database!")
	}

	return &UserRepository{
		db: db,
	}
}

func (u *UserRepository) FindByID(ctx context.Context, id uint) (*model.User, error) {
	var user model.User
	err := u.db.First(&user, id).Error

	return &user, err
}

func (u *UserRepository) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	var user model.User
	err := u.db.First(&user, "username = ?", username).Error

	return &user, err
}

func (u *UserRepository) Create(ctx context.Context, user *model.User) error {
	err := u.db.Create(user).Error
	return err
}

func (u *UserRepository) Update(ctx context.Context, user *model.User) error {
	err := u.db.Save(user).Error
	return err
}

/*
 * Performs necessary migrations on tables correlating to gorm models.
 * Does not delete unused columns; only creates missing columns etc.
 * https://gorm.io/docs/migration.html
 */
func (u *UserRepository) MigrateAll() error {
	err := u.db.AutoMigrate(&model.User{})
	return err
}
