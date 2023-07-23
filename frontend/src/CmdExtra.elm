module CmdExtra exposing (message)

-- yoinked from https://github.com/shmookey/cmd-extra/blob/1.0.0/src/Cmd/Extra.elm

import Task


{-| A command to generate a message without performing any action.
(i.e. send a Msg to your own update function)

This is useful for implementing components that generate events in the manner
of HTML elements, but where the event fires from within Elm code, rather than
by an external trigger.

-}
message : msg -> Cmd msg
message x =
    Task.perform identity (Task.succeed x)
