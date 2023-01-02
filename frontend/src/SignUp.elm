module SignUp exposing (User)

-- TODO: come back to this exporet

import Html exposing (..)
import Html.Attributes exposing (..)


type alias User =
    { username : String
    , password : String
    }


initialModel : User
initialModel =
    { username = ""
    , password = ""
    }


view : User -> Html msg
view model =
    div [ class "TODO css here" ]
        [ h1 [] [ text "Sign Up" ]
        , Html.form []
            [ div []
                [ text "Username"
                , input
                    [ id "username"
                    , type_ "text"
                    , onInput SaveUsername
                    ]
                    []
                ]
            , div []
                [ text "Password"
                , input
                    [ id "password"
                    , type_ "password"
                    , onInput SavePassword
                    ]
                    []
                ]
            , div []
                [ button [ type_ "submit", onClick Signup ]
                    [ text "Create Account" ]
                ]
            ]
        ]


type Action
    = Signup
    | SaveUsername String
    | SavePassword String


update : Action -> User -> User
update action model =
    case action of
        SaveUsername username ->
            { model | username = username }

        SavePassword password ->
            { model | password = password }

        Signup ->
            { username | username = "" }



-- TODO: network req


main : Program () User Action
main =
    Browser.sandbox
        { init = initialMOdel
        , view = view
        , update = update
        }
