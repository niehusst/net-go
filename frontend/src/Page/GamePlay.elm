module Page.GamePlay exposing (Model, buildCssClasses, init, view)

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
        (viewGameBoard <| buildCssClasses model)


viewGameBoard : List String -> List (Html msg)
viewGameBoard cssClasses =
    List.map (\cssClass -> div [ class cssClass ] []) cssClasses


buildCssClasses : Model -> List String
buildCssClasses model =
    Array.toList
        (Array.indexedMap
            (generateCssClass (boardSizeToInt model.boardSize))
            model.board
        )


{-| determines if cell position `index` is not going
to be on the outer right or bottom edges of the game
board (when rendered in 2D grid instead of flat array).
-}
isInnerCell : Int -> Int -> Bool
isInnerCell boardSize index =
    let
        isLastRow =
            index >= boardSize * (boardSize - 1)

        isLastCol =
            remainderBy boardSize (index + 1) == 0
    in
    not (isLastRow || isLastCol)


generateCssClass : Int -> Int -> Piece -> String
generateCssClass boardSize index piece =
    let
        cssClass =
            if isInnerCell boardSize index then
                "board-square inner-board-square"

            else
                "board-square"
    in
    -- TODO: piece image + hover ghost
    cssClass



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
