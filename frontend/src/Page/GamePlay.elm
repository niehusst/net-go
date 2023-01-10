module Page.GamePlay exposing (Model, init, view)

import Array
import Board exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, style)


type alias Model =
    { boardSize : BoardSize
    , board : Board
    , lastMove : Maybe ( Int, Int )
    , playerColor : ColorChoice
    }



-- VIEW --


view : Model -> Html msg
view model =
    div []
        [ h3 [] [ text "here it is:" ]
        , viewBuildBoard model
        ]


viewBuildBoard : Model -> Html msg
viewBuildBoard model =
    let
        intSize =
            boardSizeToInt model.boardSize

        gridStyle =
            String.join " " (List.repeat intSize "auto")
    in
    -- border offset, svg, second layer of views w/ z index
    div [ class "board", style "grid-template-columns" gridStyle ]
        (Array.toList
            (Array.indexedMap
                (viewBuildCell model.boardSize)
                model.board
            )
        )


viewBuildCell : BoardSize -> Int -> Piece -> Html msg
viewBuildCell size index piece =
    -- TODO: totally not working
    let
        intSize =
            boardSizeToInt size

        isLastRow =
            index >= intSize * (intSize - 1)

        isLastCol =
            remainderBy (index + 1) intSize == 0

        isInner =
            not (isLastRow || isLastCol)
    in
    viewCell piece isInner


viewCell : Piece -> Bool -> Html msg
viewCell piece isInner =
    let
        cssClass =
            if isInner then
                "board-square inner-board-square"

            else
                "board-square"
    in
    -- TODO: piece image + hover
    div [ class cssClass ] []



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
