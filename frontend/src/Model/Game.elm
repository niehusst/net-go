module Model.Game exposing (..)

import Model.Board as Board exposing (Board, BoardSize, emptyBoard, setPieceAt)
import Model.Move as Move exposing (Move(..))
import Model.Piece exposing (ColorChoice)


type alias Game =
    { boardSize : BoardSize
    , board : Board
    , lastMove : Maybe Move
    , history : List Move
    , playerColor : ColorChoice
    }


newGame : BoardSize -> ColorChoice -> Game
newGame size color =
    { boardSize = size
    , board = emptyBoard size
    , lastMove = Nothing
    , history = []
    , playerColor = color
    }


setPlayerColor : ColorChoice -> Game -> Game
setPlayerColor color game =
    { game | playerColor = color }


setBoard : Board -> Game -> Game
setBoard board game =
    { game | board = board }


setLastMove : Move -> Game -> Game
setLastMove move game =
    { game | lastMove = Just move }


{-| Note that because the moves are cons-ed
together, the history is the reverse order
of how the moves were actually played.
-}
addMoveToHistory : Move -> Game -> Game
addMoveToHistory move game =
    { game | history = move :: game.history }
