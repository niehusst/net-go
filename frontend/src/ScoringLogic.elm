module ScoringLogic exposing (scoreGame)

import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Score as Score exposing (Score)
import Set
import Util.ListExtensions exposing (indexedFoldl)



-- SCORE COUNTING


type TerritoryColor
    = BlackTerritory
    | WhiteTerritory
    | ContestedTerritory


{-| `territoryColor` indicates the player that captured the territory.
`territorySize` is the count of territory points captured.
`seen` is a set of explored indices that we dont need to check again.
-}
type alias ScoringState =
    { territoryColor : TerritoryColor
    , territorySize : Int
    , seen : Set Int
    }


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
        countAllPoints gameToScore.board gameToScore.score


{-| For each group of empty spaces on `board`, check if it's
surrounded on all sides by 1 color. If so, attribute the
number of surrounded spaces to that color's points.
Returns the updated score with the points from surrouned
spaces counted.
-}
countAllPoints : Board.Board -> Score -> Score
countAllPoints board score =
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
                            getPieceAt pos board

                        isSeen =
                            Set.member pos seen
                    in
                    case ( piece, isSeen ) of
                        ( Just Piece.None, False ) ->
                            let
                                -- count up the captured territory starting from this empty territory
                                ( updatedSeen, updatedScore ) =
                                    let
                                        countingState =
                                            countPointsFrom pos board

                                        updatedSeen =
                                            Set.union (Set.insert pos seen) countingState.seen
                                    in
                                    case countingState.territoryColor of
                                        BlackTerritory ->
                                            ( updatedSeen
                                            , { score | blackPoints = score.blackPoints + countingState.territoryPoints }
                                            )

                                        WhiteTerritory ->
                                            ( updatedSeen
                                            , { score | whitePoints = score.whitePoints + countingState.territoryPoints }
                                            )

                                        ContestedTerritory ->
                                            -- piece wasnt surrounded by 1 color, no points awarded
                                            ( updatedSeen, score )
                            in
                            kernel positionsTail updatedSeen updatedScore

                        _ ->
                            -- non-empty spaces aren't counted, and we don't want to redo work
                            kernel positionsTail seen score

        ( _, countedScore ) =
            kernel
                (List.range 0 (Array.length board))
                Set.empty
                score
    in
    countedScore


{-| Counts the captured territory connected from the input `position`.
Returns both the quantity of captured territory and also the color
that captured this territory.
-}
countPointsFrom : Int -> Board.Board -> ScoringState
countPointsFrom position board =
    let
        startingState =
            { territoryColor = ContestedTerritory
            , territoryPoints = 0
            , seen = Set.empty
            }

        kernel : ScoringState -> Int -> Board.Board -> ScoringState
        kernel state pos board =
            if Set.member pos state.seen then
                state

            else
                -- TODO: everythign (copy or alter isSurroundedByEnemyOrWall?)
                state
    in
    kernel startingState position board



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
        clearIndices indices board =
            List.foldl
                (\board index -> setPieceAt index Piece.None board)
                board
                indices

        -- award opponents points per dead stone
        newScore =
            List.foldl
                (\score index ->
                    case getPieceAt index game.board of
                        Just Piece.BlackPiece ->
                            { score | whitePoints = score.whitePoints + 1 }

                        Just Piece.WhtiePiece ->
                            { score | blackPoints = score.blackPoints + 1 }

                        Nothing ->
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
