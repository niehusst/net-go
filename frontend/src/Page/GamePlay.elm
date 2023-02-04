module Page.GamePlay exposing (Model, Msg, init, isInnerCell, update, view)

import Array
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Logic exposing (..)
import Model.Board as Board exposing (..)
import Model.Game as Game exposing (..)
import Model.Move as Move exposing (..)
import Model.Piece as Piece exposing (..)
import Svg exposing (circle, svg)
import Svg.Attributes as SAtts


type Msg
    = PlayPiece Int
    | PlayPass


type alias Model =
    { game : Game
    , activeTurn : Bool
    , invalidMoveAlert : Maybe String
    }



-- VIEW --


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "Goban state" ]
        , viewBuildBoard model
        , viewWaitForOpponent model.activeTurn
        , div []
            [ button [ onClick PlayPass ] [ text "Pass" ] ]
        , viewAlert model.invalidMoveAlert
        ]


viewAlert : Maybe String -> Html Msg
viewAlert error =
    case error of
        Nothing ->
            text ""

        Just errorMessage ->
            text ("Invalid move: " ++ errorMessage)


viewWaitForOpponent : Bool -> Html Msg
viewWaitForOpponent activeTurn =
    if activeTurn then
        text ""

    else
        text "Wait for opponent to play..."


viewBuildBoard : Model -> Html Msg
viewBuildBoard model =
    let
        intSize =
            boardSizeToInt model.game.boardSize

        gridStyle =
            String.join " " (List.repeat intSize "auto")
    in
    div [ class "board", style "grid-template-columns" gridStyle ]
        (viewGameBoard model)


viewGameBoard : Model -> List (Html Msg)
viewGameBoard model =
    Array.toList
        (Array.indexedMap
            (viewBuildCell model.game.boardSize model.game.playerColor)
            model.game.board
        )


{-| determines if cell position `index` is not going
to be on the outer right or bottom edges of the game
board (when rendered in 2D grid instead of flat array).
-}
isInnerCell : BoardSize -> Int -> Bool
isInnerCell boardSize index =
    let
        intSize =
            boardSizeToInt boardSize

        isLastRow =
            index >= intSize * (intSize - 1)

        isLastCol =
            remainderBy intSize (index + 1) == 0
    in
    not (isLastRow || isLastCol)


viewBuildCell : BoardSize -> ColorChoice -> Int -> Piece -> Html Msg
viewBuildCell boardSize color index piece =
    let
        pieceHtml =
            renderPiece piece

        hoverClass =
            "hidden-hover-element board-square-" ++ colorToString color

        cellClass =
            if isInnerCell boardSize index then
                "board-square inner-board-square"

            else
                "board-square"
    in
    div [ class cellClass, onClick (PlayPiece index) ]
        [ pieceHtml
        , div [ class hoverClass ] []
        ]


renderPiece : Piece -> Html msg
renderPiece piece =
    let
        fillColor =
            case piece of
                BlackStone ->
                    "black"

                WhiteStone ->
                    "white"

                None ->
                    ""
    in
    if piece == None then
        text ""

    else
        svg
            [ SAtts.width "26"
            , SAtts.height "26"
            , SAtts.viewBox "0 0 26 26"
            , SAtts.style "position: absolute;"
            ]
            [ circle
                [ SAtts.cx "13"
                , SAtts.cy "13"
                , SAtts.r "11"
                , SAtts.fill fillColor
                ]
                []
            ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayPiece index ->
            let
                move =
                    Move.Play (colorToPiece model.game.playerColor) index

                ( moveIsValid, errorMessage ) =
                    validMove move model.game
            in
            if moveIsValid then
                ( { model
                    | game =
                        playMove move model.game
                            |> setPlayerColor (colorInverse model.game.playerColor)

                    -- TODO: remove color swap w/ networking
                    , activeTurn = not model.activeTurn
                    , invalidMoveAlert = Nothing
                  }
                , endTurn model
                )

            else
                ( { model | invalidMoveAlert = errorMessage }
                , Cmd.none
                )

        PlayPass ->
            -- TODO remove color swap w/ networking
            ( { model
                | activeTurn = not model.activeTurn
                , invalidMoveAlert = Nothing
                , game =
                    passTurn model.game
                        |> setPlayerColor (colorInverse model.game.playerColor)
              }
            , endTurn model
            )


passTurn : Game.Game -> Game.Game
passTurn game =
    setLastMove Move.Pass game
        |> addMoveToHistory Move.Pass


endTurn : Model -> Cmd Msg
endTurn model =
    -- TODO: placeholder turn swap w/o networking
    Cmd.none


playMove : Move.Move -> Game.Game -> Game.Game
playMove move game =
    case move of
        Move.Pass ->
            setLastMove move (addMoveToHistory move game)

        Move.Play piece position ->
            let
                gameBoardWithMove =
                    { game | board = setPieceAt position piece game.board }

                ( boardWithoutCapturedPieces, scoredPoints ) =
                    removeCapturedPieces gameBoardWithMove

                -- TODO update your score once that exists
            in
            { game
                | lastMove = Just move
                , board = boardWithoutCapturedPieces
                , history = move :: game.history
            }



-- INIT --


init : BoardSize -> ColorChoice -> Model
init size color =
    initialModel size color


initialModel : BoardSize -> ColorChoice -> Model
initialModel boardSize colorChoice =
    { game = newGame boardSize colorChoice
    , activeTurn = colorChoice == Black
    , invalidMoveAlert = Nothing
    }
