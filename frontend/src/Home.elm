module Home exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)


view model =
    div [ class "jumbotron" ]
        [ h1 [] [ text "Play Go online with a friend!" ]
        , p []
            [ text "It's pretty "
            , strong [] [ text "FUN." ]
            , text <|
                """ 
                More functionality coming soon.
                """
            ]
        ]


main =
    view "dummy model"
