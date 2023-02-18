module Model.Score exposing (..)


type alias Score =
    { isForfeit : Bool
    , blackPoints : Float
    , whitePoints : Float
    }


initWithKomi : Float -> Score
initWithKomi komi =
    { isForfeit = False
    , blackPoints = 0.0
    , whitePoints = komi
    }


scoreToString : Score -> String
scoreToString score =
    let
        scoreDiff =
            abs (score.blackPoints - score.whitePoints)
    in
    if score.isForfeit then
        "Forfeit"

    else if score.blackPoints > score.whitePoints then
        "B+" ++ String.fromFloat scoreDiff

    else if score.blackPoints < score.whitePoints then
        "W+" ++ String.fromFloat scoreDiff

    else
        "Draw"
