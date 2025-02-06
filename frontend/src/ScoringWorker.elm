module ScoringWorker exposing (main)

import Platform
import Random
import Json.Decode exposing (Value)
import Model.Game as Game
import Logic.Scoring exposing (scoreGame)
import ScoringPorts exposing (receiveSentGame, returnScoreGame, decodeGameFromValue)


type Msg
    = ScoreGame Game.Game Int
    | GenerateSeedForScoring Value


init : () -> ( (), Cmd msg )
init _ =
    ( (), Cmd.none )


update : Msg -> () -> ( (), Cmd Msg )
update msg _ =
    case msg of
        GenerateSeedForScoring encodedGame ->
            case decodeGameFromValue encodedGame of
                Ok game ->
                    ( ()
                    , Random.generate (ScoreGame game) (Random.int 0 42069)
                    )
                Err error ->
                    -- local JSON communication encoding error should never happen...
                    -- there's not much we can do from here either w/o added extra JSON
                    -- data/error field structure around game
                    ( ()
                    , Cmd.none
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

