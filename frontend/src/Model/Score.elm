module Model.Score exposing (..)


type alias Score =
    { isForfeit : Bool
    , blackPoints : Float
    , whitePoints : Float
    , komi : Float
    }


initWithKomi : Float -> Score
initWithKomi komi =
    { isForfeit = False
    , blackPoints = 0.0
    , whitePoints = 0.0
    , komi = komi
    }


scoreToString : Score -> String
scoreToString score =
    let
        scoreDiff =
            score.blackPoints - (score.whitePoints + score.komi)

        blackVictory =
            scoreDiff > 0

        whiteVictory =
            scoreDiff < 0

        displayScore =
            abs scoreDiff
    in
    case ( score.isForfeit, blackVictory, whiteVictory ) of
        ( True, _, _ ) ->
            -- TODO: tell who forfeit (add whiteForfeit and blackForfeit fields to Score?)
            "Forfeit"

        ( False, True, False ) ->
            "B+" ++ String.fromFloat displayScore

        ( False, False, True ) ->
            "W+" ++ String.fromFloat displayScore

        _ ->
            "Draw"


increaseWhitePoints : Float -> Score -> Score
increaseWhitePoints points score =
    { score | whitePoints = score.whitePoints + points }


increaseBlackPoints : Float -> Score -> Score
increaseBlackPoints points score =
    { score | blackPoints = score.blackPoints + points }
