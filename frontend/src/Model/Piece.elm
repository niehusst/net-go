module Model.Piece exposing (Piece(..), intToPiece, pieceToInt, pieceDecoder)

import Json.Decode as Decode exposing (Decoder, int)
import Json.Encode as Encode

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

-- JSON

pieceDecoder : Decoder Piece
pieceDecoder =
    int
        |> Decode.andThen
           (\number ->
                let
                    positiveNum = number + 1
                in
                case positiveNum of
                    0 ->
                        Decode.succeed WhiteStone
                    1 ->
                        Decode.succeed None
                    2 ->
                        Decode.succeed BlackStone
                    _ ->
                        Decode.fail ("Piece number " ++ (String.fromInt number) ++ " is invalid")
           )
