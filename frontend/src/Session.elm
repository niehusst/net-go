module Session exposing (Session(..), fromCookie, init, navKey, toLoggedIn, toLoggedOut, UserData)

-- yoinked from https://github.com/rtfeldman/elm-spa-example/blob/master/src/Session.elm

import Browser.Navigation as Nav

type alias UserData =
    { id : Int
    , username : String
    }

type Session
    = LoggedIn Nav.Key UserData
    | LoggedOut Nav.Key


navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key _ ->
            key

        LoggedOut key ->
            key


init : Nav.Key -> Session
init key =
    LoggedOut key


fromCookie : Maybe UserData -> Nav.Key -> Session
fromCookie maybeData key =
    case maybeData of
        Just userData ->
            LoggedIn key userData

        Nothing ->
            LoggedOut key


toLoggedIn : UserData -> Session -> Session
toLoggedIn userData session =
    LoggedIn (navKey session) userData


toLoggedOut : Session -> Session
toLoggedOut session =
    LoggedOut (navKey session)
