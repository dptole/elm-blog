module Elements.SignIn exposing (..)

import Utils.Api
import Utils.Decoders
import Utils.Encoders
import Utils.Funcs
import Utils.Types
import Utils.Work

import Html
import Html.Attributes
import Html.Events
import Http



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | TypingUsername String
  | TypingPassword String
  | SubmitSignIn
  | GotSignInResponse ( Result Http.Error Utils.Types.Auth_ )
  | GotCheckIfAlreadySignedInResponse ( Result Http.Error Utils.Types.Auth )
  | SubmitSignOut
  | GotSubmitSignOutResponse ( Result Http.Error Utils.Types.SignOut )



-- MODEL


type alias Model =
  { username : String
  , password : String
  , work : Int
  , auth : Maybe Utils.Types.Auth
  , error_response : Maybe ( List String )
  , lock_username : Bool
  }



-- INIT


initModel : Model
initModel =
  Model
    ""                  -- username
    ""                  -- passwork
    checkingCredentials -- work
    Nothing             -- auth
    Nothing             -- error_response
    False               -- lock_username



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

    SubmitSignOut ->
      ( model
      , Utils.Api.signOut
          GotSubmitSignOutResponse
          Utils.Decoders.signOutResponse
      )

    GotSubmitSignOutResponse response ->
      ( { model | auth = Nothing }
      , Cmd.none
      )

    SubmitSignIn ->
      if Utils.Work.isWorking model.work then
        ( model, Cmd.none )

      else
        ( { model
          | work = Utils.Work.addWork submittingCredentials model.work
          , error_response = Nothing
          }
        , Utils.Api.signIn
            ( Utils.Encoders.signInRequest model.username model.password )
            GotSignInResponse
            Utils.Decoders.auth_
        )

    GotSignInResponse sign_in_response ->
      let
        new_model =
          { model
          | work = Utils.Work.removeWork submittingCredentials model.work
          }

      in
        case sign_in_response of
          Ok json ->
            if List.length json.errors == 0 then
              ( { new_model
                | auth = Just ( Utils.Types.Auth json.token json.user )
                , error_response = Nothing
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
                  , auth = Nothing
                  }
                , Cmd.none
                )

          Err error ->
            ( { new_model
              | error_response = Just [ "Unknown error :(" ]
              }
            , Cmd.none
            )

    GotCheckIfAlreadySignedInResponse sign_in_response ->
      let
        new_model =
          { model
          | work = Utils.Work.removeWork checkingCredentials model.work
          }

      in
        case sign_in_response of
          Ok response ->
            ( { new_model
              | auth = Just response
              , error_response = Nothing
              , password = ""
              }
            , Cmd.none
            )

          Err _ ->
            ( new_model
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
          if Utils.Work.isWorkingOn submittingCredentials model.work then
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
          [ Html.Attributes.class "sign-in-form"
          , Html.Events.onSubmit SubmitSignIn
          ]
          [ Html.h1
              []
              [ Html.text "Sign in"
              ]

          , Html.div
              []
              [ Html.input
                  [ Html.Events.onInput TypingUsername
                  , Html.Attributes.type_ "text"
                  , Html.Attributes.class "sign-in-username"
                  , Html.Attributes.autofocus True
                  , Html.Attributes.placeholder "Username"
                  , Html.Attributes.value model.username
                  , Html.Attributes.disabled
                      ( model.lock_username || is_working )
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
                  [ Html.Events.onClick SubmitSignIn
                  , Html.Attributes.class "btn-create"
                  , Html.Attributes.disabled is_working
                  ]
                  [ Html.text "Submit" ]
              ]
          ]
      ]


viewWelcome : Bool -> Model -> Html.Html Msg
viewWelcome is_signing_out model =
  Html.div
      []
      [ Html.text ( getWelcomeMessage is_signing_out model )
      , Html.div
          []
          [ Html.input
              [ Html.Events.onClick SubmitSignOut
              , Html.Attributes.disabled is_signing_out
              , Html.Attributes.value "Sign out"
              , Html.Attributes.type_ "button"
              ]
              []
          ]
      ]


viewReSignInModal : Html.Html msg
viewReSignInModal =
  Html.div
    []
    []



-- MISC


-- MISC WORK


checkingCredentials : Int
checkingCredentials = 1


submittingCredentials : Int
submittingCredentials = 2



-- MISC HTTP


checkIfAlreadySignedIn : Cmd Msg
checkIfAlreadySignedIn =
  Utils.Api.getMe
    GotCheckIfAlreadySignedInResponse
    Utils.Decoders.auth



-- MISC GETTERS


getWelcomeMessage : Bool -> Model -> String
getWelcomeMessage is_signing_out model =
  if is_signing_out then
    "Bye bye!"
  else
    "Welcome " ++ ( getModelCompSignInAuthUserUsername model ) ++ "!"


getModelCompSignInAuthUserUsername : Model -> String
getModelCompSignInAuthUserUsername model =
  case model.auth of
    Just auth ->
      auth.user.username

    Nothing ->
      ""


