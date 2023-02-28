module GamePlayTest exposing (..)

import Array
import Expect exposing (Expectation)
import Model.Board as Board exposing (..)
import Model.ColorChoice exposing (ColorChoice(..))
import Model.Piece as Piece
import Page.GamePlay as GamePlay exposing (..)
import Test exposing (..)


noop : a -> a
noop =
    \x -> x


suite : Test
suite =
    describe "Page.GamePlay Module"
        [ describe "GamePlay.buildCssClasses"
            [ test "empty board css classes are generated correctly to render the board" <|
                \_ ->
                    let
                        boardSize =
                            Board.Small

                        intBoardSize =
                            boardSizeToInt boardSize

                        model =
                            { boardSize = boardSize
                            , board = Array.repeat (intBoardSize ^ 2) Piece.None
                            , lastMove = Nothing
                            , playerColor = Black
                            }

                        expected9x9InnerSquaresTruthTable =
                            [ List.repeat (intBoardSize - 1)
                                ([ List.repeat (intBoardSize - 1) True
                                 , [ False ]
                                 ]
                                    |> List.concatMap noop
                                )
                                |> List.concatMap noop
                            , List.repeat intBoardSize False
                            ]
                                |> List.concatMap noop

                        actual9x9InnerSquaresTruthTable =
                            List.map (isInnerCell boardSize) (List.range 0 ((intBoardSize ^ 2) - 1))
                    in
                    Expect.equal expected9x9InnerSquaresTruthTable actual9x9InnerSquaresTruthTable
            ]
        ]
