module Model.Game exposing (..)

import Array
import Json.Decode as Decode exposing (Decoder, int, list, string, nullable, bool)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import Model.Board as Board exposing (Board, BoardSize, emptyBoard, setPieceAt)
import Model.ColorChoice as ColorChoice exposing (ColorChoice(..))
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (Piece(..))
import Model.Score as Score exposing (Score)


type alias Game =
    { boardSize : BoardSize
    , board : Board
    , lastMoveWhite : Maybe Move
    , lastMoveBlack : Maybe Move
    , history : List Move
    , playerColor : ColorChoice
    , isOver : Bool
    , score : Score
    }


newGame : BoardSize -> ColorChoice -> Float -> Game
newGame size color komi =
    { boardSize = size
    , board = emptyBoard size
    , lastMoveWhite = Nothing
    , lastMoveBlack = Nothing
    , history = []
    , playerColor = color
    , isOver = False
    , score = Score.initWithKomi komi
    }


setScore : Score -> Game -> Game
setScore score game =
    { game | score = score }


setPlayerColor : ColorChoice -> Game -> Game
setPlayerColor color game =
    { game | playerColor = color }


setBoard : Board -> Game -> Game
setBoard board game =
    { game | board = board }


setIsOver : Bool -> Game -> Game
setIsOver flag game =
    { game | isOver = flag }


setLastMove : Move -> Game -> Game
setLastMove move game =
    case game.playerColor of
        ColorChoice.White ->
            { game | lastMoveWhite = Just move }

        ColorChoice.Black ->
            { game | lastMoveBlack = Just move }


{-| Note that because the moves are cons-ed
together, the history is the reverse order
of how the moves were actually played.
-}
addMoveToHistory : Move -> Game -> Game
addMoveToHistory move game =
    { game | history = move :: game.history }


getLastMove : Game -> Maybe Move
getLastMove game =
    case game.playerColor of
        ColorChoice.White ->
            game.lastMoveWhite

        ColorChoice.Black ->
            game.lastMoveBlack


{-| Debugging helper function for visualizing the board in tests
-}
printBoard : Game -> Game
printBoard game =
    let
        mapper p =
            case p of
                Piece.None ->
                    "_"

                Piece.BlackStone ->
                    "X"

                Piece.WhiteStone ->
                    "O"

        kernel : Game -> Board -> Game
        kernel g board =
            if Array.isEmpty board then
                let
                    _ =
                        Debug.log "<sep>" ""
                in
                g

            else
                let
                    len =
                        Board.boardSizeToInt game.boardSize

                    row =
                        Array.slice 0 len board

                    rest =
                        Array.slice len (Array.length board) board

                    _ =
                        Debug.log "" (Array.map mapper row)
                in
                kernel g rest
    in
    kernel game game.board


{-| The last move made should be made by the opponent
-}
isActiveTurn : Game -> Bool
isActiveTurn game =
    let
        lastMoveMade : List Move -> Maybe ColorChoice
        lastMoveMade moveHistory =
            case moveHistory of
                [] ->
                    Nothing
                lastMove :: tail ->
                    case lastMove of
                        Pass playerColor ->
                            Just playerColor
                        Play BlackStone _ ->
                            Just Black
                        Play WhiteStone _ ->
                            Just White
                        _ ->
                            -- this should never happen
                            Nothing

    in
    case lastMoveMade game.history of
        Nothing ->
            game.playerColor == Black
        Just color ->
            game.playerColor /= color


--- JSON coding

gameDecoder : Decoder Game
gameDecoder =
    Decode.succeed Game
        |> required "boardSize" Board.boardSizeDecoder
        |> required "board" Board.boardDecoder
        |> required "lastMoveWhite" (nullable Move.moveDecoder)
        |> required "lastMoveBlack" (nullable Move.moveDecoder)
        |> required "history" (list Move.moveDecoder)
        |> required "playerColor" ColorChoice.colorDecoder
        |> required "isOver" bool
        |> required "score" Score.scoreDecoder


