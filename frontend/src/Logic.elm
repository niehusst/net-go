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
                    [ width "10", height "10", viewBox "0 0 13 13" ]
                    [ circle [ cx "5", cy "5", r "5", fill fillColor ] [] ]
    in
    html
