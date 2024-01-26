package services

import (
	"context"
	"log"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/model"
	"strconv"
)

/* interfaces */

// methods the router handler layer interacts with
type IGameService interface {
	IMigratable
	Get(ctx context.Context, id uint) (*model.Game, error)
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
		log.Printf("Error fetching game: %v\n", err)
		return game, apperrors.NewNotFound("Game", strconv.FormatUint(uint64(id), 10))
	}
	return game, err
}

func (s *GameService) MigrateAll() error {
	return s.gameRepository.MigrateAll()
}
