module ScoringLogic exposing (scoreGame)

import Set
import Util.ListExtensions exposing (indexedFoldl)
import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Score as Score exposing (Score)

-- SCORE COUNTING

{-| `borders*` booleans indicate whether the group of empty spaces
being counted borders on black or white stones (it is possible
for these both to be true if the territory is not captured).
`territorySize` is the count of territory points captured.
`seen` is a set of explored indices that we dont need to check again.
-}
type alias ScoringState =
  { bordersBlack : Bool
  , bordersWhite : Bool
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
            gameToScore =
                clearDeadStones game
        in
        countAllPoints gameToScore.board gameToScore.score


{-| For each empty space in the board, check if it's
surrounded on all sides by 1 color. If so, attribute the
number of surrounded spaces to that color's points.
Returns the updated score with the points from surrouned
spaces counted.
-}
countAllPoints : Board.Board -> Score -> Score
countAllPoints board score =
  let
      seen = Set.empty

      kernel =
        case list
  in
    List.foldl -- TODO: foldl not good enough here
      (\score pos seen ->
        if Set.member pos seen then
          score
        else
          case countPointsFrom pos board of
            (Just Piece.Black, points, updatedSeen) ->
              { state 
                | seen = updatedSeen
                , score = { score | blackPoints = score.blackPoints + points }
              }
            (Just Piece.White, points, updatedSeen) ->
              { state 
                | seen = updatedSeen
                , score = { score | whitePoints = score.whitePoints + points }
              }
            _ ->
              -- piece wasnt surrounded by 1 color, no points awarded
              score
      )
      score
      List.range 0 (Array.length board)


countPointsFrom : Int -> Board.Board -> ScoringState
countPointsFrom position board =
  let

      kernel : ScoringState -> Int -> Board.Board -> ScoringState
      kernel seen pos board =
        if Set.member pos seen then
          seen
        else
          -- TODO: everythign (copy or alter isSurroundedByEnemyOrWall?)
          seen

  in
  case getPieceAt position board of
    Just Piece.None ->
      kernel Set.empty position board
    _ ->
      -- non-empty spaces aren't counted
      (Nothing, 0)

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


getDeadStones : Board.Board -> List Int
getDeadStones board =
    -- TODO: everythign
    []
