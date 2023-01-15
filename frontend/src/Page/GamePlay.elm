module Page.GamePlay exposing (Model, Msg, init, isInnerCell, update, view)

import Array
import Board exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Logic exposing (..)
import Svg exposing (circle, svg)
import Svg.Attributes as SAtts


type Msg
    = PlacePiece Int


type alias Model =
    { boardSize : BoardSize
    , board : Board
    , lastMove : Maybe Int
    , playerColor : ColorChoice
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
            boardSizeToInt model.boardSize

        gridStyle =
            String.join " " (List.repeat intSize "auto")
    in
    div [ class "board", style "grid-template-columns" gridStyle ]
        (viewGameBoard model)


viewGameBoard : Model -> List (Html Msg)
viewGameBoard model =
    Array.toList
        (Array.indexedMap
            (viewBuildCell model.boardSize model.playerColor)
            model.board
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
    div [ class cellClass, onClick (PlacePiece index) ]
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
        PlacePiece index ->
            let
                ( moveIsValid, errorMessage ) =
                    validMove index model.board
            in
            if moveIsValid then
                ( { model
                    | board = placePiece model.playerColor index model.board
                    , lastMove = Just index
                    , playerColor = colorInverse model.playerColor -- TODO: remove w/ networking
                    , activeTurn = not model.activeTurn
                    , invalidMoveAlert = Nothing
                  }
                , endTurn model
                )

            else
                ( { model | invalidMoveAlert = errorMessage }
                , Cmd.none
                )


endTurn : Model -> Cmd Msg
endTurn model =
    -- TODO: placeholder turn swap w/o networking
    Cmd.none


placePiece : ColorChoice -> Int -> Board -> Board
placePiece color index board =
    let
        piece =
            case color of
                White ->
                    WhiteStone

                Black ->
                    BlackStone
    in
    setPieceAt index piece board



-- INIT --


init : BoardSize -> ColorChoice -> Model
init size color =
    initialModel size color


initialModel : BoardSize -> ColorChoice -> Model
initialModel boardSize colorChoice =
    { boardSize = boardSize
    , board = emptyBoard boardSize
    , lastMove = Nothing
    , playerColor = colorChoice
    , activeTurn = colorChoice == Black
    , invalidMoveAlert = Nothing
    }
