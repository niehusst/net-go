module Model.Piece exposing (Piece(..), intToPiece, pieceToInt)


type Piece
    = BlackStone
    | WhiteStone
    | None


{-| Convert a piece to an int, following the typical
numerical representation of pieces on Go boards.
-}
pieceToInt : Piece -> Int
pieceToInt piece =
    case piece of
        BlackStone ->
            1

        WhiteStone ->
            -1

        None ->
            0


intToPiece : Int -> Maybe Piece
intToPiece value =
    -- have to use if/else because negative constants cant be used in switch cases
    if value == 1 then
        Just BlackStone

    else if value == -1 then
        Just WhiteStone

    else if value == 0 then
        Just None

    else
        Nothing
