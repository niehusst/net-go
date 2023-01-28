module Model.Board exposing (..)

import Array exposing (Array)
import Model.Piece as Piece exposing (ColorChoice, Piece(..), colorToPiece)


{-| Using a 1d array here instead of the
more intuitive 2d representaion for the board because
it's a lot easier to work with a 1d array and we
need it in that format more often for rendering.
-}
type alias Board =
    Array Piece


getPieceAt : Int -> Board -> Maybe Piece
getPieceAt index board =
    Array.get index board


setPieceAt : Int -> Piece -> Board -> Board
setPieceAt index piece board =
    Array.set index piece board


getPositionUpFrom : Int -> BoardSize -> Int
getPositionUpFrom index boardSize =
    let
        intSize =
            boardSizeToInt boardSize
    in
    index - intSize


getPositionDownFrom : Int -> BoardSize -> Int
getPositionDownFrom index boardSize =
    let
        intSize =
            boardSizeToInt boardSize
    in
    index + intSize


getPositionLeftFrom : Int -> Int
getPositionLeftFrom index =
    index - 1


getPositionRightFrom : Int -> Int
getPositionRightFrom index =
    index + 1


type BoardSize
    = Full
    | Medium
    | Small


boardSizeToInt : BoardSize -> Int
boardSizeToInt size =
    case size of
        Full ->
            19

        Medium ->
            12

        Small ->
            9


{-| Create a 1 dimensional version of a 2D
Goban of size `size`, with all the squares
laid out in order.
-}
emptyBoard : BoardSize -> Board
emptyBoard size =
    let
        intSize =
            boardSizeToInt size
    in
    Array.repeat (intSize * intSize) None
