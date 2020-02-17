module Main exposing (..)

import Elements.CommentReply
import Elements.CommentReview
import Elements.SignIn
import Elements.SignUp
import Elements.PostComments
import Elements.PostCreate
import Elements.PostDashboard
import Elements.PostPreview
import Elements.PostShowPrivate
import Elements.PostReview
import Elements.PostShowPublic
import Elements.Profile
import Elements.Tags

import Utils.Css
import Utils.Decoders
import Utils.Funcs
import Utils.Routes
import Utils.Types
import Utils.Work

import Browser
import Browser.Dom
import Browser.Navigation
import Dict
import Html
import Html.Attributes
import Html.Events
import Html.Lazy
import Http
import Json.Decode
import Json.Encode
import Task
import Time
import Url



-- MAIN


main : Program Json.Encode.Value Model Msg
main =
  Browser.application
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    , onUrlChange = UrlChanged
    , onUrlRequest = LinkClicked
    }



-- ACTIONS


type Msg
  = UrlChanged Url.Url
  | LinkClicked Browser.UrlRequest
  | Tick Time.Posix

  -- Elements/SignUp
  | SignUpMsg Elements.SignUp.Msg

  -- Elements/SignIn
  | SignInMsg Elements.SignIn.Msg

  -- Elements/PostCreate
  | PostCreateMsg Elements.PostCreate.Msg

  -- Elements/PostShowPrivate
  | PostShowPrivateMsg Elements.PostShowPrivate.Msg

  -- Elements/PostShowPrivateReview
  | PostReviewMsg Elements.PostReview.Msg

  -- Elements/PostShowPublic
  | PostShowPublicMsg Elements.PostShowPublic.Msg

  -- Elements/CommentReview
  | CommentReviewMsg Elements.CommentReview.Msg

  -- Elements/Tags
  | TagsMsg Elements.Tags.Msg

  -- Elements/CommentReply
  | CommentReplyMsg Elements.CommentReply.Msg

  -- Elements/CommentReply
  | ProfileMsg Elements.Profile.Msg

  -- Elements/PostDashboard
  | PostDashboardMsg Elements.PostDashboard.Msg



-- MODEL


type alias ElementsModel =
  { sign_up : Elements.SignUp.Model
  , post_create : Elements.PostCreate.Model
  , post_show_private : Elements.PostShowPrivate.Model
  , sign_in : Elements.SignIn.Model
  , post_review : Elements.PostReview.Model
  , post_show_public : Elements.PostShowPublic.Model
  , comment_review : Elements.CommentReview.Model
  , tags : Elements.Tags.Model
  , comment_reply : Elements.CommentReply.Model
  , profile : Elements.Profile.Model
  , post_dashboard : Elements.PostDashboard.Model
  }


type alias MainNavModel =
  { url : Url.Url
  , key : Browser.Navigation.Key
  }


type alias MainModel =
  { nav : MainNavModel
  , flags : Utils.Types.MainModelFlags
  , work : Int
  , time : Time.Posix
  , zone : Time.Zone
  , special_msg : Utils.Types.SpecialMsg
  }


type alias Model =
  { comp : ElementsModel
  , main : MainModel
  }



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every 1000 Tick



-- INIT


init : Json.Encode.Value -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init js_flags nav_url nav_key =
  let
    flags = Utils.Decoders.flags js_flags initFlags

    model =
      Model
        ( initElementsModel flags nav_url nav_key ) -- comp
        ( initMainModel flags nav_url nav_key )     -- main

    model2 =
      updateModelCompPostDateTime
        ( Utils.Funcs.posixToIso8601 model.main.zone model.main.time )
        model

    cmds =
      [ Cmd.map SignInMsg <| Elements.SignIn.checkIfAlreadySignedIn flags
      , Cmd.map PostShowPublicMsg <| Elements.PostShowPublic.getPublishedPosts flags.api
      ]

    href =
      case getRoute model of
        Just _ ->
          flags.url.href

        Nothing ->
          flags.url.origin ++
          ( if isProdEnv then
              Utils.Routes.root
            else
              Utils.Routes.home
          )

    cmds2 =
      case Url.fromString href of
        Just url ->
          let
            location_cmd =
              Task.succeed url
                |> Task.perform (\url2 -> Browser.Internal url2 |> LinkClicked)

          in
            location_cmd :: cmds

        Nothing ->
          cmds

  in
    ( model2
    , Cmd.batch cmds2
    )


initElementsModel : Utils.Types.MainModelFlags -> Url.Url -> Browser.Navigation.Key -> ElementsModel
initElementsModel flags nav_url nav_key =
  ElementsModel
    ( Elements.SignUp.initModel flags )           -- sign_up
    ( Elements.PostCreate.initModel flags )       -- post_create
    ( Elements.PostShowPrivate.initModel flags )  -- post_show_private
    ( Elements.SignIn.initModel flags )           -- sign_in
    ( Elements.PostReview.initModel flags )       -- post_review
    ( Elements.PostShowPublic.initModel flags )   -- post_show_public
    ( Elements.CommentReview.initModel flags )    -- comment_review
    ( Elements.Tags.initModel flags )             -- tags
    ( Elements.CommentReply.initModel flags )     -- comment_reply
    ( Elements.Profile.initModel flags )          -- profile
    ( Elements.PostDashboard.initModel flags )    -- post_dashboard


initMainModel : Utils.Types.MainModelFlags -> Url.Url -> Browser.Navigation.Key -> MainModel
initMainModel flags nav_url nav_key =
  MainModel
    ( MainNavModel nav_url nav_key )                              -- nav
    flags                                                         -- flags
    ( Utils.Work.addWork loadingPublishedPosts checkingLoggedIn ) -- work
    ( Time.millisToPosix flags.initial_ms )                       -- time
    ( Time.customZone 0 [] )                                      -- zone
    Utils.Types.NoSpecial                                         -- special_msg


initFlags : Utils.Types.MainModelFlags
initFlags =
  Utils.Types.MainModelFlags
    initFlagsUrl                      -- url
    "http://localhost:9090/elm-blog"  -- api
    0                                 -- initial_ms


initFlagsUrl : Utils.Types.MainModelFlagsUrl
initFlagsUrl =
  Utils.Types.MainModelFlagsUrl
    ""                                    -- hash
    "localhost:8080"                      -- host
    "localhost"                           -- hostname
    "http://localhost:8080/src/Main.elm"  -- href
    "http://localhost:8080"               -- origin
    "http:"                               -- protocol
    "8080"                                -- port_string
    []                                    -- search_params



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  Utils.Funcs.log
  msg
  (
  case msg of
    Tick time ->
      let
        model2 =
          updateModelCompPostDateTime
            ( Utils.Funcs.posixToIso8601 model.main.zone time )
            model
              |> updateModelTime time

      in
        ( model2
        , Task.perform
            (\v ->
              PostShowPublicMsg
                <| Elements.PostShowPublic.GetViewport v
            )
            <| Browser.Dom.getViewport
        )

    UrlChanged url ->
      if model.main.special_msg == Utils.Types.NoSpecial then
        let
          model2 = updateModelNavUrl url model
          route_got = getRoute model2
        in
          case route_got of
            Just ( Utils.Types.SignIn, _ ) ->
              ( unlockSignInUser model2
              , Cmd.none
              )

            Just ( Utils.Types.ReadPost, params ) ->
              case Utils.Routes.getParamByName "post_id" params of
                Just post_id ->
                  ( addWork fetchingPublishedPost model2
                  , Cmd.map
                      PostShowPublicMsg
                      ( Elements.PostShowPublic.getPublishedPost model.main.flags.api post_id )
                  )

                Nothing ->
                  ( model2
                  , Cmd.none
                  )

            Just ( Utils.Types.DashboardCommentReview, _ ) ->
              let
                ( comment_review_model, comment_review_msg ) =
                  Elements.CommentReview.update
                    Elements.CommentReview.FetchReviewComments
                    model2.comp.comment_review

              in
                ( updateModelCompCommentReview
                    comment_review_model
                    model2
                , Cmd.map CommentReviewMsg comment_review_msg
                )

            Just ( Utils.Types.DashboardCommentReply, _ ) ->
              let
                ( comment_reply_model, comment_reply_cmd ) =
                  Elements.CommentReply.update
                    Elements.CommentReply.FetchReplies
                    model.comp.comment_reply

              in
                ( updateModelCompCommentReply comment_reply_model model2
                , Cmd.map CommentReplyMsg comment_reply_cmd
                )

            Just ( Utils.Types.Home, _ ) ->
              if
                Utils.Work.isWorkingOn
                  loadingPublishedPosts
                  model2.main.work
              then
                ( model2, Cmd.none )
              else
                ( addWork loadingPublishedPosts model2
                    |> updateModelCompPostShowPublic
                        ( Elements.PostShowPublic.initModel model.main.flags )
                , Cmd.map
                    PostShowPublicMsg
                    ( Elements.PostShowPublic.getPublishedPosts model.main.flags.api )
                )

            Just ( Utils.Types.DashboardProfile, _ ) ->
              update
                ( ProfileMsg Elements.Profile.FetchAvatar )
                model2

            Just ( Utils.Types.DashboardPost, _ ) ->
              update
                ( PostDashboardMsg Elements.PostDashboard.FetchPostsGraphs )
                model2

            Just ( Utils.Types.DashboardPostCreate, _ ) ->
              if
                Elements.PostCreate.isCommittingDraft
                  model2.comp.post_create
              then
                ( model2, Cmd.none )
              else
                ( updateModelCompPostCreate
                    ( Elements.PostCreate.initModel model.main.flags )
                    model2
                , Cmd.none
                )

            Just ( Utils.Types.DashboardPostEdit, params ) ->
              case Utils.Routes.getParamByName "post_id" params of
                Just post_id ->
                  let
                    ( post_create_model, post_create_msg ) =
                      Elements.PostCreate.update
                        ( Elements.PostCreate.FetchPost post_id )
                        ( Elements.PostCreate.initModelFetchingPostById
                            model.main.flags
                            post_id
                        )

                  in
                    ( updateModelCompPostCreate
                        post_create_model
                        model2
                    , Cmd.map PostCreateMsg post_create_msg
                    )

                Nothing ->
                  ( model2, Cmd.none )

            Just ( Utils.Types.Tags, _ ) ->
              let
                ( tags_model, cmd ) =
                  Elements.Tags.update
                    Elements.Tags.FetchTags
                    model2.comp.tags

                tags_model2 =
                  { tags_model
                  | tagged_posts = Nothing
                  }

              in
                ( updateModelCompTags tags_model2 model2
                , Cmd.map TagsMsg cmd
                )

            Just ( Utils.Types.TagDetails, params ) ->
              case Utils.Routes.getParamByName "tag_id" params of
                Just tag_id ->
                  let
                    ( tags_model, cmd ) =
                      Elements.Tags.update
                        ( Elements.Tags.FetchPosts tag_id )
                        model2.comp.tags

                    tags_model2 =
                      { tags_model
                      | tagged_posts = Nothing
                      }

                  in
                    ( updateModelCompTags tags_model2 model2
                    , Cmd.map TagsMsg cmd
                    )

                Nothing ->
                  ( model
                  , Cmd.none
                  )

            _ ->
              ( model2, Cmd.none )

      else
        if url == model.main.nav.url then
          ( model
          , Cmd.none
          )

        else
          ( model
          , Browser.Navigation.pushUrl
              model.main.nav.key
              ( Url.toString model.main.nav.url )
          )

    LinkClicked url_request ->
      if model.main.special_msg == Utils.Types.NoSpecial then
        case url_request of
          Browser.Internal url ->
            let
              url_model = updateModelNavUrl url model

              route_got = getRoute url_model

              is_page_post_show_private =
                case route_got of
                  Just ( Utils.Types.DashboardPostShowPrivate, _ ) ->
                    True

                  _ ->
                    False

              is_page_dashboard_post_review =
                case route_got of
                  Just ( Utils.Types.DashboardPostReview, _ ) ->
                    True

                  _ ->
                    False

              is_fetching_reviewing_post =
                Utils.Work.isWorkingOn
                  fetchingReviewingPost
                  url_model.main.work

              model2 =
                if is_page_post_show_private then
                  updateModelCompPostShowPrivate
                    ( Elements.PostShowPrivate.initModelLoading model.main.flags )
                    url_model
                else if
                  is_page_dashboard_post_review &&
                  not is_fetching_reviewing_post
                then
                  updateModelCompPostReview
                    ( Elements.PostReview.initModelLoading model.main.flags )
                    url_model
                else
                  url_model

              get_my_posts_http_cmd =
                Elements.PostShowPrivate.getMyPosts model.main.flags.api

              get_my_posts_cmd =
                if is_page_post_show_private then
                  [ get_my_posts_http_cmd |> Cmd.map PostShowPrivateMsg ]
                else
                  []

              show_private_posts_review_cmd =
                if
                  is_page_dashboard_post_review &&
                  not is_fetching_reviewing_post
                then
                  [ Cmd.map PostReviewMsg
                      <| Elements.PostReview.getPostsToReview model.main.flags.api
                  ]
                else
                  []

              navigate_cmd =
                Browser.Navigation.pushUrl
                  model.main.nav.key
                  ( Url.toString url )

              cmd = 
                if is_page_post_show_private then
                  Cmd.batch <| navigate_cmd :: get_my_posts_cmd

                else if is_page_dashboard_post_review then
                  Cmd.batch <| navigate_cmd :: show_private_posts_review_cmd

                else
                  navigate_cmd

              model3 =
                if is_page_dashboard_post_review then
                  addWork fetchingReviewingPost model2
                else
                  model2

              model4 =
                if List.length get_my_posts_cmd > 0 then
                  let
                    post_show_private2 =
                      Elements.PostShowPrivate.insertHttpCmd
                        "MyPosts"
                        get_my_posts_http_cmd
                        model3.comp.post_show_private

                  in
                    updateModelCompPostShowPrivate
                      post_show_private2
                      model3

                else
                  model3

            in
              ( model4, cmd )

          Browser.External url ->
            let
              cmd = 
                if isWorking model then
                  Cmd.none
                else
                  Browser.Navigation.load url
            in
              ( model, cmd )

      else
        ( model, Cmd.none )

    -- Elements/SignIn
    SignInMsg sign_in_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            sign_in_msg
            model.comp.sign_in
            Elements.SignIn.update
            updateModelCompSignIn
            SignInMsg

        handleHttpError : Http.Error -> Model -> Cmd Msg -> ( Model, Cmd Msg )
        handleHttpError error model_ cmd2 =
          Utils.Funcs.handleHttpError
            error
            update
            model
            cmd2
            Elements.SignIn.SpecialMsg
            SignInMsg
            transformModelReSignIn
            defaultBehavior

      in
        case sign_in_msg of
          Elements.SignIn.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.SignIn.SubmitSignOut ->
            addWork signingOut model
              |> defaultBehavior

          Elements.SignIn.GotSubmitSignOutResponse response ->
            let
              ( model2, cmd2 ) =
                removeWork signingOut model
                  |> defaultBehavior

              model3 =
                if model2.main.special_msg == Utils.Types.ReSignIn then
                  updateModelMainSpecialMsg Utils.Types.NoSpecial model2

                else
                  model2

            in
              case response of
                Ok _ ->
                  ( updateModelCompPostShowPublic
                      ( Elements.PostShowPublic.updateModelIsLoggedIn
                          False
                          model3.comp.post_show_public
                      )
                      model3
                  , Browser.Navigation.pushUrl
                      model.main.nav.key
                      homeUrl
                  )

                Err error ->
                  handleHttpError error model3 cmd2

          _ ->
            let
              ( new_sign_in, new_sign_in_msg ) =
                Elements.SignIn.update sign_in_msg model.comp.sign_in

              ( model3, cmd2 ) =
                case sign_in_msg of
                  Elements.SignIn.SubmitSignIn ->
                    addWork checkingLoggedIn model
                      |> defaultBehavior

                  Elements.SignIn.GotCheckIfAlreadySignedInResponse response ->
                    let
                      model2 = removeWork checkingLoggedIn model

                    in
                      case response of
                        Ok _ ->
                          updateModelCompPostShowPublicIsLoggedIn True model2
                            |> defaultBehavior

                        Err _ ->
                          defaultBehavior model2

                  Elements.SignIn.GotSignInResponse response ->
                    let
                      model2 = removeWork checkingLoggedIn model

                    in
                      case response of
                        Ok json ->
                          if List.length json.errors == 0 then
                            let
                              ( model4, cmd3 ) =
                                updateModelCompPostShowPublicIsLoggedIn True model2
                                  |> updateModelMainSpecialMsg Utils.Types.NoSpecial
                                  |> defaultBehavior

                              pending_http_requests =
                                getAllPendingHttpRequests model4

                            in
                              if List.length pending_http_requests > 0 then
                                ( model4
                                , cmd3 :: pending_http_requests
                                    |> Cmd.batch
                                )

                              else
                                ( model4
                                , Cmd.batch
                                    [ cmd3
                                    , Browser.Navigation.pushUrl
                                        model.main.nav.key
                                        homeUrl
                                    ]
                                )

                          else
                            defaultBehavior model2

                        Err _ ->
                          defaultBehavior model2

                  _ ->
                    ( model, Cmd.map SignInMsg new_sign_in_msg )

            in
              ( updateModelCompSignIn new_sign_in model3
              , cmd2
              )

    -- Elements/SignUp
    SignUpMsg sign_up_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            sign_up_msg
            model.comp.sign_up
            Elements.SignUp.update
            updateModelCompSignUp
            SignUpMsg

      in
        case sign_up_msg of
          Elements.SignUp.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.SignUp.GotSignUpResponse response ->
            case response of
              Ok json ->
                if List.length json.errors == 0 then
                  let
                    ( model2, cmd2 ) = defaultBehavior model

                    old_url = model.main.nav.url
                    new_url = { old_url | path = Utils.Routes.signIn }

                    ( sign_in_model, _ ) =
                      Elements.SignIn.update
                        ( Elements.SignIn.TypingUsername model.comp.sign_up.username )
                        model.comp.sign_in

                    ( sign_in_model2, _ ) =
                      Elements.SignIn.update
                        ( Elements.SignIn.TypingPassword model.comp.sign_up.password )
                        sign_in_model

                  in
                    ( updateModelCompSignIn sign_in_model2 model2
                    , Cmd.batch
                        [ Task.succeed Elements.SignIn.SubmitSignIn |> Task.perform SignInMsg
                        , Task.succeed ( Browser.Internal new_url ) |> Task.perform LinkClicked
                        , cmd2
                        ]
                    )

                else
                  defaultBehavior model

              Err _ ->
                defaultBehavior model

          _ ->
            defaultBehavior model

    -- Elements/CommentReply
    CommentReplyMsg comment_reply_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            comment_reply_msg
            model.comp.comment_reply
            Elements.CommentReply.update
            updateModelCompCommentReply
            CommentReplyMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.CommentReply.SpecialMsg
            CommentReplyMsg
            transformModelReSignIn
            defaultBehavior

      in
        case comment_reply_msg of
          Elements.CommentReply.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.CommentReply.GotSubmitReplyCommentResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.CommentReply.GotFetchRepliesResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          _ ->
            defaultBehavior model

    -- Elements/PostCreate
    PostCreateMsg post_create_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            post_create_msg
            model.comp.post_create
            Elements.PostCreate.update
            updateModelCompPostCreate
            PostCreateMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.PostCreate.SpecialMsg
            PostCreateMsg
            transformModelReSignIn
            defaultBehavior

        handleHttpUnauthorizedError : Model -> ( Model, Cmd Msg )
        handleHttpUnauthorizedError model_ =
          Utils.Funcs.handleHttpUnauthorizedError
            update
            model_
            Elements.PostCreate.SpecialMsg
            PostCreateMsg
            transformModelReSignIn

      in
        case post_create_msg of
          Elements.PostCreate.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.PostCreate.CancelEdit ->
            ( updateModelCompPostCreate
                ( Elements.PostCreate.initModel model.main.flags )
                model
            , Browser.Navigation.pushUrl
                model.main.nav.key
                Utils.Routes.dashboardPostCreate
            )

          Elements.PostCreate.GotSavingAsDraftResponse response ->
            case response of
              Ok json ->
                if json.meta.status_code == 401 then
                  handleHttpUnauthorizedError model

                else
                  defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostCreate.GotCommitPostResponse response ->
            case response of
              Ok json ->
                if json.meta.status_code == 401 then
                  handleHttpUnauthorizedError model

                else
                  defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostCreate.GotSavingAsPostResponse response ->
            case response of
              Ok json ->
                if json.meta.status_code == 401 then
                  handleHttpUnauthorizedError model

                else
                  defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostCreate.GotFetchPostResponse response ->
            case response of
              Ok post ->
                ( updateModelCompPostCreate
                    ( Elements.PostCreate.initModelFromPost model.main.flags post )
                    model
                , Cmd.none
                )

              Err _ ->
                ( model
                , Browser.Navigation.pushUrl
                    model.main.nav.key
                    Utils.Routes.dashboardPostCreate
                )

          _ ->
            defaultBehavior model

    -- Elements/PostShowPrivate
    PostShowPrivateMsg post_show_private_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            post_show_private_msg
            model.comp.post_show_private
            Elements.PostShowPrivate.update
            updateModelCompPostShowPrivate
            PostShowPrivateMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.PostShowPrivate.SpecialMsg
            PostShowPrivateMsg
            transformModelReSignIn
            defaultBehavior

      in
        case post_show_private_msg of
          Elements.PostShowPrivate.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.PostShowPrivate.GotMyPostsResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostShowPrivate.GotRemovedPostResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostShowPrivate.GotReviewingPostResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostShowPrivate.EditingPost post_id ->
            if
              Elements.PostCreate.isCommittingDraft model.comp.post_create
            then
              ( model, Cmd.none )

            else
              ( model
              , Utils.Routes.buildRoute
                  [ post_id ]
                  Utils.Routes.dashboardPostEdit
                    |> Browser.Navigation.pushUrl model.main.nav.key
              )

          Elements.PostShowPrivate.ReadPost post_id ->
            ( model
            , Utils.Routes.buildRoute
                [ post_id ]
                Utils.Routes.readPost
                  |> Browser.Navigation.pushUrl model.main.nav.key
            )

          _ ->
            defaultBehavior model

    -- Elements/PostReview
    PostReviewMsg post_review_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            post_review_msg
            model.comp.post_review
            Elements.PostReview.update
            updateModelCompPostReview
            PostReviewMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.PostReview.SpecialMsg
            PostReviewMsg
            transformModelReSignIn
            defaultBehavior

      in
        case post_review_msg of
          Elements.PostReview.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.PostReview.GotPublishPostResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostReview.GotRejectPostResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostReview.GotSubmitNewNoteResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostReview.GotPostsToReviewResponse response ->
            case response of
              Ok _ ->
                removeWork fetchingReviewingPost model
                  |> defaultBehavior

              Err error ->
                removeWork fetchingReviewingPost model
                  |> handleHttpError error

          Elements.PostReview.GotShowPostDetailsResponse response ->
            let
              ( model2, cmd2 ) = defaultBehavior model

            in
              case response of
                Ok _ ->
                  ( model2, cmd2 )

                Err error ->
                  let
                    ( model3, cmd3 ) =
                      handleHttpError error model2

                  in
                    ( model3
                    , Cmd.batch
                        [ cmd3
                        , Browser.Navigation.pushUrl
                            model.main.nav.key
                            Utils.Routes.dashboardPostReview
                        ]
                    )

          Elements.PostReview.ShowPostDetails post ->
            let
              ( model2, cmd2 ) = defaultBehavior model

            in
              ( model2
              , Cmd.batch
                  [ cmd2
                  , Utils.Routes.buildRoute
                      [ post.id ]
                      Utils.Routes.dashboardPostReviewDetails
                        |> Browser.Navigation.pushUrl model.main.nav.key
                  ]
              )

          Elements.PostReview.HidePostDetails ->
            let
              ( model2, cmd2 ) = defaultBehavior model

            in
              ( model2
              , Cmd.batch
                  [ cmd2
                  , Browser.Navigation.pushUrl
                      model.main.nav.key
                      Utils.Routes.dashboardPostReview
                  ]
              )

          _ ->
            defaultBehavior model

    -- Elements/Tags
    TagsMsg tags_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            tags_msg
            model.comp.tags
            Elements.Tags.update
            updateModelCompTags
            TagsMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.Tags.SpecialMsg
            TagsMsg
            transformModelReSignIn
            defaultBehavior

      in
        case tags_msg of
          Elements.Tags.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.Tags.GotFetchTagsResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.Tags.GotFetchPostsResponse response ->
            let
              ( model2, cmd2 ) =
                defaultBehavior model

            in
              case response of
                Ok _ ->
                  ( model2, cmd2 )

                Err error ->
                  let
                    ( model3, cmd3 ) =
                      handleHttpError error model2

                  in
                    ( model3
                    , Cmd.batch
                        [ cmd3
                        , Browser.Navigation.pushUrl
                            model.main.nav.key
                            Utils.Routes.tags
                        ]
                    )

          _ ->
            defaultBehavior model

    -- Elements/PostShowPublicMsg
    PostShowPublicMsg post_show_public_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            post_show_public_msg
            model.comp.post_show_public
            Elements.PostShowPublic.update
            updateModelCompPostShowPublic
            PostShowPublicMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            (\s -> Elements.PostShowPublic.PostCommentsMsg <| Elements.PostComments.SpecialMsg s)
            PostShowPublicMsg
            transformModelReSignIn
            defaultBehavior

      in
        case post_show_public_msg of
          Elements.PostShowPublic.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.PostShowPublic.PostCommentsMsg ( Elements.PostComments.SpecialMsg special ) ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.PostShowPublic.PostCommentsMsg ( Elements.PostComments.GotSubmitReplyComment response ) ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostShowPublic.PostCommentsMsg ( Elements.PostComments.GotSubmittedCommentResponse response ) ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.PostShowPublic.GotPublishedPostsResponse _ ->
            removeWork loadingPublishedPosts model
              |> defaultBehavior

          Elements.PostShowPublic.GotReadPostResponse response ->
            let
              ( model2, cmd2 ) =
                removeWork fetchingPublishedPost model
                  |> defaultBehavior

              all_cmds =
                case response of
                  Ok published_post ->
                    Cmd.batch
                      [ cmd2
                      , Elements.PostShowPublic.hitPostStats model.main.flags.api published_post.id
                          |> Cmd.map PostShowPublicMsg
                      ]

                  Err _ ->
                    Cmd.batch [ cmd2 ]

            in
              ( updateModelCompPostDateTime
                  model2.comp.post_show_public.date_time
                  model2
              , all_cmds
              )

          _ ->
            defaultBehavior model

    -- Elements/CommentReviewMsg
    CommentReviewMsg comment_review_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            comment_review_msg
            model.comp.comment_review
            Elements.CommentReview.update
            updateModelCompCommentReview
            CommentReviewMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.CommentReview.SpecialMsg
            CommentReviewMsg
            transformModelReSignIn
            defaultBehavior

      in
        case comment_review_msg of
          Elements.CommentReview.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.CommentReview.GotRejectCommentResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.CommentReview.GotPublishCommentResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.CommentReview.GotFetchReviewCommentsResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.CommentReview.GotCommentDetailsResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                let
                  ( model2, _ ) = defaultBehavior model
                  ( model3, cmd3 ) = handleHttpError error model2

                in
                  ( model3
                  , Cmd.batch
                      [ cmd3
                      , Browser.Navigation.pushUrl
                          model.main.nav.key
                          Utils.Routes.dashboardCommentReview
                      ]
                  )

          Elements.CommentReview.CommentDetails comment ->
            let
              ( model2, cmd2 ) =
                defaultBehavior model

            in
              ( model2
              , Cmd.batch
                  [ cmd2
                  , Utils.Routes.buildRoute
                      [ comment.id ]
                      Utils.Routes.dashboardCommentReviewDetails
                        |> Browser.Navigation.pushUrl model.main.nav.key
                  ]
              )

          Elements.CommentReview.ReturnToReviewList ->
            let
              ( model2, cmd2 ) =
                defaultBehavior model

            in
              ( model2
              , Cmd.batch
                  [ cmd2
                  , Browser.Navigation.pushUrl
                      model.main.nav.key
                      Utils.Routes.dashboardCommentReview
                  ]
              )

          _ ->
            defaultBehavior model

    -- Elements/Profile
    ProfileMsg profile_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            profile_msg
            model.comp.profile
            Elements.Profile.update
            updateModelCompProfile
            ProfileMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.Profile.SpecialMsg
            ProfileMsg
            transformModelReSignIn
            defaultBehavior

        handleHttpUnauthorizedError : Model -> ( Model, Cmd Msg )
        handleHttpUnauthorizedError model_ =
          Utils.Funcs.handleHttpUnauthorizedError
            update
            model_
            Elements.Profile.SpecialMsg
            ProfileMsg
            transformModelReSignIn

      in
        case profile_msg of
          Elements.Profile.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.Profile.GotUpdatePasswordResponse response ->
            case response of
              Ok json ->
                if json.meta.status_code == 401 then
                  handleHttpUnauthorizedError model

                else
                  defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.Profile.GotSaveAvatarResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          Elements.Profile.GotFetchAvatarResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          _ ->
            defaultBehavior model

    -- Elements/PostDashboard
    PostDashboardMsg post_dashboard_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            post_dashboard_msg
            model.comp.post_dashboard
            Elements.PostDashboard.update
            updateModelCompPostDashboard
            PostDashboardMsg

        handleHttpError : Http.Error -> Model -> ( Model, Cmd Msg )
        handleHttpError error model_ =
          Utils.Funcs.handleHttpError
            error
            update
            model_
            Cmd.none
            Elements.PostDashboard.SpecialMsg
            PostDashboardMsg
            transformModelReSignIn
            defaultBehavior

      in
        case post_dashboard_msg of
          Elements.PostDashboard.SpecialMsg special ->
            ( updateModelMainSpecialMsg special model
            , Cmd.none
            )

          Elements.PostDashboard.GotFetchPostsGraphsResponse response ->
            case response of
              Ok _ ->
                defaultBehavior model

              Err error ->
                handleHttpError error model

          _ ->
            defaultBehavior model
  )



-- VIEW


view : Model -> Browser.Document Msg
view model =
  let
    header = Html.Lazy.lazy viewPageHeader model
    footer = Html.Lazy.lazy viewPageFooter model

    ( title, body ) =
      case getRoute model of
        Just ( Utils.Types.Home, _ ) ->
          ( "Home"
          , Html.div
            []
            ( viewPublishedPosts model )
          )

        Just ( Utils.Types.SignUp, _ ) ->
          if isLoggedIn model then
            ( "Sign up"
            , Html.div
                []
                []
            )

          else
            ( "Sign up"
            , Elements.SignUp.view model.comp.sign_up
                |> Html.map SignUpMsg
            )

        Just ( Utils.Types.SignIn, _ ) ->
          ( "Sign in"
          , Elements.SignIn.view model.comp.sign_in
              |> Html.map SignInMsg
          )

        Just ( Utils.Types.Tags, _ ) ->
          ( "Tags"
          , Elements.Tags.view model.comp.tags
              |> Html.map TagsMsg
          )

        Just ( Utils.Types.TagDetails, a ) ->
          ( "Tags"
          , Elements.Tags.view model.comp.tags
              |> Html.map TagsMsg
          )

        Just ( Utils.Types.Dashboard, _ ) ->
          ( "Dashboard"
          , Elements.SignIn.viewWelcome
              ( isSigningOut model )
              model.comp.sign_in
                |> Html.map SignInMsg
          )

        Just ( Utils.Types.DashboardPost, _ ) ->
          ( "Posts"
          , Elements.PostDashboard.view model.comp.post_dashboard
              |> Html.map PostDashboardMsg
          )

        Just ( Utils.Types.DashboardProfile, _ ) ->
          ( "Profile"
          , Elements.Profile.view model.comp.profile
              |> Html.map ProfileMsg
          )

        Just ( Utils.Types.DashboardPostReview, _ ) ->
          ( "Posts to review"
          , Elements.PostReview.view
              model.comp.post_review
                |> Html.map PostReviewMsg
          )

        Just ( Utils.Types.DashboardPostReviewDetails, _ ) ->
          ( "Posts to review"
          , Elements.PostReview.view
              model.comp.post_review
                |> Html.map PostReviewMsg
          )

        Just ( Utils.Types.DashboardPostCreate, _ ) ->
          ( "Create a new post"
          , Elements.PostCreate.view model.comp.post_create
              |> Html.map PostCreateMsg
          )

        Just ( Utils.Types.DashboardPostShowPrivate, _ ) ->
          ( "My posts"
          , Elements.PostShowPrivate.view model.comp.post_show_private
              |> Html.map PostShowPrivateMsg
          )

        Just ( Utils.Types.DashboardPostEdit, _ ) ->
          ( model.comp.post_create.form_title
          , Elements.PostCreate.view model.comp.post_create
              |> Html.map PostCreateMsg
          )

        Just ( Utils.Types.ReadPost, _ ) ->
          if Utils.Work.isWorkingOn fetchingPublishedPost model.main.work then
            ( "Fetching post..."
            , Html.div
                [ Html.Attributes.class "loadingdotsafter" ]
                [ Html.text "Fetching post" ]
            )

          else
            let
              preview_post =
                Maybe.withDefault
                  Elements.PostPreview.initModel
                  model.comp.post_show_public.preview_post
            in
              case preview_post.post of
                Just post ->
                  ( post.title
                  , Html.div
                      []
                      ( Elements.PostShowPublic.viewOnePost
                          model.comp.post_show_public
                            |> List.map ( Html.map PostShowPublicMsg )
                      )
                  )

                Nothing ->
                  ( "Unknown post"
                  , Html.div
                      []
                      [ Html.text "This post is unavailable!" ]
                  )

        Just ( Utils.Types.DashboardComment, _ ) ->
          ( "Comment"
          , Html.div
              []
              [ Html.text "NYI" ]
          )

        Just ( Utils.Types.DashboardCommentReply, _ ) ->
          ( "Comments replies"
          , Elements.CommentReply.view
              model.comp.comment_reply
                |> Html.map CommentReplyMsg
          )

        Just ( Utils.Types.DashboardCommentReview, _ ) ->
          ( "Review comments"
          , Elements.CommentReview.view model.comp.comment_review
              |> Html.map CommentReviewMsg
          )

        Just ( Utils.Types.DashboardCommentReviewDetails, _ ) ->
          ( "Review comments"
          , Elements.CommentReview.view model.comp.comment_review
              |> Html.map CommentReviewMsg
          )

        Nothing ->
          ( "Page not found"
          , Html.div [] [ Html.text "Page not found!" ]
          )

  in
    { title = title
    , body =
        [ header
        , Html.div
            [ Html.Attributes.class "body-html" ]
            [ Html.div
                [ Html.Attributes.class "body" ]
                [ Html.Lazy.lazy identity body ]
            ]
        , footer
        , crashArea
        ]
    }


viewPageHeader : Model -> Html.Html Msg
viewPageHeader model =
  let
    li_home =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href homeUrl ]
            [ Html.text "Home" ]
        ]

    li_tags =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.tags ]
            [ Html.text "Tags" ]
        ]

    li_sign_up =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.signUp ]
            [ Html.text "Sign up" ]
        ]

    li_sign_in =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.signIn ]
            [ Html.text "Sign in" ]
        ]

    li_post_create =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.dashboardPostCreate ]
            [ Html.text "Create" ]
        ]

    li_post_show =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.dashboardPostShow ]
            [ Html.text "Show" ]
        ]

    li_post_review =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.dashboardPostReview ]
            [ Html.text "Review" ]
        ]

    li_post =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.dashboardPost ]
            [ Html.text "Post" ]
        , Html.ul
            []
            [ li_post_create , li_post_show, li_post_review ]
        ]

    li_comment_reply =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.dashboardCommentReply ]
            [ Html.text "Replies" ]
        ]

    li_comment_review =
      Html.li
        []
        [ Html.span
            []
            [ Html.a
                [ Html.Attributes.href Utils.Routes.dashboardCommentReview ]
                [ Html.text "Review" ]
            ]
        ]

    li_comment =
      Html.li
        []
        --[ Html.a
            --[ Html.Attributes.href Utils.Routes.dashboardComment ]
            --[ Html.text "Comment" ]
        [ Html.span
            [ Html.Attributes.class "text-black" ]
            [ Html.text "Comment" ]

        , Html.ul
            []
            [ li_comment_reply, li_comment_review ]
        ]

    li_profile =
      Html.li
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.dashboardProfile ]
            [ Html.text "Profile" ]
        ]

    li_signoff =
      Html.li
        []
        [ Html.span
            ( Html.Attributes.class "signoff-link" ::
              sign_off_attributes
            )
            [ Html.text sign_off_text ]
        ]

    li_dashboard =
      Html.li
        []
        [ Html.span
            []
            [ let
                username =
                  case model.comp.sign_in.auth of
                    Just auth ->
                      auth.user.username
                    Nothing -> ""

              in
                if String.length username == 0 then
                  Html.text "Dashboard"

                else if isSigningOut model then
                  Html.text <| "Bye " ++ username

                else
                  Html.text <| "Hello " ++ username
            ]

        , Html.ul
            []
            [ li_profile
            , li_post
            , li_comment
            , li_signoff
            ]
        ]

    sign_off_text =
      if isSigningOut model then
        "Signing off"
      else
        "Sign off"

    sign_off_attributes =
      if isSigningOut model then
        []
      else
        [ Html.Events.onClick <| SignInMsg Elements.SignIn.SubmitSignOut ]

    lis =
      if isLoggedIn model then
        [ li_home, li_tags ]
      else
        [ li_home, li_tags, li_sign_up, li_sign_in ]

    lis2 =
      if isLoggedIn model then
        [ li_dashboard ]
      else
        []

  in
    Html.div
      [ Html.Attributes.class "header" ]
      ( List.append
          ( if isProdEnv then
              []
            else
              headOnlyContent model
          )
          [ Html.node
              "link"
              [ Html.Attributes.href "https://fonts.googleapis.com/css?family=Handlee&display=swap"
              , Html.Attributes.attribute "rel" "stylesheet"
              ]
              []

          , Utils.Css.htmlStyles
              { pagination_scroll = model.comp.post_create.pagination_scroll
              , special_msg = model.main.special_msg
              }

          , Html.ul
              [ Html.Attributes.class "left-ul" ]
              lis

          , Html.ul
              [ Html.Attributes.class "right-ul" ]
              lis2
          ]
      )


viewPageFooter : Model -> Html.Html Msg
viewPageFooter model =
  let
    modal_html =
      case model.main.special_msg of
        Utils.Types.NoSpecial ->
          Html.div [] []

        Utils.Types.ReSignIn ->
          Html.div
            [ Html.Attributes.class "modal-container" ]
            [ Html.div
                [ Html.Attributes.class "modal-container-box" ]
                [ Html.div
                    [ Html.Attributes.class "modal-container-close"
                    , Html.Events.onClick
                        <| SignInMsg
                        <| Elements.SignIn.GotSubmitSignOutResponse
                        <| Ok { success = True }
                    ]
                    [ Html.text "x" ]

                , Html.small
                    []
                    [ Html.text "Your session has expired!" ]

                , Elements.SignIn.view model.comp.sign_in
                    |> Html.map SignInMsg
                ]
            ]

  in
    Html.div
      [ Html.Attributes.class "footer" ]
      [ modal_html

      , Html.text "Made with "

      , Html.a
          [ Html.Attributes.href "https://elm-lang.org"
          , Html.Attributes.target "_blank"
          , Html.Attributes.rel "noreferrer"
          ]
          [ Html.text "Elm" ]

      , Html.text " by "

      , Html.a
          [ Html.Attributes.href "https://github.com/dptole"
          , Html.Attributes.target "_blank"
          , Html.Attributes.rel "noreferrer"
          ]
          [ Html.text "dptole" ]

      , Html.text " · "

      , Html.a
          [ Html.Attributes.href "https://github.com/dptole/elm-blog"
          , Html.Attributes.target "_blank"
          , Html.Attributes.rel "noreferrer"
          ]
          [ Html.text "github repo" ]
      ]


viewPublishedPosts : Model -> List ( Html.Html Msg )
viewPublishedPosts model =
  List.concat
    [ [ Html.h1
          []
          [ Html.text "Posts" ]
      , Html.hr [] []
      ]

    , if Utils.Work.isWorkingOn loadingPublishedPosts model.main.work then
        [ Html.div
            [ Html.Attributes.class "loadingdotsafter" ]
            [ Html.text "Loading published posts" ]
        ]

      else
        Elements.PostShowPublic.viewPostsList model.comp.post_show_public
          |> List.map ( Html.map PostShowPublicMsg )
    ]



-- MISC


-- MISC ENV


isProdEnv : Bool
isProdEnv = False


homeUrl : String
homeUrl =
  if isProdEnv then
    Utils.Routes.root
  else
    Utils.Routes.home



-- MISC VALIDATORS


isWorking : Model -> Bool
isWorking model =
  Utils.Work.isWorking model.main.work ||
  Utils.Work.isWorking model.comp.post_create.work ||
  Utils.Work.isWorking model.comp.post_show_private.work ||
  Utils.Work.isWorking model.comp.sign_in.work ||
  Utils.Work.isWorking model.comp.sign_up.work


isLoggedIn : Model -> Bool
isLoggedIn model =
  case model.comp.sign_in.auth of
    Just _ -> True
    Nothing -> False


isSigningOut : Model -> Bool
isSigningOut model =
  Utils.Work.isWorkingOn signingOut model.main.work



-- MISC UPDATERS


updateModelMainSpecialMsg : Utils.Types.SpecialMsg -> Model -> Model
updateModelMainSpecialMsg new_special_msg model =
  let
    old_main = model.main
    new_main = { old_main | special_msg = new_special_msg }
    
  in
    { model | main = new_main }


updateModelNavUrl : Url.Url -> Model -> Model
updateModelNavUrl url model =
  let
    old_nav = model.main.nav
    new_nav = { old_nav | url = url }

    old_main = model.main
    new_main = { old_main | nav = new_nav }
  in
    { model | main = new_main }


updateModelTime : Time.Posix -> Model -> Model
updateModelTime new_time model =
  let
    old_main = model.main
    new_main = { old_main | time = new_time }
  in
    { model | main = new_main }


updateModelZone : Time.Zone -> Model -> Model
updateModelZone new_zone model =
  let
    old_main = model.main
    new_main = { old_main | zone = new_zone }
  in
    { model | main = new_main }


updateModelCompTags : Elements.Tags.Model -> Model -> Model
updateModelCompTags new_tags model =
  let
    old_comp = model.comp
    new_comp = { old_comp | tags = new_tags }
  in
    { model | comp = new_comp }


updateModelCompSignUp : Elements.SignUp.Model -> Model -> Model
updateModelCompSignUp new_sign_up model =
  let
    old_comp = model.comp
    new_comp = { old_comp | sign_up = new_sign_up }
  in
    { model | comp = new_comp }


updateModelCompSignIn : Elements.SignIn.Model -> Model -> Model
updateModelCompSignIn new_sign_in model =
  let
    old_comp = model.comp
    new_comp = { old_comp | sign_in = new_sign_in }
  in
    { model | comp = new_comp }


updateModelCompCommentReview : Elements.CommentReview.Model -> Model -> Model
updateModelCompCommentReview new_comment_review model =
  let
    old_comp = model.comp
    new_comp = { old_comp | comment_review = new_comment_review }
  in
    { model | comp = new_comp }


updateModelCompPostCreate : Elements.PostCreate.Model -> Model -> Model
updateModelCompPostCreate new_post_create model =
  let
    old_comp = model.comp
    new_comp = { old_comp | post_create = new_post_create }
  in
    { model | comp = new_comp }


updateModelCompPostDashboard : Elements.PostDashboard.Model -> Model -> Model
updateModelCompPostDashboard new_post_dashboard model =
  let
    old_comp = model.comp
    new_comp = { old_comp | post_dashboard = new_post_dashboard }
  in
    { model | comp = new_comp }


updateModelCompCommentReply : Elements.CommentReply.Model -> Model -> Model
updateModelCompCommentReply new_comment_reply model =
  let
    old_comp = model.comp
    new_comp = { old_comp | comment_reply = new_comment_reply }
  in
    { model | comp = new_comp }


updateModelCompPostCreateErrorResponse : String -> Model -> Model
updateModelCompPostCreateErrorResponse error_response model =
  let
    old_post_create = model.comp.post_create
    new_post_create =
      { old_post_create | error_response = error_response }

    old_comp = model.comp
    new_comp = { old_comp | post_create = new_post_create }
  in
    { model | comp = new_comp }


updateModelCompPostShowPrivate : Elements.PostShowPrivate.Model -> Model -> Model
updateModelCompPostShowPrivate new_post_show_private model =
  let
    old_comp = model.comp
    new_comp = { old_comp | post_show_private = new_post_show_private }
  in
    { model | comp = new_comp }


updateModelCompPostReview : Elements.PostReview.Model -> Model -> Model
updateModelCompPostReview new_pspr model =
  let
    old_comp = model.comp
    new_comp = { old_comp | post_review = new_pspr }
  in
    { model | comp = new_comp }


updateModelCompPostShowPublic : Elements.PostShowPublic.Model -> Model -> Model
updateModelCompPostShowPublic new_psp model =
  let
    old_comp = model.comp
    new_comp = { old_comp | post_show_public = new_psp }
  in
    { model | comp = new_comp }


updateModelCompProfile : Elements.Profile.Model -> Model -> Model
updateModelCompProfile new_profile model =
  let
    old_comp = model.comp
    new_comp = { old_comp | profile = new_profile }
  in
    { model | comp = new_comp }


updateModelCompPostDateTime : String -> Model -> Model
updateModelCompPostDateTime date_time model =
  let
    old_post_show_public = model.comp.post_show_public

    old_comment_reply = model.comp.comment_reply


    old_tags = model.comp.tags

    old_post_comments = model.comp.post_show_public.post_comments

    old_comment_review = model.comp.comment_review
    old_comment_review_post_preview = model.comp.comment_review.post_preview
    old_comment_review_post_comments = model.comp.comment_review.post_comments

    old_post_dashboard = model.comp.post_dashboard

    new_preview_post =
      case old_post_show_public.preview_post of
        Just preview_post ->
          Just { preview_post | date_time = date_time }

        Nothing ->
          Nothing

    new_comment_reply =
      { old_comment_reply | date_time = date_time }

    new_post_show_public =
      { old_post_show_public
      | date_time = date_time
      , preview_post = new_preview_post
      , post_comments = new_post_comments
      }

    new_comment_review_post_preview =
      { old_comment_review_post_preview
      | date_time = date_time
      }

    new_comment_review_post_comments =
      { old_comment_review_post_comments
      | date_time = date_time
      }

    new_comment_review =
      { old_comment_review
      | post_preview = new_comment_review_post_preview
      , post_comments = new_comment_review_post_comments
      }

    new_post_dashboard =
      { old_post_dashboard
      | date_time = date_time
      }

    new_tags =
      { old_tags
      | date_time = date_time
      }

    new_post_comments =
      { old_post_comments
      | date_time = date_time
      }

  in
    updateModelCompCommentReply new_comment_reply model
      |> updateModelCompCommentReview new_comment_review
      |> updateModelCompPostShowPublic new_post_show_public
      |> updateModelCompPostDashboard new_post_dashboard
      |> updateModelCompTags new_tags


updateModelCompPostShowPublicIsLoggedIn : Bool -> Model -> Model
updateModelCompPostShowPublicIsLoggedIn is_logged_in model =
  updateModelCompPostShowPublic
    ( Elements.PostShowPublic.updateModelIsLoggedIn
        is_logged_in
        model.comp.post_show_public
    )
    model


updateModelCompSignInAuth : Maybe Utils.Types.Auth -> Model -> Model
updateModelCompSignInAuth auth model =
  let
    old_sign_in = model.comp.sign_in
    new_sign_in = { old_sign_in | auth = auth }

    old_comp = model.comp
    new_comp = { old_comp | sign_in = new_sign_in }
  in
    { model | comp = new_comp }



-- MISC GETTERS


getRoute : Model -> Maybe ( Utils.Types.Route, List ( String, String ) )
getRoute model =
  Utils.Routes.getRoute model.main.nav.url.path


getPostById : String -> List Utils.Types.Post -> Maybe Utils.Types.Post
getPostById post_id posts =
  let
    selected_posts =
      List.filterMap (\post ->
        if post.id == post_id then
          Just post
        else
          Nothing
      ) posts
  in
    case selected_posts of
      first_selected_post :: tail ->
        Just first_selected_post

      _ ->
        Nothing



-- MISC WORK


signingOut : Int
signingOut = 1


loadingPublishedPosts : Int
loadingPublishedPosts = 2


checkingLoggedIn : Int
checkingLoggedIn = 4


fetchingPublishedPost : Int
fetchingPublishedPost = 8


fetchingReviewingPost : Int
fetchingReviewingPost = 16


addWork : Int -> Model -> Model
addWork new_work model =
  let
    old_main = model.main
    new_main =
      { old_main
      | work = Utils.Work.addWork new_work model.main.work
      }

  in
    { model | main = new_main }


removeWork : Int -> Model -> Model
removeWork remove_work model =
  let
    old_main = model.main
    new_main =
      { old_main
      | work = Utils.Work.removeWork remove_work model.main.work
      }

  in
    { model | main = new_main }



-- MISC CMD


getAllPendingHttpRequests : Model -> List ( Cmd Msg )
getAllPendingHttpRequests model =
  List.concat
    [ Dict.values model.comp.post_create.http_cmds
        |> List.map (Cmd.map PostCreateMsg)

    , Dict.values model.comp.post_show_private.http_cmds
        |> List.map (Cmd.map PostShowPrivateMsg)

    , Dict.values model.comp.post_review.http_cmds
        |> List.map (Cmd.map PostReviewMsg)

    , Dict.values model.comp.post_show_public.post_comments.http_cmds
        |> List.map (Cmd.map (\m2 -> PostShowPublicMsg <| Elements.PostShowPublic.PostCommentsMsg m2))

    , Dict.values model.comp.comment_review.http_cmds
        |> List.map (Cmd.map CommentReviewMsg)

    , Dict.values model.comp.comment_reply.http_cmds
        |> List.map (Cmd.map CommentReplyMsg)

    , Dict.values model.comp.profile.http_cmds
        |> List.map (Cmd.map ProfileMsg)

    , Dict.values model.comp.post_dashboard.http_cmds
        |> List.map (Cmd.map PostDashboardMsg)
    ]



-- MISC TRANSFORM MODEL SIGN_IN


transformModelReSignIn : Model -> Model
transformModelReSignIn model =
  case model.comp.sign_in.auth of
    Just auth ->
      lockSignInUser auth model

    Nothing ->
      model


lockSignInUser : Utils.Types.Auth -> Model -> Model
lockSignInUser auth model =
  let
    new_username = auth.user.username
    new_model = { old_model | comp = new_comp }
    new_comp = { old_comp | sign_in = new_sign_in }
    new_sign_in =
      { old_sign_in
      | lock_username = True
      , username = new_username
      }

    old_model = model
    old_comp = model.comp
    old_sign_in = model.comp.sign_in

  in
    new_model


unlockSignInUser : Model -> Model
unlockSignInUser model =
  if model.comp.sign_in.lock_username then
    let
      new_model = { old_model | comp = new_comp }
      new_comp = { old_comp | sign_in = new_sign_in }
      new_sign_in =
        { old_sign_in
        | lock_username = False
        , username = ""
        , password = ""
        , error_response = Nothing
        , work = Utils.Work.notWorking
        }

      old_model = model
      old_comp = old_model.comp
      old_sign_in = old_comp.sign_in

    in
      new_model

  else
    model



-- MISC HEAD


headOnlyContent : Model -> List ( Html.Html Msg )
headOnlyContent model =
  [ Html.node
      "link"
      [ Html.Attributes.href "https://fonts.gstatic.com"
      , Html.Attributes.attribute "rel" "dns-prefetch"
      ]
      []

  , Html.node
      "link"
      [ Html.Attributes.href "https://fonts.googleapis.com"
      , Html.Attributes.attribute "rel" "dns-prefetch"
      ]
      []

  , Html.node
      "meta"
      [ Html.Attributes.name "viewport"
      , Html.Attributes.attribute "content" "width=device-width"
      ]
      []

  , Html.node
      "meta"
      [ Html.Attributes.name "format-detection"
      , Html.Attributes.attribute "content" "telephone=no;date=no;address=no;email=no"
      ]
      []

  , Html.node
      "meta"
      [ Html.Attributes.name "theme-color"
      , Html.Attributes.attribute "content" "#000000"
      ]
      []
  ]



-- MISC DEBUG


crashArea : Html.Html Msg
crashArea =
  Html.pre
    [ Html.Attributes.id "elm"
    , Html.Attributes.style "white-space" "pre-wrap"
    , Html.Attributes.style "font-family" "courier"
    , Html.Attributes.style "font-size" "18px"
    , Html.Attributes.style "position" "absolute"
    , Html.Attributes.style "height" "100%"
    , Html.Attributes.style "overflow" "auto"
    ]
    []



