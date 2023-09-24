module ListExtra exposing (..)

import Random
import Debug

getAt : List a -> Int -> Maybe a
getAt lst idx =
    let
        kernel : List a -> Int -> Int -> Maybe a
        kernel list index pos =
            case list of
                [] ->
                    Nothing
                x :: xs ->
                    if index == pos then
                        Just x
                    else
                        kernel xs index (pos + 1)
    in
    kernel lst idx 0

removeAt : List a -> Int -> List a
removeAt lst idx =
    let
        kernel : List a -> Int -> Int -> List a -> List a
        kernel list index pos result =
            case list of
                [] ->
                    result
                x :: xs ->
                    if index == pos then
                        kernel list index (pos + 1) result
                    else
                        kernel list index (pos + 1) (x :: result)
    in
    List.reverse (kernel lst idx 0 [])


shuffle : Int -> List a -> List a
shuffle seedInt list =
    let
        initialSeed =
            Random.initialSeed seedInt


        kernel : Random.Seed -> List a -> List a -> List a
        kernel seed source result =
            if List.isEmpty source then
                result
            else
                let
                    indexGenerator =
                        Random.int 0 ((List.length source) - 1)

                    ( index, nextSeed ) =
                        Random.step indexGenerator seed

                    valAtIndex =
                        getAt source index

                    sourceWithoutIndex =
                        removeAt source index
                in
                    case valAtIndex of
                        Just val ->
                            kernel nextSeed sourceWithoutIndex (val :: result)

                        Nothing ->
                            -- should never get here, generated an index outside list
                            result
    in
    kernel initialSeed list []
