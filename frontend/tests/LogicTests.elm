module LogicTests exposing (..)

import Array
import Expect exposing (Expectation)
import Logic exposing (..)
import Model.Board as Board exposing (BoardSize(..))
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (ColorChoice(..), Piece(..))
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
    , [ white, black, empty, white, empty, white, black, white, empty ]
    , [ empty, white, black, empty, white, black, empty, white, empty ]
    , [ white, black, empty, white, white, white, white, white, white ]
    , [ black, empty, empty, white, black, black, black, black, black ]
    , [ empty, empty, empty, white, black, empty, black, empty, black ]
    ]
        |> List.foldr (++) []
        |> Array.fromList


blackGame : Game
blackGame =
    { boardSize = Board.Small
    , board = board
    , lastMove = Just (Move.Play white 40) -- center of board
    , history = []
    , playerColor = Piece.Black
    }


whiteGame : Game
whiteGame =
    { boardSize = Board.Small
    , board = board
    , lastMove = Just (Move.Play white 40) -- center of board
    , history = []
    , playerColor = Piece.White
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
                        validMove openMove blackGame
            , test "filling own eye is legal" <|
                \_ ->
                    let
                        fillEye =
                            Move.Play black 0
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove fillEye blackGame
            , test "play inside hollow structure is legal" <|
                \_ ->
                    let
                        inHollow =
                            Move.Play black 44
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove inHollow blackGame
            , test "violate ko rule is illegal" <|
                \_ ->
                    let
                        koViolation =
                            Move.Play black 40
                    in
                    Expect.equal ( False, Just "You can't repeat your last move" ) <|
                        validMove koViolation blackGame
            , test "basic suicide is illegal" <|
                \_ ->
                    let
                        basicSuicide =
                            Move.Play white 0
                    in
                    Expect.equal ( False, Just "You can't cause your own capture" ) <|
                        validMove basicSuicide whiteGame
            , test "layered suicide is illegal" <|
                \_ ->
                    let
                        layeredSuicide =
                            Move.Play black 8
                    in
                    Expect.equal ( False, Just "You can't cause your own capture" ) <|
                        validMove layeredSuicide blackGame
            , test "suicide to capture is legal" <|
                \_ ->
                    let
                        basicCaptureBeforeDeath =
                            Move.Play black 45
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove basicCaptureBeforeDeath blackGame
            , test "layered suicide to capture internal is legal" <|
                \_ ->
                    let
                        layeredCaptureBeforeDeath =
                            Move.Play white 8
                    in
                    Expect.equal ( True, Nothing ) <|
                        validMove layeredCaptureBeforeDeath whiteGame
            , test "playing on top of another piece is illegal" <|
                \_ ->
                    let
                        onTop =
                            Move.Play white 1
                    in
                    Expect.equal ( False, Just "You can't play on top of other pieces" ) <|
                        validMove onTop whiteGame
            ]
        , describe "removeCapturedPieces"
            [ todo "capturing single piece in eye removes it from the board"
            , todo "captured pieces against the wall are removed"
            , todo "seki captures black on white play"
            , todo "seki captures white on black play"
            , todo "when no pieces are captured, board remains unchanged"
            , todo "life is not captured"
            , todo "layered captured pieces are removed from board"
            , todo "double capture removes both captured pieces from board"
            , todo "captured group of multiple pieces are all removed from board"
            ]
        ]
