module Model.ColorChoice exposing (ColorChoice(..), colorInverse, colorToPiece, colorToString)

import Model.Piece exposing (Piece(..))


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
