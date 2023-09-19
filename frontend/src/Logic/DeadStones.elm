module Logic.DeadStones exposing (clearDeadStones)

-- thanks to SabakiHQ for the algorithm idea and guide
-- https://github.com/SabakiHQ/deadstones

import Array exposing (Array)
import Bitwise
import Model.Board as Board exposing (..)
import Model.ColorChoice exposing (ColorChoice(..), colorToPiece)
import Model.Game as Game exposing (..)
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
        boardControlScores =
            getBoardControlProbability 100 bData seed

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
                                                runSum
                                    )
                                    0
                                    connectedStones

                            averageControlScore =
                                sumControlScore / toFloat (List.length connectedStones)

                            averageControlIsEnemy =
                                ((colorToPiece >> pieceToInt) boardData.playerColor < 0) == (averageControlScore < 0)

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

        -- TODO: get dead nearby chains
    in
    kernel
        (List.range 0 (boardSizeToInt bData.boardSize))
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
        baseProbabilities =
            Array.repeat (boardSizeToInt bData.boardSize) 0.0

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


playUntilGameComplete : ColorChoice -> BoardData r -> Int -> Board
playUntilGameComplete startingColor boardData seed =
    -- TODO: actual monte carlo shit
    let
        initialSeed =
            Random.initialSeed seed

        (randNum, newSeed) =
            Random.step (Random.int 0 100) initialSeed
    in
    Array.empty
