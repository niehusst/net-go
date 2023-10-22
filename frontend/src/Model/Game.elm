module Model.Game exposing (..)

import Array
import Model.Board as Board exposing (Board, BoardSize, emptyBoard, setPieceAt)
import Model.ColorChoice exposing (ColorChoice)
import Model.Piece exposing (Piece(..))
import Model.Move as Move exposing (Move(..))
import Model.Score as Score exposing (Score)


type alias Game =
    { boardSize : BoardSize
    , board : Board
    , lastMove : Maybe Move
    , history : List Move
    , playerColor : ColorChoice
    , isOver : Bool
    , score : Score
    }


newGame : BoardSize -> ColorChoice -> Float -> Game
newGame size color komi =
    { boardSize = size
    , board = emptyBoard size
    , lastMove = Nothing
    , history = []
    , playerColor = color
    , isOver = False
    , score = Score.initWithKomi komi
    }


setScore : Score -> Game -> Game
setScore score game =
    { game | score = score }


setPlayerColor : ColorChoice -> Game -> Game
setPlayerColor color game =
    { game | playerColor = color }


setBoard : Board -> Game -> Game
setBoard board game =
    { game | board = board }


setIsOver : Bool -> Game -> Game
setIsOver flag game =
    { game | isOver = flag }


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


{-| Debugging helper function for visualizing the board in tests
-}
printBoard : Game -> Game
printBoard game =
    let
        mapper p =
            case p of
                Model.Piece.None ->
                    "_"
                Model.Piece.BlackStone ->
                    "X"
                Model.Piece.WhiteStone ->
                    "O"

        kernel : Game -> Board -> Game
        kernel g board =
            if Array.isEmpty board then
                let
                    _ = Debug.log "<sep>" ""
                in
                g
            else
                let
                    len =
                        Board.boardSizeToInt game.boardSize

                    row =
                        Array.slice 0 len board

                    rest =
                        Array.slice len (Array.length board) board

                    _ = Debug.log "" (Array.map (mapper) row)
                in
                    kernel g rest
    in
    kernel game game.board
