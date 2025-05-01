module Page.GameCreate exposing (FormData, Model, Msg(..), init, update, view)

import API.Games exposing (CreateGameResponse, createGame)
import Browser.Navigation as Nav
import CmdExtra exposing (message)
import Error exposing (HttpErrorResponse)
import Html exposing (..)
import Html.Attributes exposing (class, href, min, selected, step, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Model.Board as Board exposing (BoardSize(..), boardSizeToInt, boardSizeToString, intToBoardSize)
import Model.ColorChoice exposing (ColorChoice(..), colorToString, stringToColor)
import Model.Game as Game exposing (Game)
import Model.Score as Score
import Route exposing (Route, pushUrl)
import Session
import View.Error exposing (viewHttpError)


type Msg
    = StoreBoardSize String
    | StoreColorChoice String
    | StoreKomi String
    | StoreOpponentName String
    | CreateGame -- http req msgs for creating game in db
    | GameCreated (Result HttpErrorResponse CreateGameResponse)


type alias Model =
    { formData : FormData
    , navKey : Nav.Key
    , userData : Session.UserData
    , httpError : Maybe HttpErrorResponse
    }


type alias FormData =
    { boardSize : BoardSize
    , colorChoice : ColorChoice
    , komi : Float
    , opponentName : String
    }


setOpponentName : String -> FormData -> FormData
setOpponentName name data =
    { data | opponentName = name }


setSize : BoardSize -> FormData -> FormData
setSize size data =
    { data | boardSize = size }


setColor : ColorChoice -> FormData -> FormData
setColor color data =
    { data | colorChoice = color }


setKomi : Float -> FormData -> FormData
setKomi komi data =
    { data | komi = komi }


formDataToGame : FormData -> Session.UserData -> Game
formDataToGame formData userData =
    let
        username =
            userData.username

        ( whitePlayerName, blackPlayerName ) =
            case formData.colorChoice of
                White ->
                    ( username, formData.opponentName )

                Black ->
                    ( formData.opponentName, username )
    in
    { boardSize = formData.boardSize
    , board = Board.emptyBoard formData.boardSize
    , history = []
    , playerColor = formData.colorChoice
    , isOver = False
    , score = Score.initWithKomi formData.komi
    , whitePlayerName = whitePlayerName
    , blackPlayerName = blackPlayerName
    , id = Nothing -- no db id yet; that will gen on backend
    }



-- VIEW --


view : Model -> Html Msg
view model =
    div [ class "flex flex-col items-center justify-center p-9 gap-3" ]
        [ h2 [ class "text-xl" ] [ text "Game Settings" ]
        , viewHttpError model.httpError
        , viewGameSettings model.formData
        ]


viewGameSettings : FormData -> Html Msg
viewGameSettings data =
    div [ class "container flex justify-center" ]
        [ div [ class "w-full flex flex-col gap-3" ]
            [ div [ class "w-full" ]
                [ label [ class "block text-sm font-medium text-gray-900" ] [ text "Color" ]
                , select
                    [ onInput StoreColorChoice
                    , class "w-full appearance-none rounded-md bg-white py-1.5 pr-8 pl-3 text-base text-gray-900 border border-gray-300 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6"
                    ]
                    (List.map
                        (\color ->
                            option
                                [ value (colorToString color)
                                , selected (data.colorChoice == color)
                                ]
                                [ text (colorToString color) ]
                        )
                        [ Black, White ]
                    )
                ]
            , div []
                [ label [ class "block text-sm font-medium text-gray-900" ] [ text "Board size" ]
                , select
                    [ onInput StoreBoardSize
                    , class "w-full appearance-none rounded-md bg-white py-1.5 pr-8 pl-3 text-base text-gray-900 border border-gray-300 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6"
                    ]
                    (List.map
                        (\size ->
                            option
                                [ value (String.fromInt <| boardSizeToInt size)
                                , selected (data.boardSize == size)
                                ]
                                [ text (boardSizeToString size) ]
                        )
                        [ Full, Medium, Small ]
                    )
                ]
            , div []
                [ label [ class "block text-sm font-medium text-gray-900" ] [ text "Komi" ]
                , input
                    [ onInput StoreKomi
                    , type_ "number"
                    , class "w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 border border-gray-300 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6"
                    , step "0.1"
                    , Html.Attributes.min "0"
                    , value (String.fromFloat data.komi)
                    ]
                    []
                ]
            , div []
                [ label [ class "block text-sm font-medium text-gray-900" ] [ text "Opponent username" ]
                , input
                    [ onInput StoreOpponentName
                    , type_ "text"
                    , class "w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 border border-gray-300 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6"
                    , Html.Attributes.required True
                    , value data.opponentName
                    ]
                    []
                ]
            , button
                [ class "btn"
                , onClick CreateGame
                ]
                [ text "Create game" ]
            ]
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StoreOpponentName nameStr ->
            ( { model | formData = setOpponentName nameStr model.formData }
            , Cmd.none
            )

        StoreKomi komiStr ->
            let
                value =
                    String.toFloat komiStr
            in
            case value of
                Just komi ->
                    ( { model | formData = setKomi komi model.formData }
                    , Cmd.none
                    )

                Nothing ->
                    ( model
                    , Cmd.none
                    )

        StoreBoardSize sizeStr ->
            let
                value =
                    String.toInt sizeStr
            in
            case value of
                Just candidateSizeInt ->
                    let
                        candidateSize =
                            intToBoardSize candidateSizeInt
                    in
                    case candidateSize of
                        Just boardSize ->
                            ( { model | formData = setSize boardSize model.formData }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model
                            , Cmd.none
                            )

                Nothing ->
                    ( model
                    , Cmd.none
                    )

        StoreColorChoice colorStr ->
            case stringToColor colorStr of
                Just colorChoice ->
                    ( { model | formData = setColor colorChoice model.formData }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        CreateGame ->
            ( { model | httpError = Nothing }
            , createGame (formDataToGame model.formData model.userData) GameCreated
            )

        GameCreated (Ok createdResponse) ->
            ( model
            , pushUrl (Route.GamePlay <| String.fromInt createdResponse.uid) model.navKey
            )

        GameCreated (Err httpErr) ->
            ( { model | httpError = Just httpErr }
            , Cmd.none
            )



-- INIT --


init : Nav.Key -> Session.UserData -> ( Model, Cmd Msg )
init navKey userData =
    ( initialModel navKey userData
    , Cmd.none
    )


initialModel : Nav.Key -> Session.UserData -> Model
initialModel navKey userData =
    { formData =
        { boardSize = Full
        , colorChoice = Black
        , komi = 6.5 -- current Japanese regulation komi
        , opponentName = ""
        }
    , navKey = navKey
    , userData = userData
    , httpError = Nothing
    }
