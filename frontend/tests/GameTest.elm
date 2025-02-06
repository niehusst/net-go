module GameTest exposing (..)


import Expect exposing (Expectation)
import Json.Encode exposing (encode)
import Json.Decode exposing (decodeValue)
import Model.Game exposing (..)
import Model.Board exposing (BoardSize(..))
import Model.Piece exposing (Piece(..))
import Model.Move exposing (Move(..))
import Model.ColorChoice exposing (ColorChoice(..))
import Test exposing (..)


suite : Test
suite =
    describe "Game model"
        [ describe "isActiveTurn"
            [ test "black player has active turn in new game" <|
                \_ ->
                    let
                        game =
                            newGame Full Black 0.0
                    in
                    Expect.equal True (isActiveTurn game)
            , test "white player not active turn in new game" <|
                \_ ->
                    let
                        game =
                            newGame Full White 0.0
                    in
                    Expect.equal False (isActiveTurn game)
            , test "game with history determines correct active turn" <|
                \_ ->
                    let
                        game =
                            newGame Full Black 0.0
                                |> addMoveToHistory (Play BlackStone 0)
                                |> addMoveToHistory (Play WhiteStone 1)
                                |> addMoveToHistory (Play BlackStone 5)
                    in
                    Expect.equal False (isActiveTurn game)
            , test "active turn correct when last move was pass" <|
                \_ ->
                    let
                        game =
                            newGame Full Black 0.0
                                |> addMoveToHistory (Play BlackStone 0)
                                |> addMoveToHistory (Pass WhiteStone)
                    in
                    Expect.equal True (isActiveTurn game)
            , test "active turn correct when 2 passes in a row" <|
                \_ ->
                    let
                        game =
                            newGame Full White 0.0
                                |> addMoveToHistory (Play BlackStone 0)
                                |> addMoveToHistory (Pass WhiteStone)
                                |> addMoveToHistory (Pass BlackStone)
                    in
                    Expect.equal True (isActiveTurn game)
            , test "active turn correct when first move was pass" <|
                \_ ->
                    let
                        game =
                            newGame Full White 0.0
                                |> addMoveToHistory (Pass BlackStone)
                    in
                    Expect.equal True (isActiveTurn game)
            ]
            , describe "JSON coding"
              [ test "JSON coding works both ways" <|
                \_ ->
                    let
                        game =
                            newGame Full White 0.0
                                |> addMoveToHistory (Play BlackStone 0)
                                |> addMoveToHistory (Pass WhiteStone)
                                |> addMoveToHistory (Pass BlackStone)

                        encodedGame =
                            gameEncoder game

                        decodedGame =
                            decodeValue (gameDecoder) encodedGame
                    in
                    Expect.ok decodedGame
              ]
        ]
