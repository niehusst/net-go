module Logic.DeadStones exposing (clearDeadStones)

-- thanks to SabakiHQ for the algorithm idea and guide
-- https://github.com/SabakiHQ/deadstones

import Array exposing (Array)
import Bitwise
import ListExtra exposing (shuffle)
import Logic.Rules exposing (playMove, positionIsFriendlyEye, removeCapturedPieces, validMove)
import Model.Board as Board exposing (..)
import Model.ColorChoice exposing (ColorChoice(..), colorToPiece)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (Piece(..), intToPiece, pieceToInt)
import Model.Score as Score exposing (Score)
import Random
import Set exposing (Set)


{-| Convenience datatype for holding board related data
necessary for 2D board traversal.
-}
type alias BoardData r =
    { r
        | boardSize : BoardSize
        , board : Board
        , playerColor : ColorChoice
    }


{-| Given a board that is ready for scoring, return a
board with the dead stones removed from it.
-}
clearDeadStones : Game.Game -> Int -> Game.Game
clearDeadStones game seed =
    let
        deadStoneIndices =
            getDeadStones game seed

        clearIndices : List Int -> Board.Board -> Board.Board
        clearIndices indices gameBoard =
            List.foldl
                (\index board -> setPieceAt index Piece.None board)
                gameBoard
                indices

        -- award opponents points per dead stone
        newScore =
            List.foldl
                (\index score ->
                    case getPieceAt index game.board of
                        Just BlackStone ->
                            Score.increaseWhitePoints 1 score

                        Just WhiteStone ->
                            Score.increaseBlackPoints 1 score

                        _ ->
                            score
                )
                game.score
                deadStoneIndices
    in
    { game
        | board = clearIndices deadStoneIndices game.board
        , score = newScore
    }


{-| Use probabalistic methods to determine which stones are likely to be dead.
Returns the list of board positions where there are stones that are likely dead.
-}
getDeadStones : BoardData r -> Int -> List Int
getDeadStones bData seed =
    let
        -- perform 100 iterations of monte carlo alg
        boardControlScores =
            getBoardControlProbability 100 bData seed

        intSize =
            boardSizeToInt bData.boardSize

        boardLen =
            intSize * intSize

        {- for each connected chunk of stones on board, check
           if they are dead on average. If so, add to list of dead stones
        -}
        kernel : List Int -> Array Float -> BoardData r -> List Int -> Set Int -> List Int
        kernel boardPositions controlScores boardData deadStoneIndeces seen =
            case boardPositions of
                [] ->
                    deadStoneIndeces

                index :: positionsTail ->
                    let
                        notSeen =
                            not (Set.member index seen)

                        isPiece =
                            case getPieceAt index boardData.board of
                                Just piece ->
                                    piece /= None

                                Nothing ->
                                    False
                    in
                    if notSeen && isPiece then
                        let
                            connectedStones =
                                getConnectedStoneIndeces index boardData

                            updatedSeen =
                                Set.union seen (Set.fromList connectedStones)

                            sumControlScore =
                                List.foldr
                                    (\pos runSum ->
                                        case Array.get pos controlScores of
                                            Just probability ->
                                                runSum + probability

                                            Nothing ->
                                                -- should never happen; controlScores length != board length
                                                runSum
                                    )
                                    0
                                    connectedStones

                            averageControlScore =
                                sumControlScore / toFloat (List.length connectedStones)

                            chainColorInt =
                                pieceToInt <|
                                    case getPieceAt index boardData.board of
                                        Just piece ->
                                            piece

                                        Nothing ->
                                            None

                            -- check if average control of chain area matches the stone color on board.
                            -- if it doesnt, then that stone is usually captured by opponent
                            averageControlIsEnemy =
                                (chainColorInt < 0) /= (averageControlScore < 0) && averageControlScore /= 0

                            updatedDeadStones =
                                if averageControlIsEnemy then
                                    -- stones are likely dead
                                    deadStoneIndeces ++ connectedStones

                                else
                                    deadStoneIndeces
                        in
                        kernel positionsTail controlScores boardData updatedDeadStones updatedSeen

                    else
                        kernel positionsTail controlScores boardData deadStoneIndeces seen
    in
    kernel
        (List.range 0 boardLen)
        boardControlScores
        bData
        []
        Set.empty


{-| Use DFS to find the list of indeces of connected stones
of the same color from the provided `index` on the board.
-}
getConnectedStoneIndeces : Int -> BoardData r -> List Int
getConnectedStoneIndeces index bData =
    let
        connectedColor =
            Maybe.withDefault None (getPieceAt index bData.board)

        initialData =
            { seen = Set.empty
            , connected = []
            }

        kernel position chainColor boardData data =
            if Set.member position data.seen then
                data

            else
                case getPieceAt position boardData.board of
                    Nothing ->
                        data

                    Just piece ->
                        if piece == chainColor then
                            let
                                updatedData =
                                    { seen = Set.insert position data.seen
                                    , connected = position :: data.connected
                                    }
                            in
                            kernel (getPositionUpFrom position boardData.boardSize) chainColor boardData updatedData
                                |> kernel (getPositionDownFrom position boardData.boardSize) chainColor boardData
                                |> kernel (getPositionLeftFrom position boardData.boardSize) chainColor boardData
                                |> kernel (getPositionRightFrom position boardData.boardSize) chainColor boardData

                        else
                            data

        finalData =
            kernel index connectedColor bData initialData
    in
    finalData.connected


{-| Get the probability of each space on the provided board being controlled
by each player. Each probablity is represented by a float in the range
of -1...1, where values closer to -1 indicate stronger white control and
values closer to 1 indicates stronger black control.

The more `iterations` run, the higher confidence this probablistic
algorithm provides.

-}
getBoardControlProbability : Int -> BoardData r -> Int -> Array Float
getBoardControlProbability iterations bData seedInt =
    let
        initialSeed =
            Random.initialSeed seedInt

        boardSizeInt =
            boardSizeToInt bData.boardSize

        baseProbabilities =
            Array.repeat (boardSizeInt * boardSizeInt) 0.0

        -- finish the game `iterations` times and map each position to a probability that
        -- it is controlled by a certain color
        kernel : List Int -> BoardData r -> Array Float -> Random.Seed -> Array Float
        kernel rounds boardData controlScores seed =
            case rounds of
                [] ->
                    controlScores

                roundNum :: roundsTail ->
                    let
                        -- alternate starting color based on round number
                        startingColor =
                            if Bitwise.and roundNum 1 == 1 then
                                White

                            else
                                Black

                        ( playedOutBoard, updatedSeed ) =
                            playUntilGameComplete startingColor boardData seed

                        -- fill eyes on played out board so they get counted toward
                        -- correct player control scores (we expect the played-out board
                        -- to be basically full (excluding seki) asside from eyes anyway)
                        filledBoard =
                            fillEyes { boardData | board = playedOutBoard }

                        intPlayedOutBoard =
                            boardToIntBoard filledBoard

                        updatedControlScores =
                            List.foldl
                                (\index probabilities ->
                                    let
                                        probabilitiesValue =
                                            Array.get index probabilities

                                        boardValue =
                                            Array.get index intPlayedOutBoard
                                    in
                                    case ( probabilitiesValue, boardValue ) of
                                        ( Just currProb, Just pieceInt ) ->
                                            -- pre-divide control values by iterations during summation to save a map
                                            Array.set index (currProb + (toFloat pieceInt / toFloat iterations)) probabilities

                                        _ ->
                                            -- should never get here
                                            probabilities
                                )
                                controlScores
                                (List.range 0 (Array.length intPlayedOutBoard))
                    in
                    kernel roundsTail boardData updatedControlScores updatedSeed
    in
    kernel
        (List.range 0 (iterations - 1))
        bData
        baseProbabilities
        initialSeed


{-| Fill every eye in `boardData.board` with a piece of a matching color.
This is a helper function to ensure that board control is properly attributed
even when counting empty spaces that are eyes.
-}
fillEyes : BoardData r -> Board
fillEyes boardData =
    let
        b =
            boardData.board
    in
    Array.indexedMap
        (\index piece ->
            case piece of
                Piece.None ->
                    -- potential eye to fill w/ piece matching surrounding color
                    pieceSurroundingEyeAtIndex index boardData

                _ ->
                    piece
        )
        boardData.board


{-| Get the Piece matching those surrounding the eye at `index`.
If there is no single color of piece surrounding the eye at `index`,
Piece.None is returned.
-}
pieceSurroundingEyeAtIndex : Int -> BoardData r -> Piece
pieceSurroundingEyeAtIndex index boardData =
    case Board.getPieceAt index boardData.board of
        Just Piece.None ->
            -- index is a potential eye!
            let
                neighbors =
                    [ Board.getPieceAt (Board.getPositionUpFrom index boardData.boardSize) boardData.board
                    , Board.getPieceAt (Board.getPositionDownFrom index boardData.boardSize) boardData.board
                    , Board.getPieceAt (Board.getPositionLeftFrom index boardData.boardSize) boardData.board
                    , Board.getPieceAt (Board.getPositionRightFrom index boardData.boardSize) boardData.board
                    ]

                -- neighbors must all be same piece, or wall (Nothing), to be an eye
                maybeControlPiece =
                    List.foldl
                        (\maybePiece acc ->
                            case ( maybePiece, acc ) of
                                ( Nothing, _ ) ->
                                    -- wall, that's ok
                                    acc

                                ( Just neighborPiece, Just controlPiece ) ->
                                    -- make sure new neighbors match existing ones
                                    if neighborPiece /= controlPiece then
                                        -- None as the controlling piece type if not an eye
                                        Just Piece.None

                                    else
                                        acc

                                ( Just neighborPiece, Nothing ) ->
                                    -- set neighbor as the candidate surrounding piece
                                    Just neighborPiece
                        )
                        Nothing
                        neighbors
            in
            case maybeControlPiece of
                Nothing ->
                    Piece.None

                Just piece ->
                    piece

        Just piece ->
            -- wasnt actually an eye; break out
            piece

        Nothing ->
            -- should never check out-of-bounds as eye
            Piece.None


{-| Makes random (legal) moves of alternating color until only eye-filling moves
remain, at which point the eyes are filled with their surrounding color.
Returns the final board position with every space filled.
Also returns the stepped value of the random seed that was used, so as
to avoid repeat results when recursively calling this function.
-}
playUntilGameComplete : ColorChoice -> BoardData r -> Random.Seed -> ( Board, Random.Seed )
playUntilGameComplete startingColor boardData initialSeed =
    let
        -- x2 turn count so that each color gets that many turns
        maxTurns =
            100 * 2

        initialGame =
            setBoard boardData.board (Game.newGame boardData.boardSize startingColor 0 "" "")

        findValidPosition : List Int -> Game -> Maybe Move
        findValidPosition positions game =
            case positions of
                [] ->
                    Nothing

                position :: positionsTail ->
                    let
                        piece =
                            colorToPiece game.playerColor

                        move =
                            Move.Play piece position

                        ( isLegal, _ ) =
                            validMove move game

                        botMoveValidity =
                            isLegal && not (positionIsFriendlyEye position game)
                    in
                    if botMoveValidity then
                        Just move

                    else
                        findValidPosition positionsTail game

        kernel : Game -> Random.Seed -> Bool -> Int -> ( Board, Random.Seed )
        kernel game seed opponentCouldMove turnCount =
            let
                updatedTurnCount =
                    turnCount + 1

                emptyPositions =
                    Board.getEmptySpaces game.board

                ( shuffledPositions, nextSeed ) =
                    shuffle seed emptyPositions

                opponentColor =
                    Model.ColorChoice.colorInverse game.playerColor
            in
            if turnCount > maxTurns then
                ( game.board, nextSeed )

            else
                case findValidPosition shuffledPositions game of
                    Nothing ->
                        if opponentCouldMove then
                            -- the opponent was able to make a move last time, so maybe they will
                            -- be able to again and make new openings for further play
                            kernel (setPlayerColor opponentColor game) nextSeed False updatedTurnCount

                        else
                            -- neither color is able to make a legal move from the current board
                            -- state. Game is complete; exit play
                            ( game.board, nextSeed )

                    Just move ->
                        let
                            gameWithMove =
                                setPlayerColor opponentColor (playMove move game)
                        in
                        kernel gameWithMove nextSeed True updatedTurnCount
    in
    kernel initialGame initialSeed True 0
