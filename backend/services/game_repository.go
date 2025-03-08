package services

import (
	"context"
	"net-go/server/backend/model"

	"gorm.io/gorm/clause"
)

/* interface */

type IGameRepository interface {
	IMigratable
	FindByID(ctx context.Context, id uint) (*model.Game, error)
	ListByUserID(ctx context.Context, userId uint) ([]model.Game, error)
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
	// Preload fills the fk references in the object
	err := g.Db.Preload(clause.Associations).First(&game, id).Error
	return &game, err
}

func (g *GameRepository) ListByUserID(ctx context.Context, userId uint) ([]model.Game, error) {
	var games []model.Game
	err := g.Db.Preload(clause.Associations).Where("white_player_id = ?", userId).Or("black_player_id = ?", userId).Find(&games).Error
	return games, err
}

func (g *GameRepository) Create(ctx context.Context, game *model.Game) error {
	// TODO: make sure player name maps correctly
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
