package endpoints

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

type createGameRequest struct {
	Game ElmGame `json:"game" binding:"required"`
}

type updateGameRequest struct {
	Game ElmGame `json:"game" binding:"required"`
}

func parseGameIdUriParam(c *gin.Context) (*gameUri, error) {
	// bind uri params
	var uriParams gameUri
	if err := c.ShouldBindUri(&uriParams); err != nil {
		log.Printf("Failed to parse game URI params: %v\n", err)
		badReqErr := apperrors.NewBadRequest("Invalid URI parameter for game ID")
		c.JSON(badReqErr.Status(), gin.H{
			"error": badReqErr.Error(),
		})
		return nil, err
	}
	return &uriParams, nil
}

func getUserFromCtx(c *gin.Context) (*model.User, error) {
	untypedUser, exists := c.Get("user")
	if !exists {
		return nil, apperrors.NewUnauthorized()
	}
	user := untypedUser.(*model.User)
	return user, nil
}

// this follows the definition of Game in the Elm frontend
type ElmGame struct {
	BoardSize       types.BoardSize   `json:"boardSize" binding:"required"`
	Board           []types.Piece     `json:"board" binding:"required"`
	History         []types.Move      `json:"history" binding:"required"`
	IsOver          bool              `json:"isOver"`
	Score           types.Score       `json:"score" binding:"required"`
	PlayerColor     types.ColorChoice `json:"playerColor" binding:"required"`
	WhitePlayerName string            `json:"whitePlayerName" binding:"required"`
	BlackPlayerName string            `json:"blackPlayerName" binding:"required"`
	ID              string            `json:"id,omitempty"`
}

/**
 * Creates a Game model from an Elm Game record. Does not take
 * db state into account, so only use this when there is no existing Game.
 *
 * authedUser - currently authed User who is causing the action
 */
func (r ElmGame) toGame(authedUser *model.User) (*model.Game, error) {
	// convert 1d Elm game board Array to 2d array or gorm model
	board, err := types.BoardFromArray(r.BoardSize, r.Board)
	if err != nil {
		return nil, err
	}

	game := model.Game{
		Board:   *board,
		History: r.History,
		IsOver:  r.IsOver,
		Score:   r.Score,
	}

	if r.ID != "" {
		if parsedId, err := strconv.ParseUint(r.ID, 10, 64); err == nil {
			game.ID = uint(parsedId)
		}
	}
	if r.PlayerColor == types.Black {
		game.BlackPlayerId = authedUser.ID
		game.BlackPlayer = *authedUser
	} else {
		game.WhitePlayerId = authedUser.ID
		game.WhitePlayer = *authedUser
	}

	return &game, nil
}

/**
 * Populates fields of receiver using the provided Game and User
 */
func (r *ElmGame) fromGame(g model.Game, authedUser model.User) {
	// convert 2d board to 1d
	board := make([]types.Piece, 0)
	for _, row := range g.Board.Map {
		for _, piece := range row {
			board = append(board, piece)
		}
	}
	r.Board = board
	r.BoardSize = g.Board.Size
	r.History = g.History
	r.IsOver = g.IsOver
	r.Score = g.Score
	r.ID = strconv.FormatUint(uint64(g.ID), 10)
	r.BlackPlayerName = g.BlackPlayer.Username
	r.WhitePlayerName = g.WhitePlayer.Username
	if g.WhitePlayerId == authedUser.ID {
		r.PlayerColor = types.White
	} else {
		r.PlayerColor = types.Black
	}
}

func validateUserIsPlayerInGame(game model.Game, user model.User) bool {
	return user.ID == game.BlackPlayerId || user.ID == game.WhitePlayerId
}

// GET /:id
func (rhandler RouteHandler) GetGame(c *gin.Context) {
	// make sure we got authed user
	user, err := getUserFromCtx(c)
	if err != nil {
		log.Printf("Expected to have authed user from middleware, but found none\n")
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	uriParams, err := parseGameIdUriParam(c)
	if err != nil {
		// JSON resp handled in helper func failure
		return
	}

	game, err := rhandler.Provider.GameService.Get(c, uriParams.ID)
	if err != nil {
		log.Printf("Error fetching game with id %d: %v\n", uriParams.ID, err)
		notFoundErr := apperrors.NewNotFound("Game", strconv.FormatUint(uint64(uriParams.ID), 10))
		c.JSON(notFoundErr.Status(), gin.H{
			"error": notFoundErr.Error(),
		})
		return
	}

	// return game in shape elm expects
	var respGame ElmGame
	respGame.fromGame(*game, *user)
	c.JSON(http.StatusOK, gin.H{
		"game": respGame,
	})
}

// GET /
func (rhandler RouteHandler) ListGamesByUser(c *gin.Context) {
	// make sure we got authed user
	user, err := getUserFromCtx(c)
	if err != nil {
		log.Printf("Expected to have authed user from middleware, but found none\n")
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	games, err := rhandler.Provider.GameService.ListByUser(c, user.ID)
	if err != nil {
		log.Printf("Error fetching games for user with id %d: %v\n", user.ID, err)
		internal := apperrors.NewInternal()
		c.JSON(internal.Status(), gin.H{
			"error": internal.Error(),
		})
		return
	}

	// return games in shape elm expects
	resp := make([]ElmGame, len(games))
	for i, game := range games {
		var elmGame ElmGame
		elmGame.fromGame(game, *user)
		resp[i] = elmGame
	}

	c.JSON(http.StatusOK, gin.H{
		"games": resp,
	})
}

// POST /
func (rhandler RouteHandler) CreateGame(c *gin.Context) {
	// make sure we got authed user
	user, err := getUserFromCtx(c)
	if err != nil {
		log.Printf("Expected to have authed user from middleware, but found none\n")
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	var req createGameRequest
	if ok := binding.BindData(c, &req); !ok {
		// bind failure resp handled in BindData
		return
	}

	// transform input into game model
	game, err := req.Game.toGame(user)
	if err != nil {
		log.Printf("Failed to construct game model from request data\n")
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// fetch user info to populate game struct fk user IDs
	var opponentUsername string
	if user.Username == req.Game.BlackPlayerName && req.Game.PlayerColor == types.Black {
		game.BlackPlayerId = user.ID
		opponentUsername = req.Game.WhitePlayerName
	} else if user.Username == req.Game.WhitePlayerName && req.Game.PlayerColor == types.White {
		game.WhitePlayerId = user.ID
		opponentUsername = req.Game.BlackPlayerName
	} else {
		log.Printf("Requesting user not a member of the proposed game to create\n")
		err := apperrors.NewForbidden()
		c.JSON(err.Status(), gin.H{
			"error": err.Error(),
		})
		return
	}

	opponentUser, err := rhandler.Provider.UserService.FindByUsername(c, opponentUsername)
	if err != nil {
		log.Printf("Opponent user not found by username\n")
		err := apperrors.NewNotFound("User", opponentUsername)
		c.JSON(err.Status(), gin.H{
			"error": err.Error(),
		})
		return
	}

	if game.BlackPlayerId > 0 && game.WhitePlayerId == 0 {
		game.WhitePlayerId = opponentUser.ID
	} else {
		game.BlackPlayerId = opponentUser.ID
	}

	if err := rhandler.Provider.GameService.Create(c, game); err != nil {
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"uid": game.ID,
	})
}

// POST /:id
func (rhandler RouteHandler) UpdateGame(c *gin.Context) {
	uriParams, err := parseGameIdUriParam(c)
	if err != nil {
		// JSON resp handled in helper func failure
		return
	}

	// make sure we got authed user
	user, err := getUserFromCtx(c)
	if err != nil {
		log.Printf("Expected to have authed user from middleware, but found none\n")
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	var req updateGameRequest
	if ok := binding.BindData(c, &req); !ok {
		// bind failure resp handled in BindData
		return
	}

	// transform input into game model
	newGameValues, err := req.Game.toGame(user)
	if err != nil {
		log.Printf("Failed to construct game model from request data\n")
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// fetch current value from DB
	currentGame, err := rhandler.Provider.GameService.Get(c, uriParams.ID)
	if err != nil {
		log.Printf("Error fetching game with id %d: %v\n", uriParams.ID, err)
		notFoundErr := apperrors.NewNotFound("Game", strconv.FormatUint(uint64(uriParams.ID), 10))
		c.JSON(notFoundErr.Status(), gin.H{
			"error": notFoundErr.Error(),
		})
		return
	}

	// validate the authed user has correct ownership to update the game
	if !validateUserIsPlayerInGame(*currentGame, *user) {
		forbiddenError := apperrors.NewForbidden()
		c.JSON(forbiddenError.Status(), gin.H{
			"error": forbiddenError.Error(),
		})
		return
	}

	currentGame.UpdateLegalValues(*newGameValues)
	if err := rhandler.Provider.GameService.Update(c, currentGame); err != nil {
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// return game in shape elm expects
	var respGame ElmGame
	respGame.fromGame(*currentGame, *user)
	c.JSON(http.StatusOK, gin.H{
		"game": respGame,
	})
}

// DELETE /:id
func (rhandler RouteHandler) DeleteGame(c *gin.Context) {
	uriParams, err := parseGameIdUriParam(c)
	if err != nil {
		// JSON resp handled in helper func failure
		return
	}

	// make sure we got authed user
	user, err := getUserFromCtx(c)
	if err != nil {
		log.Printf("Expected to have authed user from middleware, but found none\n")
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// fetch current value from DB
	currentGame, err := rhandler.Provider.GameService.Get(c, uriParams.ID)
	if err != nil {
		log.Printf("Error fetching game with id %d: %v\n", uriParams.ID, err)
		notFoundErr := apperrors.NewNotFound("Game", strconv.FormatUint(uint64(uriParams.ID), 10))
		c.JSON(notFoundErr.Status(), gin.H{
			"error": notFoundErr.Error(),
		})
		return
	}

	// validate the authed user has correct ownership to update the game
	if !validateUserIsPlayerInGame(*currentGame, *user) {
		forbiddenError := apperrors.NewForbidden()
		c.JSON(forbiddenError.Status(), gin.H{
			"error": forbiddenError.Error(),
		})
		return
	}

	// TODO: might also be nice to check if game has no moves for at least 1 user before deletion
	// (so that in progress games cant be rage deleted)

	if err := rhandler.Provider.GameService.Delete(c, uriParams.ID); err != nil {
		c.JSON(apperrors.Status(err), gin.H{
			"error": err.Error(),
		})
		return
	}

	// return game in shape elm expects
	c.JSON(http.StatusNoContent, gin.H{})
}
