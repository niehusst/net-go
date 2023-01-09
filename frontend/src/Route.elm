module Route exposing (Route(..), parseUrl, pushUrl, routeToString)

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser exposing (..)


type Route
    = NotFound
    | Home
    | GameCreate
    | GamePlay


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Home top
        , map GameCreate (s "game" </> s "create")
        , map GamePlay (s "game") -- TODO: set game code
        ]


parseUrl : Url -> Route
parseUrl url =
    case parse matchRoute url of
        Just route ->
            route

        Nothing ->
            NotFound


pushUrl : Route -> Nav.Key -> Cmd msg
pushUrl route navKey =
    routeToString route
        |> Nav.pushUrl navKey


routeToString : Route -> String
routeToString route =
    case route of
        NotFound ->
            "/route-not-found"

        Home ->
            "/"

        GameCreate ->
            "/game/create"

        GamePlay ->
            -- TODO: dont forget to change this too
            "/game"
