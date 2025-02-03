module ScoringWorker exposing (main)

import Platform
import Random
import Model.Game as Game
import Logic.Scoring exposing (scoreGame)
import ScoringPorts exposing (receiveSentGame, returnScoreGame)


type Msg
    = ScoreGame Game.Game Int -- TODO: json encode
    | GenerateSeedForScoring Game.Game


init : () -> ( (), Cmd msg )
init _ =
    ( (), Cmd.none )


update : Msg -> () -> ( (), Cmd Msg )
update msg _ =
    case msg of
        GenerateSeedForScoring game ->
           ( ()
           , Random.generate (ScoreGame game) (Random.int 0 42069)
           )
        ScoreGame game seed ->
            let
                finalScore =
                    scoreGame game seed

                completedGame =
                    Game.setScore finalScore game
                        |> Game.setIsOver True
            in
            ( ()
            , returnScoreGame (Game.gameEncoder completedGame)
            )


subscriptions : () -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveSentGame GenerateSeedForScoring
        ]


main : Program () () Msg
main =
    Platform.worker { init = init
                    , update = update
                    , subscriptions = subscriptions
                    }

