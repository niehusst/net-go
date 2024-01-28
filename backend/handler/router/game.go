package router

import (
	"github.com/gin-gonic/gin"
	"log"
	"net-go/server/backend/apperrors"
	"net-go/server/backend/handler/binding"
	"net-go/server/backend/model"
	"net-go/server/backend/model/types"
	"net/http"
	"strconv"
)

type gameUri struct {
	ID uint `uri:"id" binding:"required"`
}

func parseUriParams(c *gin.Context) (*gameUri, error) {
	// bind uri params
	var uriParams gameUri
	if err := c.ShouldBindUri(&uriParams); err != nil {
		log.Printf("Failed to parse game URI params: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": apperrors.NewBadRequest("Invalid URI parameter for game ID"),
		})
		return nil, err
	}
	return &uriParams, nil
}

// GET /:id
func (handler RouteHandler) GetGame(c *gin.Context) {
	uriParams, err := parseUriParams(c)
	if err != nil {
		// JSON resp handled in helper func failure
		return
	}

	game, err := handler.p.GameService.Get(c, uriParams.ID)
	if err != nil {
		log.Printf("Error fetching game with id %u: %v\n", uriParams.ID, err)
		c.JSON(http.StatusNotFound, gin.H{
			"error": apperrors.NewNotFound("Game", strconv.FormatUint(uint64(uriParams.ID), 10)),
		})
	}

	// return game in shape elm expects
	var respGame ElmGame
	respGame.fromGame(game, user)
	c.JSON(http.StatusOK, gin.H{
		"game": respGame,
	})
}

// this follows the Game record shape in Elm frontend
type ElmGame struct {
	BoardSize     types.BoardSize
	Board         [][]types.Piece
	LastMoveWhite *types.Move
	LastMoveBlack *types.Move
	History       []types.Move
	IsOver        bool
	Score         types.Score
	PlayerColor   types.ColorChoice
}

/**
 * Creates a Game model from an Elm Game record. Does not take
 * db state into account, so only use this when there is no existing Game.
 *
 * authedUser - currently authed User who is causing the action
 */
func (r ElmGame) toGame(authedUser *model.User) model.Game {
	game := model.Game{
		Board: types.Board{
			Size: r.BoardSize,
			Map:  r.Board,
		},
		LastMoveWhite: r.LastMoveWhite,
		LastMoveBlack: r.LastMoveBlack,
		History:       r.History,
		IsOver:        r.IsOver,
		Score:         r.Score,
	}

	if r.PlayerColor == types.Black {
		game.BlackPlayer = *authedUser
	} else {
		game.WhitePlayer = *authedUser
	}

	return game
}

// populates fiels of receiver using the provided Game
func (r *ElmGame) fromGame(g model.Game, authedUser model.User) {
	r.BoardSize = g.Board.Size
	r.Board = g.Board.Map
	r.LastMoveWhite = g.LastMoveWhite
	r.LastMoveBlack = g.LastMoveBlack
	r.History = g.History
	r.IsOver = g.IsOver
	r.Score = g.Score
	if g.WhitePlayer.ID == authedUser.ID {
		r.PlayerColor = types.White
	} else {
		r.PlayerColor = types.Black
	}
}

// POST /
func (handler RouteHandler) CreateGame(c *gin.Context) {
	var req ElmGame
	if ok := binding.BindData(c, &req); !ok {
		return
	}

	// transform input into game model
	game := req.toGame(user)

	if err := handler.p.GameService.Create(c, &game); err != nil {
		c.JSON(apperrors.Status(err), gin.H{
			"error": err,
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"uid": game.ID,
	})
}
