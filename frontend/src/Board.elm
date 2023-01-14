module Board exposing (..)

import Array exposing (Array)


{-| Using a 1d array here instead of the
more intuitive 2d representaion for the board because
it's a lot easier to work with a 1d array and we
need it in that format more often for rendering.
-}
type alias Board =
    Array Piece


getPieceAt : Int -> Int -> Board -> BoardSize -> Maybe Piece
getPieceAt row col board size =
    let
        intSize =
            boardSizeToInt size

        oneDimensionalIndex =
            row * intSize + col
    in
    Array.get oneDimensionalIndex board


setPieceAt : Int -> Int -> Piece -> Board -> BoardSize -> Board
setPieceAt row col piece board size =
    let
        intSize =
            boardSizeToInt size

        oneDimensionalIndex =
            row * intSize + col
    in
    Array.set oneDimensionalIndex piece board


type Piece
    = BlackStone
    | WhiteStone
    | None


type ColorChoice
    = White
    | Black


colorToString : ColorChoice -> String
colorToString color =
    case color of
        White ->
            "White"

        Black ->
            "Black"


type BoardSize
    = Standard
    | Medium
    | Small


boardSizeToInt : BoardSize -> Int
boardSizeToInt size =
    case size of
        Standard ->
            19

        Medium ->
            12

        Small ->
            9


emptyBoard : BoardSize -> Board
emptyBoard size =
    let
        intSize =
            boardSizeToInt size
    in
    Array.repeat (intSize * intSize) None
