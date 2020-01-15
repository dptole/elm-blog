module Elements.SignUp exposing (..)

import Utils.Api
import Utils.Decoders
import Utils.Encoders
import Utils.Funcs
import Utils.Types
import Utils.Work

import Dict
import Html
import Html.Attributes
import Html.Events
import Http



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | TypingUsername String
  | TypingPassword String
  | SubmitSignUp
  | GotSignUpResponse ( Result Http.Error Utils.Types.SignUp_ )



-- MODEL


type alias Model =
  { username : String
  , password : String
  , work : Int
  , error_response : Maybe ( List String )
  }



-- INIT


initModel : Model
initModel =
  Model
    ""                    -- username
    ""                    -- password
    Utils.Work.notWorking -- work
    Nothing               -- error_response


init : ( Model, Cmd Msg )
init =
  ( initModel, Cmd.none )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    TypingUsername username ->
      ( { model | username = username }
      , Cmd.none
      )

    TypingPassword password ->
      ( { model | password = password }
      , Cmd.none
      )

    SubmitSignUp ->
      if Utils.Work.isWorking model.work then
        ( model, Cmd.none )

      else
        ( { model
          | work = Utils.Work.addWork creatingAccount model.work
          }
        , Utils.Api.createAccount
            ( Utils.Encoders.signUpRequest model.username model.password )
            GotSignUpResponse
            Utils.Decoders.createAccount_
        )

    GotSignUpResponse sign_up_response ->
      let
        new_model =
          { model
          | work = Utils.Work.removeWork creatingAccount model.work
          }

      in
        case sign_up_response of
          Ok json ->
            if List.length json.errors == 0 then
              ( { new_model
                | error_response = Nothing
                , username = ""
                , password = ""
                }
              , Cmd.none
              )

            else
              let
                error_responses1 =
                  Utils.Funcs.extractErrorsFromDicts json.errors
                    |> List.map (\(k, v) -> v)

                error_responses =
                  if List.length error_responses1 == 0 then
                    [ json.reqid ++ ": There were no failures but it doesn't mean success :(" ]

                  else
                    error_responses1

              in
                ( { new_model
                  | error_response = Just error_responses
                  }
                , Cmd.none
                )

          Err _ ->
            ( { new_model
              | error_response = Just [ "Unknown error :(" ]
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Html.Html Msg
view model =
  let
    is_working = Utils.Work.isWorking model.work

    error_response_div =
      case model.error_response of
        Nothing ->
          if Utils.Work.isWorkingOn creatingAccount model.work then
            Html.div
              [ Html.Attributes.class "loadingdotsafter" ]
              []

          else
            Html.div
              []
              []

        Just error_responses ->
          Html.div
            [ Html.Attributes.class "errors-from-http text-red" ]
            ( List.map
                (\error_response ->
                  Html.div
                    []
                    [ Html.text error_response ]
                ) error_responses
                |> Utils.Funcs.htmlSeparator1
            )

  in
    Html.div
      [ Html.Attributes.class "sign-up-container" ]
      [ Html.form
          [ Html.Events.onSubmit SubmitSignUp ]
          [ Html.h1
              []
              [ Html.text "Sign up"
              ]

          , Html.div
              []
              [ Html.input
                  [ Html.Events.onInput TypingUsername
                  , Html.Attributes.type_ "text"
                  , Html.Attributes.autofocus True
                  , Html.Attributes.placeholder "Username"
                  , Html.Attributes.value model.username
                  , Html.Attributes.disabled is_working
                  ]
                  []
              ]

          , Html.div
              []
              [ Html.input
                  [ Html.Events.onInput TypingPassword
                  , Html.Attributes.type_ "password"
                  , Html.Attributes.placeholder "Password"
                  , Html.Attributes.value model.password
                  , Html.Attributes.disabled is_working
                  ]
                  []
              ]

          , error_response_div

          , Html.div
              []
              [ Html.button
                  [ Html.Attributes.disabled is_working
                  , Html.Events.onClick SubmitSignUp
                  , Html.Attributes.class "btn-create"
                  ]
                  [ Html.text "Submit" ]
              ]
          ]
      ]



-- MISC


-- MISC WORK


creatingAccount : Int
creatingAccount = 1


