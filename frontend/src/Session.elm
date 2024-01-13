module Session exposing (Session(..), fromCookie, init, navKey, toLoggedIn, toLoggedOut)

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
    LoggedOut key


fromCookie : Bool -> Nav.Key -> Session
fromCookie isAuthed key =
    if isAuthed then
        LoggedIn key

    else
        LoggedOut key


toLoggedIn : Session -> Session
toLoggedIn session =
    LoggedIn (navKey session)


toLoggedOut : Session -> Session
toLoggedOut session =
    LoggedOut (navKey session)
