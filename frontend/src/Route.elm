module Route exposing (Route(..), parseUrl, pushUrl, routeToString)

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser exposing (Parser, (</>), string, map, oneOf, s, top, parse)


type Route
    = NotFound
    | Home
    | GameCreate
    | GamePlay String -- game ID
    | SignUp
    | SignIn


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Home top
        , map GameCreate (s "game" </> s "create")
        , map GamePlay (s "game" </> string)
        , map SignUp (s "signup")
        , map SignIn (s "signin")
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
            "/"

        Home ->
            "/"

        GameCreate ->
            "/game/create"

        GamePlay gameId ->
            "/game/" ++ gameId

        SignUp ->
            "/signup"

        SignIn ->
            "/signin"
