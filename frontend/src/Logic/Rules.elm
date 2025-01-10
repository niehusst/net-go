module Logic.Rules exposing (isGameEnded, playMove, positionIsFriendlyEye, removeCapturedPieces, validMove)

import Array
import Model.Board as Board exposing (..)
import Model.ColorChoice as ColorChoice exposing (ColorChoice(..), colorInverse, colorToPiece)
import Model.Game as Game exposing (Game, addMoveToHistory, getLastMove, getLastMoveBlack, getLastMoveWhite)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (..)
import Model.Score as Score
import Set exposing (Set)


type alias MoveCheck =
    Piece -> Int -> Game -> ( Bool, Maybe String )


type alias BoardData r =
    { r
        | playerColor : ColorChoice
        , board : Board.Board
        , boardSize : Board.BoardSize
    }


okay =
    ( True, Nothing )


{-| Validates `position` is an empty space on the `game` board
and that it is surrounded on all sides by friendly stones
or the wall (making it an eye).
-}
positionIsFriendlyEye : Int -> BoardData r -> Bool
positionIsFriendlyEye position boardData =
    let
        friendly =
            colorToPiece boardData.playerColor

        positionIs : Piece.Piece -> Int -> BoardData r -> Bool
        positionIs targetPiece pos bData =
            case Board.getPieceAt pos bData.board of
                Just piece ->
                    piece == targetPiece

                Nothing ->
                    -- out of bounds (walls) are friendly
                    True

        positionEmpty =
            positionIs Piece.None position boardData

        topFriendly =
            positionIs friendly (Board.getPositionUpFrom position boardData.boardSize) boardData

        bottomFriendly =
            positionIs friendly (Board.getPositionDownFrom position boardData.boardSize) boardData

        leftFriendly =
            positionIs friendly (Board.getPositionLeftFrom position boardData.boardSize) boardData

        rightFriendly =
            positionIs friendly (Board.getPositionRightFrom position boardData.boardSize) boardData
    in
    topFriendly && rightFriendly && bottomFriendly && leftFriendly && positionEmpty


{-| Determine whether a move to be applied to the board is legal.
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
        Move.Pass _ ->
            okay

        Move.Play piece position ->
            applyChecks legalPlayChecks piece position gameState


{-| Checks entire board to remove any captured pieces of the
enemy color from it.
Assumes that any capturing moves have been applied to board
before function call.

Returns a Tuple of the updated board and the number of pieces captured
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
        capturedPositionsSet =
            findCapturedEnemyPieces
                boardData
                (Array.toIndexedList boardData.board)
                Set.empty
                Set.empty

        updatedBoard =
            removePiecesAt capturedPositionsSet boardData.board
    in
    ( updatedBoard, Set.size capturedPositionsSet )



-- HELPERS


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
        case getLastMove game of
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

            -- perform capture before checking if captured
            gameWithPlayedPiece =
                { game | board = setPieceAt position piece game.board }

            ( playerCaptureBoardState, _ ) =
                removeCapturedPieces gameWithPlayedPiece

            -- now check that the played piece does not capture itself
            gameWithPlayedPieceOnEnemyTurn =
                { game
                    | board = playerCaptureBoardState
                    , playerColor = colorInverse game.playerColor
                }

            ( enemyCaptureBoardState, _ ) =
                removeCapturedPieces gameWithPlayedPieceOnEnemyTurn
        in
        case getPieceAt position enemyCaptureBoardState of
            Just Piece.None ->
                -- the piece just played was captured
                ( False, Just checkMessage )

            _ ->
                okay
    ]


{-| Find all the captured pieces of color `color` and return
as a dictionary mapping from position to whether piece at
that position is surrounded.

color - color of piece to check if surrounded
indexedBoard - zip of a Board type with its indices
globalVisited - set of all positions that have been checked for capture
captured - set of positions of captured pieces

returns the built up `captured` set once board iteration is complete

-}
findCapturedEnemyPieces : BoardData r -> List ( Int, Piece.Piece ) -> Set Int -> Set Int -> Set Int
findCapturedEnemyPieces boardData indexedBoard globalVisited captured =
    case indexedBoard of
        [] ->
            captured

        ( position, piece ) :: indexedTail ->
            if Set.member position globalVisited then
                -- advance without redoing work
                findCapturedEnemyPieces boardData indexedTail globalVisited captured

            else
                let
                    -- we havent seen this position before, so we know it's not
                    -- connected to any other pieces we've already checked.
                    -- Therefore, we dont have to pass `globalVisited` as seenSet
                    ( groupIsCaptured, seenPositions ) =
                        markCapturedEnemyPieces piece position boardData Set.empty

                    updatedGlobalVisited =
                        Set.union globalVisited seenPositions

                    updatedCaptured =
                        if groupIsCaptured then
                            Set.union captured seenPositions

                        else
                            captured
                in
                findCapturedEnemyPieces
                    boardData
                    indexedTail
                    updatedGlobalVisited
                    updatedCaptured


markCapturedEnemyPieces : Piece.Piece -> Int -> BoardData r -> Set Int -> ( Bool, Set Int )
markCapturedEnemyPieces piece position boardData seenState =
    let
        enemyColor =
            colorInverse boardData.playerColor

        isEnemyPiece =
            piece == colorToPiece enemyColor
    in
    if isEnemyPiece && not (Set.member position seenState) then
        let
            enemyBoardData =
                { boardData | playerColor = colorInverse boardData.playerColor }

            initialState =
                { surrounded = True, visited = seenState }

            checkedState =
                isSurroundedByEnemyOrWall enemyBoardData position initialState
        in
        ( checkedState.surrounded, checkedState.visited )

    else
        -- take no action for non enemy pieces, which can't be captured
        ( False, seenState )


{-| Given a set of positions of captured pieces,
return an updated board where all the captured positions
have been set to Piece.None.
-}
removePiecesAt : Set Int -> Board -> Board
removePiecesAt captured board =
    Array.indexedMap
        (\index piece ->
            if Set.member index captured then
                Piece.None

            else
                piece
        )
        board


{-| Convenience data struct for searching the board for
captured pieces

`surrounded` indicates whether the group of conneted pieces
being evaluated are completely surrounded.
`visited` is a set position indices on the board
that have already been checked.

-}
type alias SurroundedState =
    { surrounded : Bool
    , visited : Set Int
    }


{-| DFS flood to see if pieces of the color `BoardData.playerColor`
are surrounded by enemy pieces or the wall (aka captured)
starting from the space `position` on `BoardData.board`.
-}
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
                piece =
                    getPieceAt position boardData.board

                playerPiece =
                    colorToPiece boardData.playerColor

                enemyPiece =
                    colorInverse boardData.playerColor |> colorToPiece
            in
            case piece of
                Just stonePiece ->
                    if stonePiece == playerPiece then
                        let
                            updatedVisited =
                                Set.insert position state.visited

                            updatedState =
                                { state | visited = updatedVisited }
                        in
                        -- check all neighboring spaces
                        isSurroundedByEnemyOrWall boardData (getPositionUpFrom position boardData.boardSize) updatedState
                            |> isSurroundedByEnemyOrWall boardData (getPositionDownFrom position boardData.boardSize)
                            |> isSurroundedByEnemyOrWall boardData (getPositionRightFrom position boardData.boardSize)
                            |> isSurroundedByEnemyOrWall boardData (getPositionLeftFrom position boardData.boardSize)

                    else if stonePiece == enemyPiece then
                        { state | surrounded = True }

                    else
                        -- empty space; FREEDOM!!!
                        { state | surrounded = False }

                Nothing ->
                    -- wall
                    { state | surrounded = True }


playMove : Move.Move -> Game.Game -> Game.Game
playMove move game =
    case move of
        Move.Pass _ ->
            addMoveToHistory move game

        Move.Play piece position ->
            let
                gameBoardWithMove =
                    { game | board = setPieceAt position piece game.board }

                ( boardWithoutCapturedPieces, scoredPoints ) =
                    removeCapturedPieces gameBoardWithMove

                updatedScore =
                    let
                        points =
                            toFloat scoredPoints
                    in
                    case game.playerColor of
                        ColorChoice.Black ->
                            Score.increaseBlackPoints points game.score

                        ColorChoice.White ->
                            Score.increaseWhitePoints points game.score
            in
            { game
                | board = boardWithoutCapturedPieces
                , score = updatedScore
            }
                |> addMoveToHistory move


{-| Game is over when both players passed their turn w/o playing a piece
-}
isGameEnded : Game.Game -> Bool
isGameEnded game =
    case ( getLastMoveWhite game, getLastMoveBlack game ) of
        ( Just (Move.Pass _), Just (Move.Pass _) ) ->
            True

        _ ->
            False
