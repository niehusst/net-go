package services

import (
	"context"
	"net-go/server/backend/model"
)

/* interface */

type IGameRepository interface {
	IMigratable
	FindByID(ctx context.Context, id uint) (*model.Game, error)
	Create(ctx context.Context, g *model.Game) error
	Update(ctx context.Context, g *model.Game) error
}

/* implementation */

type GameRepository struct {
	BaseRepository
}

type GameRepoDeps struct {
	BaseRepoDeps
}

func NewGameRepository(deps *GameRepoDeps) IGameRepository {
	db := OpenDbConnection(deps.DbString, deps.Config)

	return &GameRepository{
		BaseRepository: BaseRepository{Db: db},
	}
}

func (g *GameRepository) FindByID(ctx context.Context, id uint) (*model.Game, error) {
	var game model.Game
	err := g.Db.First(&game, id).Error
	return &game, err
}

func (g *GameRepository) Create(ctx context.Context, game *model.Game) error {
	err := g.Db.Create(game).Error
	return err
}

func (g *GameRepository) Update(ctx context.Context, game *model.Game) error {
	err := g.Db.Save(game).Error
	return err
}

/*
 * Performs necessary migrations on tables correlating to gorm models.
 * Does not delete unused columns; only creates missing columns etc.
 * https://gorm.io/docs/migration.html
 */
func (g *GameRepository) MigrateAll() error {
	err := g.Db.AutoMigrate(&model.Game{})
	return err
}