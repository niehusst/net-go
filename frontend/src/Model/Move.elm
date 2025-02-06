module Model.Move exposing (..)

import Json.Decode as Decode exposing (Decoder, field, int, maybe, string)
import Json.Encode as Encode
import Model.Piece exposing (Piece(..))


{-| Either a pass, or playing a piece at
a particular position
Pass includes the Piece so we can know which player passed.
-}
type Move
    = Pass Piece
    | Play Piece Int



--- JSON
{-
   Match these coders to the corresponding backend model/types/move.go data structures
-}


moveDecoder : Decoder Move
moveDecoder =
    Decode.oneOf
        [ Decode.map2 Play (field "piece" Model.Piece.pieceDecoder) int
        , Decode.map Pass (field "piece" Model.Piece.pieceDecoder)
        ]


moveEncoder : Move -> Encode.Value
moveEncoder move =
    case move of
        Pass piece ->
            Encode.object
                [ ( "moveType", Encode.int 0 )
                , ( "piece", Model.Piece.pieceEncoder piece )
                , ( "coord", Encode.int 0 )
                ]

        Play piece position ->
            Encode.object
                [ ( "moveType", Encode.int 1 )
                , ( "piece", Model.Piece.pieceEncoder piece )
                , ( "coord", Encode.int position )
                ]
