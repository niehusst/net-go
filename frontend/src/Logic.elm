module Logic exposing (validMove)

import Board exposing (..)


validMove : Int -> Board -> ( Bool, Maybe String )
validMove position board =
    ( False, Just "todo" )


legalPlayChecks : List (( Int, Board ) -> Bool)
legalPlayChecks =
    []
