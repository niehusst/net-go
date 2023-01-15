module Board exposing (..)

import Array exposing (Array)


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


type Piece
    = BlackStone
    | WhiteStone
    | None


type ColorChoice
    = White
    | Black


colorInverse : ColorChoice -> ColorChoice
colorInverse color =
    case color of
        White ->
            Black

        Black ->
            White


colorToString : ColorChoice -> String
colorToString color =
    case color of
        White ->
            "white"

        Black ->
            "black"


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
