module Logic exposing (..)

import Board exposing (..)
import Html exposing (Html, text)
import Svg exposing (circle, svg)
import Svg.Attributes exposing (..)


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

        html =
            if piece == None then
                Html.text ""

            else
                svg
                    [ width "26", height "26", viewBox "0 0 26 26", style "position: absolute;" ]
                    [ circle [ cx "13", cy "13", r "11", fill fillColor ] [] ]
    in
    html
