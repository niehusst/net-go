module Logic exposing (validMove)

import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (..)


okay =
    ( True, Nothing )


{-| Determine whether a move on the board is legal.
if yes -> (True, Nothing)
if not -> (False, Just errorMessage)
-}
validMove : Move.Move -> Game -> ( Bool, Maybe String )
validMove move gameState =
    let
        applyChecks : List MoveCheck -> Piece -> Int -> Game -> ( Bool, Maybe String )
        applyChecks checks piece position game =
            case checks of
                [] ->
                    okay

                check :: checksTail ->
                    case check piece position game of
                        ( False, Just errorMessage ) ->
                            ( False, Just errorMessage )

                        _ ->
                            applyChecks checksTail piece position game
    in
    case move of
        Move.Pass ->
            okay

        Move.Play piece position ->
            applyChecks legalPlayChecks piece position gameState


type alias MoveCheck =
    Piece -> Int -> Game -> ( Bool, Maybe String )


legalPlayChecks : List MoveCheck
legalPlayChecks =
    [ \piece position game ->
        let
            checkMessage =
                "You can't play on top of other pieces"

            pieceAtPosition =
                Board.getPieceAt position game.board
        in
        case pieceAtPosition of
            Just Piece.None ->
                okay

            _ ->
                ( False, Just checkMessage )
    , \piece position game ->
        let
            checkMessage =
                "You can't repeat your last move"
        in
        case game.lastMove of
            Just (Move.Play _ prevPos) ->
                if position == prevPos then
                    ( False, Just checkMessage )

                else
                    okay

            _ ->
                okay
    ]
