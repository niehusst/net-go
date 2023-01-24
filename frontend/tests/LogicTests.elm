module LogicTests exposing (..)

import Array
import Expect exposing (Expectation)
import Logic exposing (..)
import Model.Board as Board exposing (BoardSize(..))
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (Piece(..))
import Test exposing (..)


white =
    Piece.WhiteStone


black =
    Piece.BlackStone


empty =
    Piece.None


board : Board.Board
board =
    [ [ empty, black, empty, empty, empty, empty, white, black, empty ]
    , [ black, empty, empty, empty, empty, empty, white, black, black ]
    , [ empty, empty, empty, empty, empty, empty, white, white, white ]
    , [ empty, empty, empty, empty, white, black, empty, white, empty ]
    , [ white, empty, empty, white, empty, white, black, white, empty ]
    , [ empty, white, empty, empty, white, black, empty, white, empty ]
    , [ white, black, white, empty, white, white, white, white, white ]
    , [ black, empty, empty, white, black, black, black, black, black ]
    , [ empty, empty, empty, white, black, empty, black, empty, black ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


game : Game
game =
    { boardSize = Board.Small
    , board = board
    , lastMove = Just (Move.Play white 50) -- center of board
    , history = []
    }


suite : Test
suite =
    describe "Game Logic"
        [ describe "validMove"
            [ todo "basic move is legal"
            , todo "play inside hollow structure is legal"
            , todo "violate ko rule is illegal"
            , todo "basic suicide is illegal"
            , todo "layered suicide is illegal"
            , todo "suicide to capture is legal"
            , todo "layered suicide to capture internal is legal"
            , test "playing on top of another piece is illegal" <|
                \_ ->
                    let
                        onTop =
                            Move.Play white 1
                    in
                    Expect.equal ( False, Just "Can't play on top of other pieces" ) <|
                        validMove onTop board
            ]
        ]
