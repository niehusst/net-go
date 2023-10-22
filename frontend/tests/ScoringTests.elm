module ScoringTests exposing (..)

import Array
import Expect exposing (Expectation)
import Logic.Scoring exposing (..)
import Model.Board as Board exposing (BoardSize(..), setPieceAt)
import Model.ColorChoice exposing (ColorChoice(..))
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (Piece(..))
import Model.Score as Score exposing (..)
import Random
import Test exposing (..)

-- TODO: use test fuzzing seed??
initialSeed = 42069

white =
    Piece.WhiteStone


black =
    Piece.BlackStone


empty =
    Piece.None


complexGame : Board.Board
complexGame =
    [ [ empty, empty, black, black, black, white, empty, empty, empty ]
    , [ empty, black, empty, black, white, empty, empty, white, empty ]
    , [ empty, black, black, white, white, empty, empty, empty, white ]
    , [ empty, empty, black, black, white, empty, white, white, black ]
    , [ empty, empty, black, white, empty, empty, white, black, black ]
    , [ empty, black, white, white, white, white, black, empty, black ]
    , [ empty, empty, black, white, white, black, black, black, black ]
    , [ empty, empty, black, white, white, white, black, empty, white ]
    , [ empty, empty, black, black, black, white, black, white, empty ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


incompleteGame : Board.Board
incompleteGame =
    [ [ empty, empty, empty, empty, empty, empty, black, black, empty ]
    , [ empty, empty, empty, empty, empty, empty, white, black, white ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, white ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, white, empty, empty, empty, empty ]
    , [ empty, empty, empty, black, empty, empty, empty, white, empty ]
    , [ black, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ white, empty, empty, empty, empty, empty, empty, empty, empty ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


seki : Board.Board
seki =
    [ [ empty, black, empty, black, white, empty, empty, empty, empty ]
    , [ empty, black, white, black, white, empty, empty, empty, empty ]
    , [ empty, black, white, black, white, empty, empty, empty, empty ]
    , [ empty, black, black, white, white, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ black, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ white, empty, empty, empty, empty, empty, empty, empty, empty ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


life : Board.Board
life =
    [ [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, white, white, white, white, white, white ]
    , [ black, empty, empty, white, black, black, black, black, black ]
    , [ white, empty, empty, white, black, empty, black, empty, black ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


deadStones =
    [ [ white, white, white, white, white, white, white, black, empty ]
    , [ white, white, white, white, white, white, white, black, black ]
    , [ white, white, white, white, white, white, white, white, white ]
    , [ white, white, white, empty, white, white, white, white, white ]
    , [ white, white, white, white, empty, white, white, white, white ]
    , [ white, white, white, white, white, white, white, white, white ]
    , [ white, white, white, white, white, white, white, white, white ]
    , [ black, white, white, white, white, white, white, white, white ]
    , [ empty, white, white, white, white, white, white, white, white ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


falseLife : Board.Board
falseLife =
    [ [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, empty, empty, empty, empty, empty, empty ]
    , [ empty, empty, empty, white, white, white, white, white, white ]
    , [ black, empty, empty, white, white, black, black, black, black ]
    , [ white, empty, empty, white, black, empty, black, empty, black ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


tie : Board.Board
tie =
    [ [ black, black, black, black, white, white, white, white, white ]
    , [ empty, black, black, black, white, white, white, white, empty ]
    , [ empty, black, black, black, white, white, white, white, empty ]
    , [ empty, black, black, black, white, white, white, white, empty ]
    , [ empty, black, black, black, empty, white, white, white, empty ]
    , [ empty, black, black, black, black, white, white, white, empty ]
    , [ empty, black, black, black, black, white, white, white, empty ]
    , [ empty, black, black, black, black, white, white, white, empty ]
    , [ black, black, black, black, black, white, white, white, white ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


game : Game.Game
game =
    { boardSize = Board.Small
    , board = life
    , lastMove = Just (Move.Play white 40) -- center of board
    , history = []
    , playerColor = Black
    , isOver = False
    , score = Score.initWithKomi 0.0
    }


suite : Test
suite =
    describe "Scoring module"
        [ describe "scoreGame"
            [ test "score for seki is shared by both players" <|
                \_ ->
                    let
                        expectedScore =
                            "Draw"

                        actualScore =
                            scoreGame { game | board = seki } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , test "score for complete game is accurate" <|
                \_ ->
                    let
                        expectedScore =
                            "B+3"

                        actualScore =
                            scoreGame game initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , test "life does not get removed from board or count toward enemy score" <|
                \_ ->
                    let
                        expectedScore =
                            "B+2"

                        actualScore =
                            scoreGame { game | board = life } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , only <| test "dead stones get removed from board for scoring and are included in score" <|
                \_ ->
                    let
                        expectedScore =
                            "W+12"

                        actualScore =
                            scoreGame { game | board = deadStones } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , test "false life removed from board" <|
                \_ ->
                    let
                        expectedScore =
                            "W+7"

                        actualScore =
                            scoreGame { game | board = falseLife } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , test "komi score can tip balance" <|
                \_ ->
                    let
                        expectedScore =
                            "W+0.5"

                        actualScore =
                            scoreGame { game | board = tie, score = initWithKomi 0.5 } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , test "captured stone points are weighed into final score" <|
                \_ ->
                    let
                        expectedScore =
                            "B+6.5"

                        captureScore =
                            let
                                initialScore =
                                    initWithKomi 5.5
                            in
                            { initialScore | blackPoints = 12.0 }

                        actualScore =
                            scoreGame { game | board = tie, score = captureScore } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , test "tied score is possible when komi is not used" <|
                \_ ->
                    let
                        expectedScore =
                            "Draw"

                        actualScore =
                            scoreGame { game | board = tie } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            , test "forfeited games are not scored since they are forfeit" <|
                \_ ->
                    let
                        score =
                            Score.initWithKomi 0.0

                        forfeitScore =
                            { score | isForfeit = True }

                        actualScore =
                            scoreGame { game | score = forfeitScore } initialSeed
                                |> scoreToString
                    in
                    Expect.equal "Forfeit" actualScore
            , test "very incomplete game gets scored" <|
                \_ ->
                    let
                        expectedScore =
                            "Draw"

                        actualScore =
                            scoreGame { game | board = incompleteGame } initialSeed
                                |> scoreToString
                    in
                    Expect.equal expectedScore actualScore
            ]
        ]
