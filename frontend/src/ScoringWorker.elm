port module ScoringWorker exposing (main)

import Platform
import Model.Game as Game


type Msg
    = ScoreGame Game.Game -- TODO: json encode


init : () -> ( (), Cmd msg )
init _ =
    ( (), Cmd.none )


update : Msg -> () -> ( (), Cmd msg )
update msg _ =
    case msg of
        Increment int ->
            ( (), sendCount (int + 1) )

        Decrement int ->
            ( (), sendCount (int - 1) )


subscriptions : () -> Sub Msg
subscriptions _ =
    Sub.batch
        [ scoreGame ScoreGame
        ]


main : Program () () Msg
main =
    Platform.worker { init = init
                    , update = update
                    , subscriptions = subscriptions
                    }


-- TODO: json encoded game
port scoreGame : (Int -> msg) -> Sub msg


port sendScoredGame : Int -> Cmd msg
