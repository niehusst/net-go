package services

import (
	"context"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/logger"
	"net-go/server/backend/model"
	"strconv"
)

/* interfaces */

// methods the router handler layer interacts with
type IGameService interface {
	IMigratable
	Get(ctx context.Context, id uint) (*model.Game, error)
	ListByUser(ctx context.Context, userId uint) ([]model.Game, error)
	Delete(ctx context.Context, gameID uint) error
	Create(ctx context.Context, game *model.Game) error
	Update(ctx context.Context, game *model.Game) error
}

/* implementation */

type GameService struct {
	gameRepository IGameRepository
}

// injectable deps
type GameServiceDeps struct {
	GameRepository IGameRepository
}

func NewGameService(d GameServiceDeps) IGameService {
	return &GameService{
		gameRepository: d.GameRepository,
	}
}

// fetch by ID
func (s *GameService) Get(ctx context.Context, id uint) (*model.Game, error) {
	game, err := s.gameRepository.FindByID(ctx, id)
	if err != nil {
		return game, apperrors.NewNotFound("Game", strconv.FormatUint(uint64(id), 10))
	}
	return game, err
}

func (s *GameService) ListByUser(ctx context.Context, userId uint) ([]model.Game, error) {
	games, err := s.gameRepository.ListByUserID(ctx, userId)
	if err != nil {
		return games, apperrors.NewInternal()
	}
	return games, err
}

func (s *GameService) Create(ctx context.Context, game *model.Game) error {
	if err := s.gameRepository.Create(ctx, game); err != nil {
		logger.Error("Error creating game: %v", err)
		return apperrors.NewInternal()
	}
	return nil
}

func (s *GameService) Update(ctx context.Context, game *model.Game) error {
	if err := s.gameRepository.Update(ctx, game); err != nil {
		logger.Error("Error updating game: %v", err)
		return apperrors.NewInternal()
	}
	return nil
}

func (s *GameService) Delete(ctx context.Context, gameID uint) error {
	if err := s.gameRepository.Delete(ctx, gameID); err != nil {
		logger.Debug("Error deleting game: %v", err)
		return apperrors.NewNotFound("Game", strconv.FormatUint(uint64(gameID), 10))
	}
	return nil
}

func (s *GameService) MigrateAll() error {
	return s.gameRepository.MigrateAll()
}
