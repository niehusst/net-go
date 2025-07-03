package services

import (
	"context"
	"net-go/server/backend/instrumentation"
	"net-go/server/backend/model"

	"gorm.io/gorm/clause"
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
	BaseDeps *BaseRepoDeps
}

func NewUserRepository(deps *UserRepoDeps) IUserRepository {
	return &UserRepository{
		BaseRepository: NewBaseRepository(deps.BaseDeps),
	}
}

func (u *UserRepository) FindByID(ctx context.Context, id uint) (*model.User, error) {
	ctx, endSpan := instrumentation.StartDbTrace("UserRepository.FindByID")
	defer endSpan()
	var user model.User
	err := u.Db.WithContext(ctx).
		Preload(clause.Associations).
		First(&user, id).Error

	return &user, err
}

func (u *UserRepository) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	ctx, endSpan := instrumentation.StartDbTrace("UserRepository.FindByUsername")
	defer endSpan()
	var user model.User
	err := u.Db.WithContext(ctx).
		Preload(clause.Associations).
		First(&user, "username = ?", username).
		Error

	return &user, err
}

func (u *UserRepository) Create(ctx context.Context, user *model.User) error {
	ctx, endSpan := instrumentation.StartDbTrace("UserRepository.Create")
	defer endSpan()
	err := u.Db.WithContext(ctx).Create(user).Error
	return err
}

func (u *UserRepository) Update(ctx context.Context, user *model.User) error {
	ctx, endSpan := instrumentation.StartDbTrace("UserRepository.Update")
	defer endSpan()
	err := u.Db.WithContext(ctx).Save(user).Error
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
