module Model.Game exposing (..)

import Model.Board as Board exposing (Board, BoardSize, emptyBoard, setPieceAt)
import Model.Move as Move exposing (Move(..))


type alias Game =
    { boardSize : BoardSize
    , board : Board
    , lastMove : Maybe Move
    , history : List Move
    }


newGame : BoardSize -> Game
newGame size =
    { boardSize = size
    , board = emptyBoard size
    , lastMove = Nothing
    , history = []
    }


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


playMove : Move -> Game -> Game
playMove move game =
    case move of
        Pass ->
            setLastMove move (addMoveToHistory move game)

        Play piece position ->
            setLastMove move (addMoveToHistory move (setBoard (setPieceAt position piece game.board) game))
