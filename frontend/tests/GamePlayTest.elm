module GamePlayTest exposing (..)

import Array
import Board exposing (..)
import Expect exposing (Expectation)
import Page.GamePlay as GamePlay exposing (..)
import Test exposing (..)


noop : a -> a
noop =
    \x -> x


suite : Test
suite =
    describe "Page.GamePlay Module"
        [ describe "GamePlay.buildCssClasses"
            [ test "board css classes are generated without grid square classes in the outer right and bottom edges of the board" <|
                \_ ->
                    let
                        boardSize =
                            Board.Small

                        intBoardSize =
                            boardSizeToInt boardSize

                        model =
                            { boardSize = boardSize
                            , board = Array.repeat (intBoardSize ^ 2) Board.None
                            , lastMove = Nothing
                            , playerColor = Board.Black
                            }

                        expected9x9Classes =
                            [ List.repeat (intBoardSize - 1)
                                ([ List.repeat (intBoardSize - 1) "board-square inner-board-square"
                                 , [ "board-square" ]
                                 ]
                                    |> List.concatMap noop
                                )
                                |> List.concatMap noop
                            , List.repeat intBoardSize "board-square"
                            ]
                                |> List.concatMap noop
                    in
                    Expect.equal expected9x9Classes (buildCssClasses model)
            ]
        ]
