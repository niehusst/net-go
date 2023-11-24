module Model.Score exposing (Score, increaseBlackPoints, increaseWhitePoints, initWithKomi, isForfeit, scoreToString, winningColor)

import Model.ColorChoice as ColorChoice exposing (ColorChoice(..))


type alias Score =
    { blackForfeit : Bool
    , whiteForfeit : Bool
    , blackPoints : Float
    , whitePoints : Float
    , komi : Float
    }


initWithKomi : Float -> Score
initWithKomi komi =
    { blackForfeit = False
    , whiteForfeit = False
    , blackPoints = 0.0
    , whitePoints = 0.0
    , komi = komi
    }


{-| Returns the difference between player scores.
A positive value means Black victory, a negative White victory.
-}
calcScoreDiff : Score -> Float
calcScoreDiff score =
    score.blackPoints - (score.whitePoints + score.komi)


scoreToString : Score -> String
scoreToString score =
    let
        scoreDiff =
            calcScoreDiff score

        displayScore =
            abs scoreDiff
    in
    if isForfeit score then
        if score.blackForfeit then
            "W [Black Forfeit]"

        else
            "B [White Forfeit]"

    else
        case winningColor score of
            Just ColorChoice.Black ->
                "B+" ++ String.fromFloat displayScore

            Just ColorChoice.White ->
                "W+" ++ String.fromFloat displayScore

            Nothing ->
                "Draw"


isForfeit : Score -> Bool
isForfeit score =
    score.blackForfeit || score.whiteForfeit


{-| Returns Just the winning color, or Nothing on a draw.
-}
winningColor : Score -> Maybe ColorChoice
winningColor score =
    let
        scoreDiff =
            calcScoreDiff score

        blackVictory =
            scoreDiff > 0

        whiteVictory =
            scoreDiff < 0
    in
    case ( blackVictory, whiteVictory ) of
        ( True, False ) ->
            Just ColorChoice.Black

        ( False, True ) ->
            Just ColorChoice.White

        _ ->
            Nothing


increaseWhitePoints : Float -> Score -> Score
increaseWhitePoints points score =
    { score | whitePoints = score.whitePoints + points }


increaseBlackPoints : Float -> Score -> Score
increaseBlackPoints points score =
    { score | blackPoints = score.blackPoints + points }
