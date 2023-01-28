module Logic exposing (validMove)

import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (..)
import Set exposing (..)


type alias MoveCheck =
    Piece -> Int -> Game -> ( Bool, Maybe String )


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
    , \piece position game ->
        let
            checkMessage =
                "You can't cause your own capture"

            beginningState =
                { surrounded = True, visited = Set.empty }

            potentialGameState =
                { game | board = setPieceAt position piece game.board }
        in
        if not (isSurroundedByEnemyOrWall potentialGameState position beginningState).surrounded then
            okay

        else
            ( False, Just checkMessage )
    ]



-- HELPERS


type alias BoardData r =
    { r
        | playerColor : Piece.ColorChoice
        , board : Board.Board
        , boardSize : Board.BoardSize
    }


type alias SurroundedState =
    { surrounded : Bool
    , visited : Set Int
    }


isSurroundedByEnemyOrWall : BoardData r -> Int -> SurroundedState -> SurroundedState
isSurroundedByEnemyOrWall boardData position state =
    let
        alreadySeen =
            Set.member position state.visited
    in
    case ( state.surrounded, alreadySeen ) of
        ( False, _ ) ->
            -- exit early
            state

        ( _, True ) ->
            -- don't recheck already seen pieces
            state

        _ ->
            let
                updatedVisited =
                    Set.insert position state.visited

                piece =
                    getPieceAt position boardData.board

                playerPiece =
                    colorToPiece boardData.playerColor

                enemyPiece =
                    colorInverse boardData.playerColor |> colorToPiece

                updatedState =
                    { state | visited = updatedVisited }
            in
            case piece of
                Just stonePiece ->
                    if stonePiece == playerPiece then
                        -- check all neighboring spaces
                        isSurroundedByEnemyOrWall boardData (getPositionUpFrom position boardData.boardSize) updatedState
                            |> isSurroundedByEnemyOrWall boardData (getPositionDownFrom position boardData.boardSize)
                            |> isSurroundedByEnemyOrWall boardData (getPositionRightFrom position boardData.boardSize)
                            |> isSurroundedByEnemyOrWall boardData (getPositionLeftFrom position boardData.boardSize)

                    else if stonePiece == enemyPiece then
                        { surrounded = True, visited = updatedVisited }

                    else
                        -- empty space; FREEDOM!!!
                        { surrounded = False, visited = updatedVisited }

                Nothing ->
                    -- wall
                    { surrounded = True, visited = updatedVisited }
