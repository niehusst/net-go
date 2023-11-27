module Page.GameCreate exposing (Model, FormData, Msg(..), init, update, view)

import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (href, value, selected, type_, step, min)
import Html.Events exposing (onClick, onInput)
import Http
import CmdExtra exposing (message)
import Model.Board exposing (BoardSize(..), boardSizeToString, boardSizeToInt)
import Model.ColorChoice exposing (ColorChoice(..), colorToString)
import Route exposing (Route, pushUrl)

type alias Model =
    { formData : FormData
    , navKey : Nav.Key
    }


type alias FormData =
    { boardSize : BoardSize
    , colorChoice : ColorChoice
    , komi : Float
    }

setSize : BoardSize -> FormData -> FormData
setSize size data =
    { data | boardSize = size }

setColor : ColorChoice -> FormData -> FormData
setColor color data =
    { data | colorChoice = color }

setKomi : Float -> FormData -> FormData
setKomi komi data =
    { data | komi = komi }

type Msg
    = StoreBoardSize String
    | StoreColorChoice String
    | StoreKomi String
    | CreateGame -- http req msgs for creating game in db
    | GameCreated (Result Http.Error FormData)
    | SendFormDataToMain FormData



-- VIEW --


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "Game Settings" ]
        , viewGameSettings model.formData
        ]


viewGameSettings : FormData -> Html Msg
viewGameSettings data =
    let
        black = colorToString Black

        white = colorToString White

        full = boardSizeToString Full

        med = boardSizeToString Medium

        small = boardSizeToString Small
    in
    div []
        [ Html.form []
              [ div []
                    [ label [] [ text "Color" ]
                    , select [ onInput StoreColorChoice ]
                        [ option
                              [ value black
                              , selected (data.colorChoice == Black)
                              ]
                              [ text black ]
                        , option
                              [ value white
                              , selected (data.colorChoice == White)
                              ]
                              [ text white ]
                        ]
                    ]
              , div []
                    [ label [] [ text "Board size" ]
                    , select [ onInput StoreBoardSize ]
                             [ option [ value (String.fromInt <| boardSizeToInt Full)
                                      , selected (data.boardSize == Full)
                                      ]
                                      [ text full ]
                             , option [ value (String.fromInt <| boardSizeToInt Medium)
                                      , selected (data.boardSize == Medium)
                                      ]
                                      [ text med ]
                             , option [ value (String.fromInt <| boardSizeToInt Small)
                                      , selected (data.boardSize == Small)
                                      ]
                                      [ text small ]
                             ]
                    ]
              , div []
                    [ label [] [ text "Komi" ]
                    , input [ onInput StoreKomi
                            , type_ "number"
                            , step "0.1"
                            , Html.Attributes.min "0"
                            , value (String.fromFloat data.komi)
                            ]
                            []
                    ]
              , button [ onClick CreateGame ]
                       [ text "Create game" ]
              ]
        ]



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StoreKomi komiStr ->
            let
                value = String.toFloat komiStr
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
                value = String.toInt sizeStr
            in
            case value of
                Just candidateSize ->
                    if candidateSize == boardSizeToInt Full then
                        ( { model | formData = setSize Full model.formData }
                        , Cmd.none
                        )
                    else if candidateSize == boardSizeToInt Medium then
                        ( { model | formData = setSize Medium model.formData }
                        , Cmd.none
                        )
                    else if candidateSize == boardSizeToInt Small then
                        ( { model | formData = setSize Small model.formData }
                        , Cmd.none
                        )
                    else
                        ( model
                        , Cmd.none
                        )
                Nothing ->
                    ( model
                    , Cmd.none
                    )

        StoreColorChoice colorStr ->
            case colorStr of
                "black" ->
                    ( { model | formData = setColor Black model.formData }
                    , Cmd.none
                    )
                "white" ->
                    ( { model | formData = setColor White model.formData }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        CreateGame ->
            -- TODO: real networking to save game to db
            ( model
            , message (GameCreated (Result.Ok model.formData))
            )

        GameCreated (Ok formData) ->
            ( model
            , message (SendFormDataToMain formData)
            )

        GameCreated (Err httpErr) ->
            -- TODO: display err message
            ( model
            , Cmd.none
            )

        SendFormDataToMain formData ->
            -- now that Main.elm has the data to create the GamePlay page, nav there
            ( model
            , pushUrl Route.GamePlay model.navKey
            )


-- INIT --


init : Nav.Key -> ( Model, Cmd Msg )
init navKey =
    ( initialModel navKey
    , Cmd.none
    )


initialModel : Nav.Key -> Model
initialModel navKey =
    { formData = { boardSize = Full
                 , colorChoice = Black
                 , komi = 5.5 -- current? Japanese regulation komi
                 }
    , navKey = navKey
    }
