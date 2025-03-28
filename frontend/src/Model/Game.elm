module Model.Game exposing (..)

import Array
import Json.Decode as Decode exposing (Decoder, bool, int, list, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import JsonExtra
import Model.Board as Board exposing (Board, BoardSize, emptyBoard, setPieceAt)
import Model.ColorChoice as ColorChoice exposing (ColorChoice(..))
import Model.Move as Move exposing (Move(..))
import Model.Piece as Piece exposing (Piece(..))
import Model.Score as Score exposing (Score)


type alias Game =
    { boardSize : BoardSize
    , board : Board
    , history : List Move
    , playerColor : ColorChoice
    , isOver : Bool
    , score : Score
    , whitePlayerName : String
    , blackPlayerName : String
    , id : Maybe String
    }


newGame : BoardSize -> ColorChoice -> Float -> String -> String -> Game
newGame size color komi blackName whiteName =
    { boardSize = size
    , board = emptyBoard size
    , history = []
    , playerColor = color
    , isOver = False
    , score = Score.initWithKomi komi
    , blackPlayerName = blackName
    , whitePlayerName = whiteName
    , id = Nothing
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


{-| Note that because the moves are cons-ed
together, the history is the reverse order
of how the moves were actually played.
-}
addMoveToHistory : Move -> Game -> Game
addMoveToHistory move game =
    { game | history = move :: game.history }


getLastMoveWhite : Game -> Maybe Move
getLastMoveWhite game =
    let
        kernel : List Move -> Maybe Move
        kernel history =
            case history of
                [] ->
                    Nothing

                move :: historyTail ->
                    let
                        playerPiece =
                            case move of
                                Pass piece ->
                                    piece

                                Play piece _ ->
                                    piece
                    in
                    case playerPiece of
                        WhiteStone ->
                            Just move

                        _ ->
                            kernel historyTail
    in
    kernel game.history


getLastMoveBlack : Game -> Maybe Move
getLastMoveBlack game =
    let
        kernel : List Move -> Maybe Move
        kernel history =
            case history of
                [] ->
                    Nothing

                move :: historyTail ->
                    let
                        playerPiece =
                            case move of
                                Pass piece ->
                                    piece

                                Play piece _ ->
                                    piece
                    in
                    case playerPiece of
                        BlackStone ->
                            Just move

                        _ ->
                            kernel historyTail
    in
    kernel game.history


{-| Get last move made by the player matching `playerColor`
-}
getLastMove : Game -> Maybe Move
getLastMove game =
    case game.playerColor of
        ColorChoice.White ->
            getLastMoveWhite game

        ColorChoice.Black ->
            getLastMoveBlack game



{- Debugging helper function for visualizing the board in tests
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
-}


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
                        Pass WhiteStone ->
                            Just White

                        Pass BlackStone ->
                            Just Black

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
        |> required "history" (list Move.moveDecoder)
        |> required "playerColor" ColorChoice.colorDecoder
        |> required "isOver" bool
        |> required "score" Score.scoreDecoder
        |> required "whitePlayerName" string
        |> required "blackPlayerName" string
        |> required "id" (nullable string)


gameEncoder : Game -> Encode.Value
gameEncoder game =
    Encode.object
        [ ( "boardSize", Board.boardSizeEncoder game.boardSize )
        , ( "board", Board.boardEncoder game.board )
        , ( "history", Encode.list Move.moveEncoder game.history )
        , ( "playerColor", ColorChoice.colorEncoder game.playerColor )
        , ( "isOver", Encode.bool game.isOver )
        , ( "score", Score.scoreEncoder game.score )
        , ( "blackPlayerName", Encode.string game.blackPlayerName )
        , ( "whitePlayerName", Encode.string game.whitePlayerName )
        , ( "id", (Maybe.map Encode.string >> Maybe.withDefault Encode.null) game.id )
        ]
