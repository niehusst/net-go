module ScoringLogic exposing (clearDeadStones, scoreGame)

import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Score as Score exposing (Score)


{-| Given a game, return the Score for the game.
-}
scoreGame : Game.Game -> Score
scoreGame game =
    Score.initWithKomi 0.0


{-| Given a board that is ready for scoring, return a
board with the dead stones removed from it.
-}
clearDeadStones : Board.Board -> Board.Board
clearDeadStones board =
    board
