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
            abs (score.blackPoints - (score.whitePoints + score.komi))
    in
    if score.isForfeit then
        -- TODO: indicate who won (by forfeit)
        "Forfeit"

    else if score.blackPoints > score.whitePoints then
        "B+" ++ String.fromFloat scoreDiff

    else if score.blackPoints < score.whitePoints then
        "W+" ++ String.fromFloat scoreDiff

    else
        "Draw"


increaseWhitePoints : Float -> Score -> Score
increaseWhitePoints points score =
    { score | whitePoints = score.whitePoints + points }


increaseBlackPoints : Float -> Score -> Score
increaseBlackPoints points score =
    { score | blackPoints = score.blackPoints + points }
