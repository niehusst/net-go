module Logic exposing (validMove)

import Array
import Dict exposing (Dict)
import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (..)
import Set exposing (Set)


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
        case getPieceAt position game.board of
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


{-| Checks entire board to remove any captured pieces of the
enemy color from it.
Assumes that any capturing moves have been applied to board
before function call.

Returns the updated board and the number of pieces captured
(for scoring purposes).

(Since you can't capture your own pieces, the only possibility is for
scored points to be awarded to the player who played the piece, so
returning point value, or checking to remove pieces, for both
players is unnecessary; assuming
legal play has been enforced on prior turns.)

-}
removeCapturedPieces : BoardData r -> ( Board, Int )
removeCapturedPieces boardData =
    let
        --        beginningState =
        --            { surrounded = True, visited = Set.empty }
        capturedPositionsDict =
            findCapturedEnemyPieces boardData <|
                Array.toIndexedList boardData.board <|
                    Dict.empty

        updatedBoard =
            removePiecesAt capturedPositionsDict boardData.board

        numberOfCapturedPieces =
            Dict.foldr <|
                (\_ surrounded sum ->
                    if surrounded then
                        sum + 1

                    else
                        sum
                )
                    0
                    capturedPositionsDict
    in
    ( updatedBoard, numberOfCapturedPieces )


{-| Find all the captured pieces of color `color` and return
as a dictionary mapping from position to whether piece at
that position is surrounded.

color - color of piece to check if surrounded
indexedBoard - zip of a Board type with its indices
seenState - map from position to whether that position is known to be captured or not (no value if there it is not known for that position yet)

-}
findCapturedEnemyPieces : BoardData r -> List ( Int, Piece.Piece ) -> Dict Int Bool -> Dict Int Bool
findCapturedEnemyPieces boardData indexedBoard seenState =
    case indexedBoard of
        [] ->
            seenState

        ( position, piece ) :: indexedTail ->
            let
                updatedSeenState =
                    markCapturedPieces piece position boardData seenState
            in
            findCapturedEnemyPieces boardData indexedTail updatedSeenState


markCapturedPieces : Piece.Piece -> Int -> BoardData r -> Dict Int Bool -> Dict Int Bool
markCapturedPieces piece position boardData seenState =
    let
        enemyColor =
            colorInverse boardData.playerColor

        isEnemyPiece =
            piece == colorToPiece enemyColor
    in
    if isEnemyPiece && not (Dict.member position seenState) then
        let
            enemyBoardData =
                { boardData | playerColor = colorInverse boardData.playerColor }

            -- TODO: seenstate is type mismatch. need to resolve
            ( surrounded, _ ) =
                isSurroundedByEnemyOrWall enemyBoardData position seenState
        in
        Dict.insert position surrounded seenState

    else
        seenState


{-| Given a dict of positions mapped to whether or
not the piece at that position is captured, return
an updated board where all the captured positions
have been set to Piece.None.
-}
removePiecesAt : Dict Int Bool -> Board -> Board
removePiecesAt captured board =
    Array.indexedMap
        (\index piece ->
            case Dict.get index captured of
                Just True ->
                    Piece.None

                _ ->
                    piece
        )
        board


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
