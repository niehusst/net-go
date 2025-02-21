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


moveToInt : Move -> Int
moveToInt move =
    case move of
        Pass _ ->
            0

        Play _ _ ->
            1


moveDecoder : Decoder Move
moveDecoder =
    let
        moveTypeValidation moveType =
            if moveType < 0 || moveType > 1 then
                Decode.fail ("Invalid move type: " ++ String.fromInt moveType)

            else
                Decode.succeed moveType
    in
    Decode.map3
        (\moveType piece coord ->
            case moveType of
                1 ->
                    Play piece coord

                _ ->
                    -- should only be 0 from moveType validation
                    Pass piece
        )
        (field "moveType" int |> Decode.andThen moveTypeValidation)
        (field "piece" Model.Piece.pieceDecoder)
        (field "coord" int)


moveEncoder : Move -> Encode.Value
moveEncoder move =
    case move of
        Pass piece ->
            Encode.object
                [ ( "moveType", Encode.int (moveToInt move) )
                , ( "piece", Model.Piece.pieceEncoder piece )
                , ( "coord", Encode.int 0 )
                ]

        Play piece position ->
            Encode.object
                [ ( "moveType", Encode.int (moveToInt move) )
                , ( "piece", Model.Piece.pieceEncoder piece )
                , ( "coord", Encode.int position )
                ]
