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

            boardWithPlayedPiece =
                setPieceAt position piece game.board

            ( potentialBoardState, _ ) =
                removeCapturedPieces boardWithPlayedPiece
        in
        case getPieceAt poisition game.board of
            Piece.None ->
                -- the piece just played was captured
                ( False, Just checkMessage )

            _ ->
                okay
    ]



-- HELPERS


type alias BoardData r =
    { r
        | playerColor : Piece.ColorChoice
        , board : Board.Board
        , boardSize : Board.BoardSize
    }


{-| Checks entire board to remove any captured pieces from it.
Assumes that any capturing moves have been applied to board
before function call.

Returns the updated board and the number of pieces captured.

(Since you can't capture your own pieces, the only possibility is for
scored points to be awarded to the player who played the piece, so
returning point value for both players is unnecessary, assuming
legal play has been enforced on prior turns.)

-}
removeCapturedPieces : BoardData -> ( Board, Int )
removeCapturedPieces boardData =
    let
        positionsToRemove : List Int
        positionsToRemove =
            List.empty

        beginningState =
            { surrounded = True, visited = Set.empty }

        -- TODO: kernel should iter over every piece on board and perform dfs flood to find captured groups. uses a set to avoid redoing dfs on already tested groups
        completeState =
            kernel boardData

        updatedBoard =
            removePiecesAt positionsToRemove boardData.board
    in
    ( updatedBoard, List.size positionsToRemove )


{-| TODO type signature and also everything
-}
kernel boardData =
    case indexedBoard of
        [] ->
            state

        ( position, _ ) :: indexedTail ->
            isSurroundedByEnemyOrWall boardData position state


removePiecesAt : List Int -> Board -> Board
removePiecesAt positions board =
    let
        sortedPositions =
            List.sort positions

        -- TODO: mega not done
        removePiece : List Int -> ( Board, Board ) -> ( Board, Board )
        removePiece position ( oldBoard, newBoard ) =
            "TODO"
    in
    List.indexedMap (removePiece sortedPositions) board


{-| `visited` is a set of position indices on the board that have already been checked
-}
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
