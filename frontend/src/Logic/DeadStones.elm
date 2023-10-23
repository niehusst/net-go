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
                            { score | whitePoints = score.whitePoints + 1 }

                        Just WhiteStone ->
                            { score | blackPoints = score.blackPoints + 1 }

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
            (boardSizeToInt bData.boardSize)

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
                                (chainColorInt < 0) /= (averageControlScore < 0) || averageControlScore == 0

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

        -- TODO: get dead nearby chains? do need to do that?
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
getBoardControlProbability iterations bData seed =
    let
        boardSizeInt =
            boardSizeToInt bData.boardSize

        baseProbabilities =
            Array.repeat (boardSizeInt * boardSizeInt) 0.0

        -- finish the game `iterations` times and map each position to a probability that
        -- it is controlled by a certain color
        kernel rounds boardData controlScores =
            case rounds of
                [] ->
                    controlScores

                roundNum :: roundsTail ->
                    let
                        startingColor =
                            if Bitwise.and roundNum 1 == 1 then
                                White

                            else
                                Black

                        playedOutBoard =
                            playUntilGameComplete startingColor boardData seed
                                |> boardToIntBoard
                    in
                    List.foldl
                        (\index probabilities ->
                            let
                                probabilitiesValue =
                                    Array.get index probabilities

                                boardValue =
                                    Array.get index playedOutBoard
                            in
                            case ( probabilitiesValue, boardValue ) of
                                ( Just prob, Just pieceInt ) ->
                                    Array.set index (prob + (toFloat pieceInt / toFloat iterations)) probabilities

                                _ ->
                                    -- should never get here
                                    probabilities
                        )
                        controlScores
                        (List.range 0 (Array.length playedOutBoard))
    in
    kernel
        (List.range 0 iterations)
        bData
        baseProbabilities


{-| Makes random (legal) moves of alternating color until only eye-filling moves
remain, at which point the eyes are filled with their surrounding color.
Returns the final board position with every space filled.
-}
playUntilGameComplete : ColorChoice -> BoardData r -> Int -> Board
playUntilGameComplete startingColor boardData seedInt =
    let
        initialGame =
            setBoard boardData.board (Game.newGame boardData.boardSize startingColor 0)

        initialSeed =
            Random.initialSeed seedInt

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

        kernel : Game -> Random.Seed -> Bool -> Board
        kernel game seed opponentCouldMove =
            let
                emptyPositions =
                    Board.getEmptySpaces game.board

                ( shuffledPositions, nextSeed ) =
                    shuffle seed emptyPositions

                opponentColor =
                    Model.ColorChoice.colorInverse game.playerColor
            in
            case findValidPosition shuffledPositions game of
                Nothing ->
                    if opponentCouldMove then
                        -- the opponent was able to make a move last time, so maybe they will
                        -- be able to again and make new openings for further play
                        kernel (setPlayerColor opponentColor game) nextSeed False

                    else
                        -- neither color is able to make a legal move from the current board
                        -- state. Game is complete; exit play
                        game.board

                Just move ->
                    let
                        gameWithMove =
                            setPlayerColor opponentColor (playMove move game)
                    in
                    kernel gameWithMove nextSeed True
    in
    kernel initialGame initialSeed True
