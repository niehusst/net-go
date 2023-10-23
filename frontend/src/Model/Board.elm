module Model.Board exposing (..)

import Array exposing (Array)
import Model.ColorChoice exposing (ColorChoice, colorToPiece)
import Model.Piece as Piece exposing (Piece(..), pieceToInt)


{-| Using a 1d array here instead of the
more intuitive 2d representaion for the board because
it's a lot easier to work with a 1d array and we
need it in that format more often for rendering.
-}
type alias Board =
    Array Piece


getPieceAt : Int -> Board -> Maybe Piece
getPieceAt index board =
    if index < 0 then
        {- prevent access to pieces via negative indexing
           since we rely on negative index to indicate 2d array
           out of bounds
        -}
        Nothing

    else
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


getPositionLeftFrom : Int -> BoardSize -> Int
getPositionLeftFrom index boardSize =
    let
        intSize =
            boardSizeToInt boardSize
    in
    if modBy intSize index == 0 then
        -- out of bounds
        -1

    else
        index - 1


getPositionRightFrom : Int -> BoardSize -> Int
getPositionRightFrom index boardSize =
    let
        intSize =
            boardSizeToInt boardSize
    in
    if modBy intSize (index + 1) == 0 then
        -- out of bounds
        -1

    else
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


{-| Convert an entire Board to integer representation
-}
boardToIntBoard : Board -> Array Int
boardToIntBoard board =
    Array.map pieceToInt board


{-| Get list of empty board indices.
-}
getEmptySpaces : Board -> List Int
getEmptySpaces board =
    List.foldl
        (\( index, piece ) emptySpaces ->
            case piece of
                Piece.None ->
                    index :: emptySpaces

                _ ->
                    emptySpaces
        )
        []
        (Array.toIndexedList board)

{-| Percentage of the board that has stones on it.
-}
getPercentFilled : Board -> Float
getPercentFilled board =
    let
        boardSize =
            Array.length board

        piecesOnBoard =
            Array.foldr
                (\piece runSum ->
                    case piece of
                        Piece.None ->
                            runSum
                        _ ->
                            runSum + 1
                )
                0
                board
    in
    piecesOnBoard / toFloat boardSize
