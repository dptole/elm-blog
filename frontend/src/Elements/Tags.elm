module Elements.Tags exposing (..)

import Elements.SignIn

import Utils.Api
import Utils.Decoders
import Utils.Funcs
import Utils.Routes
import Utils.Types
import Utils.Work

import Html
import Html.Attributes
import Html.Events
import Http


-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | FetchTags
  | GotFetchTagsResponse ( Result Http.Error ( List Utils.Types.PostTag ) )
  | FetchPosts String
  | GotFetchPostsResponse ( Result Http.Error Utils.Types.TaggedPosts )



-- MODEL


type alias Model =
  { tags : List Utils.Types.PostTag
  , tagged_posts : Maybe Utils.Types.TaggedPosts
  , work : Int
  , date_time : String
  , flags : Utils.Types.MainModelFlags
  }


initModel : Utils.Types.MainModelFlags -> Model
initModel flags =
  Model
    []                      -- tags
    Nothing                 -- tagged_posts
    Utils.Work.notWorking   -- work
    ""                      -- date_time
    flags                   -- flags



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    FetchTags ->
      ( { model
        | work = Utils.Work.addWork fetchingTags model.work
        , tags = []
        }
      , Utils.Api.getTags
          model.flags.api
          GotFetchTagsResponse
          Utils.Decoders.getTags
      )

    GotFetchTagsResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork fetchingTags model.work
          }

      in
        case response of
          Ok tags ->
            ( { model2
              | tags = tags
              }
            , Cmd.none
            )

          Err _ ->
            ( model2, Cmd.none )

    FetchPosts tag_id ->
      let
        model2 =
          { model
          | work = Utils.Work.addWork fetchingPosts model.work
          }

      in
        ( model2
        , Utils.Api.taggedPosts
            model.flags.api
            tag_id
            GotFetchPostsResponse
            Utils.Decoders.taggedPosts
        )

    GotFetchPostsResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork fetchingPosts model.work
          }

      in
        case response of
          Ok tagged_posts ->
            ( { model2
              | tagged_posts = Just tagged_posts
              }
            , Cmd.none
            )

          Err _ ->
            ( { model2
              | tagged_posts = Nothing
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Html.Html Msg
view model =
  let
    total_tags_int = List.length model.tags

    total_tags =
      if
        total_tags_int == 0 ||
        Utils.Work.isWorkingOn fetchingPosts model.work
      then
        ""

      else
        " (" ++ ( String.fromInt total_tags_int ) ++ ")"

    tags_title =
      case model.tagged_posts of
        Just tagged_posts ->
          "Tag: " ++ tagged_posts.tag.name

        Nothing ->
          "Tags" ++ total_tags

  in
    Html.div
      []
      [ Html.h1
          []
          [ Html.text tags_title ]

      , Html.hr [] []

      , if Utils.Work.isWorkingOn fetchingTags model.work then
          Html.div
            [ Html.Attributes.class "loadingdotsafter" ]
            [ Html.text "Fetching tags" ]

        else if Utils.Work.isWorkingOn fetchingPosts model.work then
          Html.div
            [ Html.Attributes.class "loadingdotsafter" ]
            [ Html.text "Fetching posts" ]

        else
          case model.tagged_posts of
            Just tagged_posts ->
              viewTaggedPosts model tagged_posts

            Nothing ->
              viewTagsList model
      ]


viewTaggedPost : Model -> Utils.Types.PublishedPost -> Html.Html Msg
viewTaggedPost model post =
  let
    href =
      Utils.Routes.buildRoute
        [ post.id ]
        Utils.Routes.readPost

    tags =
      if List.length post.tags > 0 then
        String.join ", " post.tags
      else
        "<None>"

  in
    Html.div
      []
      [ Html.div
          []
          [ Html.a
              [ Html.Attributes.href href ]
              [ Html.text post.title ]

          , Html.text " published "

          , Utils.Funcs.iso8601HumanDateDiff
              model.date_time
              post.published_at
                |> Html.text

          , Html.div
              []
              [ "Tags: " ++ tags
                  |> Html.text
              ]
          ]

      , Html.div
          []
          [ "Author: " ++ post.author.username
              |> Html.text
          ]
      ]


viewTaggedPosts : Model -> Utils.Types.TaggedPosts -> Html.Html Msg
viewTaggedPosts model tagged_posts =
  Html.div
    []
    (
      List.intersperse ( Html.hr [] [] )
        <| List.map ( viewTaggedPost model ) tagged_posts.posts
    )


viewTagsList : Model -> Html.Html Msg
viewTagsList model =
  if List.length model.tags < 1 then
    viewTagsEmptyList model

  else
    viewTagsFullList model


viewTagsEmptyList : Model -> Html.Html Msg
viewTagsEmptyList model =
  Html.div
    []
    [ Html.text "There are no tags available!" ]


viewTagsFullList : Model -> Html.Html Msg
viewTagsFullList model =
  Html.div
    []
    ( 
      List.map ( viewTag model ) model.tags
        |> List.intersperse ( Html.hr [] [] )
    )


viewTag : Model -> Utils.Types.PostTag -> Html.Html Msg
viewTag model tag =
  let
    tag_link =
      Utils.Routes.buildRoute
        [ tag.id ]
        Utils.Routes.tagDetails

    post_naming =
      if tag.posts == 1 then
        " post"
      else
        " posts"

  in
    Html.div
      []
      [ Html.div
          []
          [ Html.a
              [ Html.Attributes.href tag_link ]
              [ Html.text tag.name ]

          , Html.text " | "

          , Html.span
              []
              [ Html.text <| String.fromInt tag.posts
              , Html.text post_naming
              ]
          ]

      , Html.div
          []
          [ Html.text "Last updated: "

          , Utils.Funcs.iso8601HumanDateDiff
              model.date_time
              tag.last_updated
                |> Html.text
          ]
      ]



-- MISC


-- MISC WORK


fetchingTags : Int
fetchingTags = 1


fetchingPosts : Int
fetchingPosts = 2

