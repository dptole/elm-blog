module Elements.PostShowPublic exposing (..)

import Elements.PostComments
import Elements.PostPreview

import Utils.Api
import Utils.Decoders
import Utils.Funcs
import Utils.Routes
import Utils.Types
import Utils.Work

import Browser.Dom
import Html
import Html.Attributes
import Html.Events
import Http



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | GotPublishedPostsResponse ( Result Http.Error Utils.Types.HomePosts )
  | GotPublishedPostsAfterResponse ( Result Http.Error Utils.Types.HomePosts )
  | GotReadPostResponse ( Result Http.Error Utils.Types.PublishedPost )
  | WhateverHttpResponse ( Result Http.Error () )
  | GetViewport Browser.Dom.Viewport

  -- Elements/PostPreview
  | PostPreviewMsg Elements.PostPreview.Msg

  -- Elements/PostComments
  | PostCommentsMsg Elements.PostComments.Msg



-- MODEL


type alias Model =
  { posts : Maybe ( List Utils.Types.PublishedPost )
  , selected_post : Maybe Utils.Types.PublishedPost
  , preview_post : Maybe Elements.PostPreview.Model
  , post_comments : Elements.PostComments.Model
  , tags : Maybe ( List Utils.Types.SinglePostTag )
  , date_time : String
  , flags : Utils.Types.MainModelFlags
  , is_page_bottom : Bool
  , load_more_posts : Bool
  , work : Int
  }



-- INIT


initModel : Utils.Types.MainModelFlags -> Model
initModel flags =
  Model
    Nothing                                   -- posts
    Nothing                                   -- selected_post
    Nothing                                   -- preview_post
    ( Elements.PostComments.initModel flags ) -- post_comments
    Nothing                                   -- tags
    ""                                        -- date_time
    flags                                     -- flags
    False                                     -- is_page_bottom
    True                                      -- load_more_posts
    Utils.Work.notWorking                     -- work



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    GetViewport viewport ->
      let
        model2 =
          { model
          | is_page_bottom =
              viewport.scene.height ==
              viewport.viewport.height + viewport.viewport.y
          }

        posts = Maybe.withDefault [] model.posts

        last_post_id =
          case List.drop ( List.length posts - 1 ) posts |> List.head of
            Just post ->
              post.id

            Nothing ->
              ""

        cmd =
          if
            List.length posts > 0 &&
            model2.is_page_bottom &&
            model2.load_more_posts
          then
            getPublishedPostsAfter model.flags.api last_post_id

          else
            Cmd.none

        model3 =
          if Cmd.none == cmd then
            model2

          else
            { model2
            | work = Utils.Work.addWork loadingMorePosts model2.work
            }

      in
        ( model3
        , cmd
        )

    GotPublishedPostsAfterResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork loadingMorePosts model.work
          }

      in
        case response of
          Ok json ->
            if List.length json.posts < 1 then
              ( { model2
                | load_more_posts = False
                }
              , Cmd.none
              )

            else
              case model2.posts of
                Just posts ->
                  ( { model2
                    | posts = List.append posts json.posts |> Just
                    }
                  , Cmd.none
                  )

                Nothing ->
                  ( { model2
                    | posts = Just json.posts
                    }
                  , Cmd.none
                  )

          Err _ ->
            ( model2, Cmd.none )

    WhateverHttpResponse _ ->
      ( model, Cmd.none )

    GotPublishedPostsResponse response ->
      case response of
        Ok home_posts ->
          ( { model
            | posts = Just home_posts.posts
            , tags = Just home_posts.tags
            }
          , Cmd.none
          )

        Err _ ->
          ( model, Cmd.none )

    GotReadPostResponse response ->
      case response of
        Ok selected_post ->
          ( { model
            | selected_post = Just selected_post
            , preview_post =
                Elements.PostPreview.initModelFromPublishedPost selected_post
                  |> Just
            , post_comments =
                Elements.PostComments.initModelFromPostIdPageIndex
                selected_post.id
                0
                model.post_comments
            }
          , Cmd.none
          )

        Err _ ->
          ( { model
            | selected_post = Nothing
            , preview_post = Nothing
            }
          , Cmd.none
          )

    -- Elements/PostPreview
    PostPreviewMsg pp_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.maybeRedirectMsgToSubModule
            pp_msg
            model.preview_post
            Elements.PostPreview.update
            updateModelCompPreviewPost
            PostPreviewMsg

      in
        case pp_msg of
          Elements.PostPreview.NextPagePostPreview ->
            nextPagePostPreview model.post_comments model
              |> defaultBehavior

          Elements.PostPreview.PrevPagePostPreview ->
            prevPagePostPreview model.post_comments model
              |> defaultBehavior

          _ ->
            defaultBehavior model

    -- Elements/PostComments
    PostCommentsMsg pc_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            pc_msg
            model.post_comments
            Elements.PostComments.update
            updateModelCompPostComments
            PostCommentsMsg

      in
        defaultBehavior model



-- VIEW


viewOnePost : Model -> List ( Html.Html Msg )
viewOnePost model =
  case model.preview_post of
    Just preview_post ->
      [ Elements.PostPreview.view preview_post
          |> Html.map PostPreviewMsg

      , Html.hr [] []

      , Elements.PostComments.view model.post_comments
          |> Html.map PostCommentsMsg
      ]

    Nothing ->
      [ Html.div [] [] ]


viewPostsList : Model -> List ( Html.Html Msg )
viewPostsList model =
  let
    no_posts =
      [ Html.div
          []
          [ Html.text "List.isEmpty posts, be the List.head" ]
      ]

  in
    case model.posts of
      Just posts ->
        if List.length posts > 0 then
          List.intersperse
            (
              Html.hr [] []
            )
            (
              List.map(\published_post ->
                let
                  post_link =
                    Utils.Routes.buildRoute
                      [ published_post.id ]
                      Utils.Routes.readPost

                  tags_info =
                    case model.tags of
                      Just tis -> tis
                      Nothing -> []

                  joined_ti_tags =
                    List.filterMap (\tag ->
                      List.filter (\ti -> ti.name == tag) tags_info
                        |> List.head
                    ) published_post.tags

                  joined_a_tags =
                    List.map (\ti ->
                      let
                        tag_link =
                          Utils.Routes.buildRoute
                            [ ti.id ]
                            Utils.Routes.tagDetails

                      in
                        Html.a
                          [ Html.Attributes.href tag_link ]
                          [ Html.text ti.name ]
                    ) joined_ti_tags

                  joined_html_tags =
                    List.intersperse
                      ( Html.text ", " )
                      joined_a_tags

                  tags =
                    if List.length published_post.tags > 0 then
                      [ Html.div
                          []
                          <| ( Html.text "Tags: " ) :: joined_html_tags
                      ]
                    else
                      []

                in
                  Html.div
                    []
                    ( List.append
                        [ Html.div
                            []
                            [ Html.a
                                [ Html.Attributes.href post_link ]
                                [ Html.text published_post.title ]

                            , Html.text " - "

                            , Html.span
                                [ Html.Attributes.class "published-at" ]
                                [ Html.text "Published "

                                , Utils.Funcs.iso8601HumanDateDiff
                                    model.date_time
                                    published_post.published_at
                                      |> Html.text
                                ]
                            ]

                        , Html.div
                            []
                            [ "Author: " ++ published_post.author.username
                                |> Html.text
                            ]
                        ]
                        tags
                    )
              ) posts
            )
          |> Utils.Funcs.prepend
              ( if Utils.Work.isWorkingOn loadingMorePosts model.work then
                  [ Html.div
                      [ Html.Attributes.class "loadingdotsafter post-show-public-load-more" ]
                      [ Html.text "Loading more posts" ]
                  ]
                else
                  []
              )

        else
          no_posts

      Nothing ->
        no_posts



-- MISC


-- MISC UPDATERS


updateModelCompPreviewPost : Elements.PostPreview.Model -> Model -> Model
updateModelCompPreviewPost new_preview_post model =
  { model | preview_post = Just new_preview_post }


updateModelCompPostComments : Elements.PostComments.Model -> Model -> Model
updateModelCompPostComments new_post_comments model =
  { model | post_comments = new_post_comments }



-- MISC UPDATERS


movePagePostPreview : Int
  -> Elements.PostComments.Model
  -> Elements.PostComments.Model
movePagePostPreview move post_comments_model =
  case post_comments_model.comments of
    Utils.Types.CommentsForPostNotReady ->
      { post_comments_model
      | page_index = post_comments_model.page_index + move
      }

    Utils.Types.CommentsForPostReady post_id page_index ->
      { post_comments_model
      | comments =
          Utils.Types.CommentsForPostReady post_id ( page_index + move )
      , page_index = page_index + move
      }

    Utils.Types.CommentsForPostLoading post_id page_index ->
      { post_comments_model
      | comments =
          Utils.Types.CommentsForPostReady post_id ( page_index + move )
      , page_index = page_index + move
      }

    Utils.Types.CommentsForPostLoaded pcs ->
      case pcs of
        pc :: _ ->
          { post_comments_model
          | comments =
              Utils.Types.CommentsForPostReady
                pc.post_id
                ( pc.page_index + move )
          , page_index = pc.page_index + move
          }

        _ ->
          { post_comments_model
          | comments = Utils.Types.CommentsForPostNotReady
          , page_index = post_comments_model.page_index + move
          }

nextPagePostPreview : Elements.PostComments.Model -> Model -> Model
nextPagePostPreview old_post_comments model =
  { model | post_comments = movePagePostPreview 1 old_post_comments }


prevPagePostPreview : Elements.PostComments.Model -> Model -> Model
prevPagePostPreview old_post_comments model =
  { model | post_comments = movePagePostPreview -1 old_post_comments }


updateModelIsLoggedIn : Bool -> Model -> Model
updateModelIsLoggedIn is_logged_in model =
  let
    old_post_comments = model.post_comments
    new_post_comments =
      { old_post_comments | is_logged_in = is_logged_in }
  in
    { model
    | post_comments = new_post_comments
    }



-- MISC HTTP


getPublishedPosts : String -> Cmd Msg
getPublishedPosts api =
  Utils.Api.getPublishedPosts
    api
    GotPublishedPostsResponse
    Utils.Decoders.homePosts


getPublishedPostsAfter : String -> String -> Cmd Msg
getPublishedPostsAfter api post_id =
  Utils.Api.getPublishedPostsAfter
    api
    post_id
    GotPublishedPostsAfterResponse
    Utils.Decoders.homePosts


getPublishedPost : String -> String -> Cmd Msg
getPublishedPost api post_id =
  Utils.Api.getPublishedPost
    api
    post_id
    GotReadPostResponse
    Utils.Decoders.publishedPost


hitPostStats : String -> String -> Cmd Msg
hitPostStats api post_id =
  Utils.Api.hitPostStats
    api
    post_id
    WhateverHttpResponse



-- MISC WORK


loadingMorePosts : Int
loadingMorePosts = 1



