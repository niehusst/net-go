module Model.Piece exposing (ColorChoice(..), Piece(..), colorInverse, colorToPiece, colorToString)


type Piece
    = BlackStone
    | WhiteStone
    | None


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
