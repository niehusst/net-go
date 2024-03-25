module Model.Move exposing (..)

import Model.Piece exposing (Piece)


{-| Either a pass, or playing a piece at
a particular position
-}
type Move
    = Pass
    | Play Piece Int
