module Page.GamePlay exposing (Model, Msg, init, isInnerCell, update, view)

import Array
import Board exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Logic exposing (..)


type Msg
    = PlacePiece Int


type alias Model =
    { boardSize : BoardSize
    , board : Board
    , lastMove : Maybe Int
    , playerColor : ColorChoice
    }



-- VIEW --


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "Goban state" ]
        , viewBuildBoard model
        ]


viewBuildBoard : Model -> Html Msg
viewBuildBoard model =
    let
        intSize =
            boardSizeToInt model.boardSize

        gridStyle =
            String.join " " (List.repeat intSize "auto")
    in
    -- border offset, svg, second layer of views w/ z index
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
    -- TODO: piece hover ghost
    div [ class cellClass, onClick (PlacePiece index) ]
        [ pieceHtml
        , div [ class hoverClass ] []
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlacePiece index ->
            ( { model
                | board = placePiece model.playerColor index model.board
                , lastMove = Just index
                , playerColor = colorInverse model.playerColor -- TODO: remove w/ networking
              }
            , endTurn model
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
    }
