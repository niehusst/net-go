module Logic exposing (validMove)

import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (..)


{-| Determine whether a move on the board is legal.
if yes -> (True, Nothing)
if not -> (False, Just errorMessage)
-}
validMove : Move -> Game -> ( Bool, Maybe String )
validMove position board =
    ( True, Nothing )


legalPlayChecks : List (( Int, Board ) -> Bool)
legalPlayChecks =
    []
