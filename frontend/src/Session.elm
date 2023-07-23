module Session exposing (Session(..), init, navKey, toLoggedIn, toLoggedOut)

-- yoinked from https://github.com/rtfeldman/elm-spa-example/blob/master/src/Session.elm

import Browser.Navigation as Nav


type Session
    = LoggedIn Nav.Key
    | LoggedOut Nav.Key


navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key ->
            key

        LoggedOut key ->
            key


init : Nav.Key -> Session
init key =
    -- TODO: make capable of init both states (e.g. take input about existence of cookie?)
    LoggedOut key


toLoggedIn : Session -> Session
toLoggedIn session =
    LoggedIn (navKey session)


toLoggedOut : Session -> Session
toLoggedOut session =
    LoggedOut (navKey session)
