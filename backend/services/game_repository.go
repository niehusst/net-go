package services

import (
	"context"
	"net-go/server/backend/instrumentation"
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
	Delete(ctx context.Context, gameID uint) error
}

/* implementation */

type GameRepository struct {
	BaseRepository
}

type GameRepoDeps struct {
	BaseDeps *BaseRepoDeps
}

func NewGameRepository(deps *GameRepoDeps) IGameRepository {
	return &GameRepository{
		BaseRepository: NewBaseRepository(deps.BaseDeps),
	}
}

func (g *GameRepository) FindByID(ctx context.Context, id uint) (*model.Game, error) {
	ctx, endSpan := instrumentation.StartDbTrace("GameRepository.FindByID")
	defer endSpan()
	var game model.Game
	// Preload fills the fk references in the object
	err := g.Db.WithContext(ctx).
		Preload(clause.Associations).
		First(&game, id).
		Error
	return &game, err
}

func (g *GameRepository) ListByUserID(ctx context.Context, userId uint) ([]model.Game, error) {
	ctx, endSpan := instrumentation.StartDbTrace("GameRepository.ListByUserID")
	defer endSpan()
	var games []model.Game
	err := g.Db.WithContext(ctx).
		Preload(clause.Associations).
		Where("white_player_id = ?", userId).
		Or("black_player_id = ?", userId).
		Find(&games).Error
	return games, err
}

func (g *GameRepository) Create(ctx context.Context, game *model.Game) error {
	ctx, endSpan := instrumentation.StartDbTrace("GameRepository.Update")
	defer endSpan()
	err := g.Db.WithContext(ctx).Create(game).Error
	return err
}

func (g *GameRepository) Update(ctx context.Context, game *model.Game) error {
	ctx, endSpan := instrumentation.StartDbTrace("GameRepository.Update")
	defer endSpan()
	err := g.Db.WithContext(ctx).Save(game).Error
	return err
}

func (g *GameRepository) Delete(ctx context.Context, gameID uint) error {
	ctx, endSpan := instrumentation.StartDbTrace("GameRepository.Delete")
	defer endSpan()
	err := g.Db.WithContext(ctx).Delete(&model.Game{}, gameID).Error
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
