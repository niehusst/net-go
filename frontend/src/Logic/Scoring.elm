module Logic.Scoring exposing (scoreGame)

import Array exposing (Array)
import Bitwise
import Model.Board as Board exposing (..)
import Model.ColorChoice exposing (ColorChoice(..), colorToPiece)
import Model.Game as Game exposing (..)
import Model.Piece as Piece exposing (Piece(..), intToPiece, pieceToInt)
import Model.Score as Score exposing (Score)
import Set exposing (Set)



-- SCORE COUNTING


type TerritoryColor
    = BlackTerritory
    | WhiteTerritory
    | ContestedTerritory


{-| Given a game, return the final Score for the game.
Uses territory scoring to calculate the score.
-}
scoreGame : Game.Game -> Score
scoreGame game =
    if game.score.isForfeit then
        -- no need to do complex scoring work for forfeit games
        game.score

    else
        let
            -- TODO: switch to area scoring for boards fewer than 1/3 full???
            -- clear the dead stones from the board before counting territory
            gameToScore =
                clearDeadStones game
        in
        countAllPoints gameToScore gameToScore.score


{-| For each group of empty spaces on `board`, check if it's
surrounded on all sides by 1 color. If so, attribute the
number of surrounded spaces to that color's points.
Returns the updated score with the points from surrouned
spaces counted.
-}
countAllPoints : BoardData r -> Score -> Score
countAllPoints boardData initialScore =
    let
        -- TODO: this is a lot of case nesting. break into smaller funcs or compress cases?
        kernel : List Int -> Set Int -> Score -> ( Set Int, Score )
        kernel positions seen score =
            case positions of
                [] ->
                    ( seen, score )

                pos :: positionsTail ->
                    let
                        piece =
                            getPieceAt pos boardData.board

                        isSeen =
                            Set.member pos seen
                    in
                    case ( piece, isSeen ) of
                        ( Just Piece.None, False ) ->
                            let
                                -- count up the captured territory starting from this empty territory
                                ( updatedSeen, updatedScore ) =
                                    let
                                        ( territoryColor, territoryPoints, visited ) =
                                            countPointsFrom pos boardData

                                        combinedSeen =
                                            Set.union (Set.insert pos seen) visited

                                        floatPoints =
                                            toFloat territoryPoints
                                    in
                                    case territoryColor of
                                        BlackTerritory ->
                                            ( combinedSeen
                                            , { score | blackPoints = score.blackPoints + floatPoints }
                                            )

                                        WhiteTerritory ->
                                            ( combinedSeen
                                            , { score | whitePoints = score.whitePoints + floatPoints }
                                            )

                                        ContestedTerritory ->
                                            -- piece wasnt surrounded by 1 color, no points awarded
                                            ( combinedSeen, score )
                            in
                            kernel positionsTail updatedSeen updatedScore

                        _ ->
                            -- non-empty spaces aren't counted, and we don't want to redo work
                            kernel positionsTail seen score

        ( _, countedScore ) =
            kernel
                (List.range 0 (Array.length boardData.board))
                Set.empty
                initialScore
    in
    countedScore


{-| Counts the captured territory connected to the input index on the board, `position`.
Returns a tuple of:

  - what single color (if any) captured the territory
  - the quantity of captured territory
  - the set of explored positions on the board (so caller does not have to recheck them)

-}
countPointsFrom : Int -> BoardData r -> ( TerritoryColor, Int, Set Int )
countPointsFrom position boardData =
    let
        startingState =
            { visited = Set.empty
            , surroundingPieces = Set.empty
            }

        surroundingData =
            getSurroundingData boardData position startingState

        surroundingPieces =
            Set.toList surroundingData.surroundingPieces
                |> List.map intToPiece

        territoryOwner =
            case surroundingPieces of
                (Just WhiteStone) :: [] ->
                    WhiteTerritory

                (Just BlackStone) :: [] ->
                    BlackTerritory

                _ ->
                    ContestedTerritory
    in
    ( territoryOwner
    , Set.size surroundingData.visited
    , surroundingData.visited
    )


{-| Convenience datatype for holding board related data
necessary for 2D board traversal.
-}
type alias BoardData r =
    { r
        | boardSize : BoardSize
        , board : Board
        , playerColor : ColorChoice
    }


{-| Helper type for determing which pieces surround empty territory.
`visited`: set of (empty) positions that have already been explored
`surroundingPieces`: set of int representation of pieces that are surrounding the empty territory
-}
type alias SurroundingState =
    { visited : Set Int
    , surroundingPieces : Set Int
    }


getSurroundingData : BoardData r -> Int -> SurroundingState -> SurroundingState
getSurroundingData boardData position state =
    if Set.member position state.visited then
        -- don't recheck already seen pieces
        state

    else
        case getPieceAt position boardData.board of
            Just stonePiece ->
                if stonePiece == None then
                    -- continue exploring empty space chain
                    let
                        updatedState =
                            { state | visited = Set.insert position state.visited }
                    in
                    getSurroundingData boardData (getPositionUpFrom position boardData.boardSize) updatedState
                        |> getSurroundingData boardData (getPositionDownFrom position boardData.boardSize)
                        |> getSurroundingData boardData (getPositionRightFrom position boardData.boardSize)
                        |> getSurroundingData boardData (getPositionLeftFrom position boardData.boardSize)

                else
                    -- record a surrounding piece
                    let
                        pieceAsInt =
                            pieceToInt stonePiece
                    in
                    { state | surroundingPieces = Set.insert pieceAsInt state.surroundingPieces }

            Nothing ->
                -- wall. counts for either color, so dont record
                state



-- DEAD STONE FINDING


{-| Given a board that is ready for scoring, return a
board with the dead stones removed from it.
-}
clearDeadStones : Game.Game -> Game.Game
clearDeadStones game =
    let
        deadStoneIndices =
            getDeadStones game

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
getDeadStones : BoardData r -> List Int
getDeadStones bData =
    -- TODO: only run quick alg if board is above certain percent full? does quick alg break on incomplete boards? is quick alg even worth?
    let
        -- TODO: get floating stones?
        boardControlScores =
            getBoardControlProbability 100 bData

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
getBoardControlProbability : Int -> BoardData r -> Array Float
getBoardControlProbability iterations bData =
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
                            playUntilGameComplete startingColor boardData
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


playUntilGameComplete : ColorChoice -> BoardData r -> Board
playUntilGameComplete startingColor boardData =
    -- TODO:
    Array.empty
