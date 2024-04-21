module Model.Move exposing (..)

import Model.Piece exposing (Piece(..))
import Json.Decode as Decode exposing (Decoder, int, string, maybe, field)
import Json.Encode as Encode

{-| Either a pass, or playing a piece at
a particular position
Pass includes the Piece so we can know which player passed.
-}
type Move
    = Pass Piece
    | Play Piece Int


--- JSON

moveDecoder : Decoder Move
moveDecoder =
    field "coord" (maybe int)
        |> Decode.andThen
           (\maybeCoord ->
                case maybeCoord of
                    Just _ ->
                        Decode.map2 Play (field "piece" Model.Piece.pieceDecoder) coordDecoder
                    Nothing ->
                        -- TODO: unfuck
                        Decode.succeed (Pass Model.Piece.WhiteStone)
           )

coordDecoder : Decoder Int
coordDecoder =
    -- TODO: use real 2D->1D conversion (requires board size)
    -- or maybe change go backend to match frontend format...
    Decode.map2 (*) (field "x" int) (field "y" int)
