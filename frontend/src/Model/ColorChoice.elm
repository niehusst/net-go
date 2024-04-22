module Model.ColorChoice exposing (ColorChoice(..), colorInverse, colorToPiece, colorToString, stringToColor, colorDecoder, colorEncoder)

import Model.Piece exposing (Piece(..))
import Json.Decode as Decode exposing (Decoder, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type ColorChoice
    = White
    | Black


colorToPiece : ColorChoice -> Piece
colorToPiece color =
    case color of
        White ->
            WhiteStone

        Black ->
            BlackStone


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

stringToColor : String -> Maybe ColorChoice
stringToColor string =
    case String.toLower string of
        "black" ->
            Just Black
        "white" ->
            Just White
        _ ->
            Nothing

--- JSON

colorDecoder : Decoder ColorChoice
colorDecoder =
    string
        |> Decode.andThen
            (\str ->
                case str of
                    "black" ->
                        Decode.succeed Black

                    "white" ->
                        Decode.succeed White

                    _ ->
                        Decode.fail "Invalid color"
            )

colorEncoder : ColorChoice -> Encode.Value
colorEncoder color =
    Encode.string (colorToString color)
