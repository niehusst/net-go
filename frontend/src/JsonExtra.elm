module JsonExtra exposing (..)

import Json.Encode as Encode


encodeMaybe : (t -> Encode.Value) -> Maybe t -> Encode.Value
encodeMaybe encoder maybeValue =
    case maybeValue of
        Just val ->
            encoder val

        Nothing ->
            Encode.null
