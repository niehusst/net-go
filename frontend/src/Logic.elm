module Logic exposing (validMove)

import Model.Board as Board exposing (..)
import Model.Move as Move exposing (..)


{-| Determine whether a move on the board is legal.
if yes -> (True, Nothing)
if not -> (False, Just errorMessage)
-}
validMove : Move -> Board -> ( Bool, Maybe String )
validMove position board =
    ( False, Just "todo" )


legalPlayChecks : List (( Int, Board ) -> Bool)
legalPlayChecks =
    []
