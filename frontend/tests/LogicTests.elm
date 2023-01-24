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
    , lastMove = Just (Move.Play white 40) -- center of board
    , history = []
    }


suite : Test
suite =
    describe "Game Logic"
        [ describe "validMove"
            [ test "basic move is legal" <|
                \_ ->
                    let
                        openMove =
                            Move.Play black 12
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove openMove game
            , test "filling own eye is legal" <|
                \_ ->
                    let
                        fillEye =
                            Move.Play black 0
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove fillEye game
            , test "play inside hollow structure is legal" <|
                \_ ->
                    let
                        inHollow =
                            Move.Play black 44
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove inHollow game
            , test "violate ko rule is illegal" <|
                \_ ->
                    let
                        koViolation =
                            Move.Play black 40
                    in
                    Expect.equal ( False, Just "You can't repeat your last move" ) <|
                        validMove koViolation game
            , test "basic suicide is illegal" <|
                \_ ->
                    let
                        basicSuicide =
                            Move.Play white 0
                    in
                    Expect.equal ( False, Just "You can't cause your own capture" ) <|
                        validMove basicSuicide game
            , test "layered suicide is illegal" <|
                \_ ->
                    let
                        layeredSuicide =
                            Move.Play black 8
                    in
                    Expect.equal ( False, Just "You can't cause your own capture" ) <|
                        validMove layeredSuicide game
            , test "suicide to capture is legal" <|
                \_ ->
                    let
                        basicCaptureBeforeDeath =
                            Move.Play black 45
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove basicCaptureBeforeDeath game
            , test "layered suicide to capture internal is legal" <|
                \_ ->
                    let
                        layeredCaptureBeforeDeath =
                            Move.Play white 8
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove layeredCaptureBeforeDeath game
            , test "playing on top of another piece is illegal" <|
                \_ ->
                    let
                        onTop =
                            Move.Play white 1
                    in
                    Expect.equal ( False, Just "You can't play on top of other pieces" ) <|
                        validMove onTop game
            ]
        ]
