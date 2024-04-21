module Model.Score exposing (Score, increaseBlackPoints, increaseWhitePoints, initWithKomi, isForfeit, scoreToString, winningColor, scoreDecoder, scoreEncoder)

import Model.ColorChoice as ColorChoice exposing (ColorChoice(..))
import Json.Decode as Decode exposing (Decoder, float, nullable)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode
import JsonExtra

type alias Score =
    { forfeitColor : Maybe ColorChoice
    , blackPoints : Float
    , whitePoints : Float
    , komi : Float
    }


initWithKomi : Float -> Score
initWithKomi komi =
    { forfeitColor = Nothing
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
    case score.forfeitColor of
        Just ColorChoice.Black ->
            "W [Black Forfeit]"

        Just ColorChoice.White ->
            "B [White Forfeit]"

        Nothing ->
            case winningColor score of
                Just ColorChoice.Black ->
                    "B+" ++ String.fromFloat displayScore

                Just ColorChoice.White ->
                    "W+" ++ String.fromFloat displayScore

                Nothing ->
                    "Draw"


isForfeit : Score -> Bool
isForfeit score =
    case score.forfeitColor of
        Just _ ->
            True
        Nothing ->
            False


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

--- JSON

scoreDecoder : Decoder Score
scoreDecoder =
    Decode.succeed Score
        |> required "forfeitColor" (nullable ColorChoice.colorDecoder)
        |> required "blackPoints" float
        |> required "whitePoints" float
        |> required "komi" float

scoreEncoder : Score -> Encode.Value
scoreEncoder score =
    Encode.object
        [ ("forfeitColor", JsonExtra.encodeMaybe (ColorChoice.colorEncoder) score.forfeitColor)
        , ("blackPoints", Encode.float score.blackPoints)
        , ("whitePoints", Encode.float score.whitePoints)
        , ("komi", Encode.float score.komi)
        ]
