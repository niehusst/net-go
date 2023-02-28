module Logic.Scoring exposing (scoreGame)

import Array
import Model.Board as Board exposing (..)
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
            -- TODO: only clear dead stones if board is above certain percent full? does dead stone clearing break on incomplete boards? is dead stone clearing even worth?
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
            getDeadStones game.board

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


{-| Use probabalistic method to determine which stones are likely to be dead.
-}
getDeadStones : Board.Board -> List Int
getDeadStones board =
    -- TODO: everythign
    []
