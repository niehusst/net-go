module LogicTests exposing (..)

import Logic exposing (..)


suite : Test
suite =
    describe "Game Logic"
        [ describe "validMove"
            [ todo "ko rule"
            , todo "basic suicide is illegal"
            , todo "layered suicide is illegal"
            , todo "suicide to capture is legal"
            , todo "layered suicide to capture internal is legal"
            , todo "playing on top of another piece is illegal"
            ]
        ]
