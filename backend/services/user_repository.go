package services

import (
	"context"
	"net-go/server/backend/model"
)

/* interface */

// methods for interacting with the data layer
type IUserRepository interface {
	IMigratable
	// db functionality abstractions
	FindByID(ctx context.Context, id uint) (*model.User, error)
	Create(ctx context.Context, u *model.User) error
	FindByUsername(ctx context.Context, username string) (*model.User, error)
	Update(ctx context.Context, user *model.User) error
}

/* implementation */

type UserRepository struct {
	BaseRepository
}

type UserRepoDeps struct {
	BaseRepoDeps
}

func NewUserRepository(deps *UserRepoDeps) IUserRepository {
	db := OpenDbConnection(deps.DbString, deps.Config)

	return &UserRepository{
		BaseRepository: BaseRepository{Db: db},
	}
}

func (u *UserRepository) FindByID(ctx context.Context, id uint) (*model.User, error) {
	var user model.User
	err := u.Db.First(&user, id).Error

	return &user, err
}

func (u *UserRepository) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	var user model.User
	err := u.Db.First(&user, "username = ?", username).Error

	return &user, err
}

func (u *UserRepository) Create(ctx context.Context, user *model.User) error {
	err := u.Db.Create(user).Error
	return err
}

func (u *UserRepository) Update(ctx context.Context, user *model.User) error {
	err := u.Db.Save(user).Error
	return err
}

/*
 * Performs necessary migrations on tables correlating to gorm models.
 * Does not delete unused columns; only creates missing columns etc.
 * https://gorm.io/docs/migration.html
 */
func (u *UserRepository) MigrateAll() error {
	err := u.Db.AutoMigrate(&model.User{})
	return err
}
