module RulesTests exposing (..)

import Array
import Expect exposing (Expectation)
import Logic.Rules exposing (..)
import Model.Board as Board exposing (BoardSize(..), setPieceAt)
import Model.ColorChoice exposing (ColorChoice(..))
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (Piece(..))
import Model.Score as Score
import Test exposing (..)


white =
    Piece.WhiteStone


black =
    Piece.BlackStone


empty =
    Piece.None


board : Board.Board
board =
    [ [ empty, black, empty, black, white, empty, white, black, empty ]
    , [ black, black, white, black, white, empty, white, black, black ]
    , [ empty, black, white, black, white, empty, white, white, white ]
    , [ empty, black, black, white, white, black, empty, white, empty ]
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
    , history =
          [ (Move.Play black 40)
          , (Move.Play white 40)
          ]
    , playerColor = Black
    , isOver = False
    , score = Score.initWithKomi 0
    }


whiteGame : Game
whiteGame =
    { boardSize = Board.Small
    , board = board
    , history =
          [ (Move.Play black 40)
          , (Move.Play white 40)
          ]
    , playerColor = White
    , isOver = False
    , score = Score.initWithKomi 0
    }


suite : Test
suite =
    describe "Game Logic"
        [ describe "validMove"
            [ test "basic move is legal" <|
                \_ ->
                    let
                        openMove =
                            Move.Play black 73
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
            , test "filling life eye is illegal" <|
                \_ ->
                    let
                        fillLife =
                            Move.Play white 79
                    in
                    Expect.equal ( False, Just "You can't cause your own capture" ) <|
                        validMove fillLife whiteGame
            ]
        , describe "removeCapturedPieces"
            [ test "capturing single piece in eye removes it from the board" <|
                \_ ->
                    let
                        expectedEndBoard =
                            whiteGame.board

                        expectedNumCapturedPieces =
                            1

                        capturedBlackGameState =
                            { whiteGame | board = setPieceAt 40 black whiteGame.board }
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces capturedBlackGameState)
            , test "captured pieces against the wall are removed" <|
                \_ ->
                    let
                        expectedEndBoard =
                            whiteGame.board

                        expectedNumCapturedPieces =
                            3

                        boardBlackPiecesCapturedAgainstWall =
                            setPieceAt 35 black whiteGame.board
                                |> setPieceAt 44 black
                                |> setPieceAt 53 black

                        capturedBlackGameState =
                            { whiteGame | board = boardBlackPiecesCapturedAgainstWall }
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces capturedBlackGameState)
            , test "seki captures black on white play" <|
                \_ ->
                    let
                        expectedEndBoard =
                            setPieceAt 2 white whiteGame.board
                                |> setPieceAt 3 empty
                                |> setPieceAt 12 empty
                                |> setPieceAt 21 empty

                        expectedNumCapturedPieces =
                            3

                        capturedBlackGameState =
                            { whiteGame | board = setPieceAt 2 white whiteGame.board }
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces capturedBlackGameState)
            , test "seki captures white on black play" <|
                \_ ->
                    let
                        expectedEndBoard =
                            setPieceAt 2 black blackGame.board
                                |> setPieceAt 11 empty
                                |> setPieceAt 20 empty

                        expectedNumCapturedPieces =
                            2

                        capturedWhiteGameState =
                            { blackGame | board = setPieceAt 2 black blackGame.board }
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces capturedWhiteGameState)
            , test "when no pieces are captured, board remains unchanged" <|
                \_ ->
                    let
                        expectedEndBoard =
                            whiteGame.board

                        expectedNumCapturedPieces =
                            0
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces whiteGame)
            , test "layered captured pieces are removed from board" <|
                \_ ->
                    let
                        expectedEndBoard =
                            setPieceAt 8 white blackGame.board
                                |> setPieceAt 7 empty
                                |> setPieceAt 16 empty
                                |> setPieceAt 17 empty

                        expectedNumCapturedPieces =
                            3

                        capturedBlackGameState =
                            { whiteGame | board = setPieceAt 8 white whiteGame.board }
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces capturedBlackGameState)
            , test "captured group of multiple pieces are all removed from board" <|
                \_ ->
                    let
                        expectedEndBoard =
                            setPieceAt 7 empty whiteGame.board
                                |> setPieceAt 16 empty
                                |> setPieceAt 17 empty

                        expectedNumCapturedPieces =
                            4

                        capturedBlackGameState =
                            { whiteGame | board = setPieceAt 8 black whiteGame.board }
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces capturedBlackGameState)
            , test "double capture removes both captured pieces from board" <|
                \_ ->
                    let
                        expectedEndBoard =
                            setPieceAt 45 black blackGame.board
                                |> setPieceAt 46 empty
                                |> setPieceAt 54 empty

                        expectedNumCapturedPieces =
                            2

                        capturedWhiteGameState =
                            { blackGame | board = setPieceAt 45 black blackGame.board }
                    in
                    Expect.equal
                        ( expectedEndBoard, expectedNumCapturedPieces )
                        (removeCapturedPieces capturedWhiteGameState)
            , test "game end on double pass" <|
                \_ ->
                    let
                        game = playMove (Move.Pass Piece.WhiteStone) blackGame
                               |> playMove (Move.Pass Piece.BlackStone)
                    in
                    Expect.equal
                        True
                        (isGameEnded game)
            , test "game not ended on single pass" <|
                \_ ->
                    let
                        game = playMove (Move.Pass Piece.WhiteStone) blackGame
                               |> playMove (Move.Play Piece.BlackStone 0)
                    in
                    Expect.equal
                        False
                        (isGameEnded game)
            ]
        ]
