module Elements.PostShowPrivate exposing (..)

import Elements.PostComments

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
import Html.Lazy
import Http



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | GotMyPostsResponse ( Result Http.Error ( List Utils.Types.Post ) )
  | GotReviewingPostResponse ( Result Http.Error Utils.Types.Post )
  | GotRemovedPostResponse ( Result Http.Error () )
  | RemovingPost Utils.Types.Post
  | EditingPost String
  | PromptingRemoval ( Utils.Types.PromptResponse Utils.Types.Post )
  | ReadPost String
  | ReviewingPost Utils.Types.Post
  | PromptingReview ( Utils.Types.PromptResponse Utils.Types.Post )


-- MODEL


type alias Model =
  { posts : List Utils.Types.Post
  , work : Int
  , error_message : String
  , remove_post : Maybe Utils.Types.Post
  , review_post : Maybe Utils.Types.Post
  , http_cmds : Dict.Dict String ( Cmd Msg )
  , flags : Utils.Types.MainModelFlags
  }



-- INIT


initModel : Utils.Types.MainModelFlags -> Model
initModel flags =
  Model
    []                    -- posts
    Utils.Work.notWorking -- work
    loadingMessage        -- error_message
    Nothing               -- remove_post
    Nothing               -- review_post
    Utils.Funcs.emptyDict -- http_cmds
    flags                 -- flags


initModelLoading : Utils.Types.MainModelFlags -> Model
initModelLoading flags =
  Model
    []                    -- posts
    loadingPosts          -- work
    loadingMessage        -- error_message
    Nothing               -- remove_post
    Nothing               -- review_post
    Utils.Funcs.emptyDict -- http_cmds
    flags                 -- flags



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Should be handled by the module that runs Browser.application
      ( model, Cmd.none )

    ReadPost post_id ->
      -- Should be handled by the module that runs Browser.application
      ( model, Cmd.none )

    EditingPost post_id ->
      -- Should be handled by the module that runs Browser.application
      ( model, Cmd.none )

    PromptingRemoval response ->
      case response of
        Utils.Types.PromptResponseYes post ->
          let
            http_cmd =
              Utils.Api.deletePost
                model.flags.api
                post.id
                GotRemovedPostResponse

            new_model =
              { model
              | work = Utils.Work.addWork removingWork model.work
              , error_message = removingPost
              , http_cmds = Dict.insert "RemovedPost" http_cmd model.http_cmds
              , review_post = Nothing
              , remove_post = Nothing
              }

          in
            ( new_model
            , http_cmd
            )

        Utils.Types.PromptResponseNo ->
          ( { model | remove_post = Nothing }
          , Cmd.none
          )

    GotRemovedPostResponse _ ->
      let
        http_cmd = getMyPosts model.flags.api

        http_cmds = Dict.insert "MyPosts" http_cmd model.http_cmds

        model2 =
          { model
          | work = Utils.Work.removeWork removingWork model.work
          }

      in
        ( { model2
          | error_message = loadingMessage
          , work = Utils.Work.addWork loadingPosts model2.work
          , http_cmds = Dict.remove "RemovedPost" http_cmds
          }
        , http_cmd
        )

    GotMyPostsResponse response ->
      let
        model2 =
          { model
          | review_post = Nothing
          , remove_post = Nothing
          , work = Utils.Work.removeWork loadingPosts model.work
          , error_message = ""
          , http_cmds = Dict.remove "MyPosts" model.http_cmds
          }

      in
        case response of
          Ok posts ->
            ( { model2
              | posts = posts
              }
            , Cmd.none
            )

          Err _ ->
            ( model2, Cmd.none )

    RemovingPost post ->
      ( { model | remove_post = Just post }
      , Cmd.none
      )

    ReviewingPost post ->
      ( { model | review_post = Just post }
      , Cmd.none
      )

    PromptingReview response ->
      case response of
        Utils.Types.PromptResponseYes post ->
          let
            http_cmd =
              Utils.Api.updatePostStatus
                model.flags.api
                post.id
                ( Utils.Encoders.postStatus Utils.Types.PostStatusReviewing )
                GotReviewingPostResponse
                Utils.Decoders.post

          in
            ( { model
              | work = Utils.Work.addWork sendingToReview model.work
              , error_message = sendingToReviewMessage
              , http_cmds = Dict.insert "ReviewingPost" http_cmd model.http_cmds
              , review_post = Nothing
              , remove_post = Nothing
              }
            , http_cmd
            )

        Utils.Types.PromptResponseNo ->
          ( { model | review_post = Nothing }
          , Cmd.none
          )

    GotReviewingPostResponse response ->
      let
        model2 =
          { model
          | error_message = loadingMessage
          , work = Utils.Work.removeWork sendingToReview model.work
          , review_post = Nothing
          , remove_post = Nothing
          }

        http_cmd = getMyPosts model.flags.api

      in
        ( { model2
          | http_cmds = Dict.insert "MyPosts" http_cmd model2.http_cmds
          , work = Utils.Work.addWork loadingPosts model2.work
          }
        , http_cmd
        )



-- VIEW


view : Model -> Html.Html Msg
view model =
  let
    ( thead, tbody ) =
      case model.remove_post of
        Just _ ->
          viewRemovingPostPrompt model

        Nothing ->
          case model.review_post of
            Just _ ->
              viewReviewingPostPrompt model

            Nothing ->
              ( viewPostsHeader
              , viewPostsList model
              )

    content =
      if Utils.Work.isWorking model.work then
        Html.div
          ( if String.length model.error_message > 0 then
              [ Html.Attributes.class "loadingdotsafter" ]
            else
              []
          )
          [ Html.text model.error_message ]

      else if List.length model.posts < 1 then
        Html.div
          []
          [ Html.text "You have no posts at the moment." ]

      else
        Html.table
          [ Html.Attributes.attribute "rules" "rows"
          , Html.Attributes.class "hoverable post-show-private"
          ]
          [ Html.thead
              []
              thead

          , Html.tbody
              []
              tbody

          , Html.tfoot
              []
              []
          ]

  in
    Html.div
      []
      [ Html.h1
          []
          [ Html.text "Your posts" ]

      , Html.div
          []
          [ Html.text "Manage your posts" ]

      , Html.hr [] []

      , content
      ]


viewPostsHeader : List ( Html.Html Msg )
viewPostsHeader =
  [ Html.tr
      []
      [ Html.th
          []
          [ Html.text "Title" ]

      , Html.th
          []
          [ Html.text "Tags" ]

      , Html.th
          []
          [ Html.text "Notes" ]
      ]
  ]


viewPostsList : Model -> List ( Html.Html Msg )
viewPostsList model =
  List.concatMap (\post ->
    let
      tags =
        if List.length post.tags > 0 then
          String.join ", " post.tags
        else
          "<No tags>"

      notes =
        if String.length post.notes > 0 then
          post.notes
        else
          "<No notes>"

      remove_button =
        Html.input
          [ Html.Events.onClick <| RemovingPost post
          , Html.Attributes.class "btn-danger"
          , Html.Attributes.type_ "button"
          , Html.Attributes.value "Remove"
          ]
          []

      extra_buttons =
        if Utils.Types.PostStatusDraft == post.status then
          [ Html.input
              [ Html.Events.onClick <| EditingPost post.id
              , Html.Attributes.type_ "button"
              , Html.Attributes.value "Edit"
              ]
              []
          ]
        else if Utils.Types.PostStatusCreated == post.status then
          [ Html.input
              [ Html.Events.onClick <| ReviewingPost post
              , Html.Attributes.type_ "button"
              , Html.Attributes.class "btn-create"
              , Html.Attributes.value "Send to review"
              ]
              []

          , Html.input
              [ Html.Events.onClick <| EditingPost post.id
              , Html.Attributes.type_ "button"
              , Html.Attributes.value "Edit"
              ]
              []
          ]
        else
          []

      buttons =
        if Utils.Types.PostStatusPublished == post.status then
          [ Html.input
              [ Html.Events.onClick <| ReadPost post.id
              , Html.Attributes.type_ "button"
              , Html.Attributes.value "Read"
              ]
              []
          ]
        else
          remove_button :: extra_buttons

      post_status_title =
        "[" ++ ( fromPostStatusToString post.status ) ++ "] "

    in
      [ Html.tr
          [ Html.Attributes.class "post-show-private-post" ]
          [ Html.td
              []
              [ Html.span
                  [ Html.Attributes.class "post-show-private-post-status" ]
                  [ Html.text post_status_title ]

              , Html.span
                  []
                  [ Html.text post.title ]
              ]

          , Html.td
              []
              [ Html.text tags ]

          , Html.td
              []
              [ Html.text notes ]
          ]

      , Html.tr
          [ Html.Attributes.class "post-show-private-actions" ]
          [ Html.td
              [ Html.Attributes.colspan 4 ]
              buttons
          ]
      ]
  ) model.posts


viewRemovingPostPrompt : Model -> ( List ( Html.Html Msg ), List ( Html.Html Msg ) )
viewRemovingPostPrompt model =
  let
    thead =
      [ Html.tr
          []
          [ Html.th
              []
              [ Html.text "Remove post?" ]
          ]
      ]

    tbody =
      case model.remove_post of
        Just post ->
          [ Html.tr
              []
              [ Html.td
                  []
                  [ Html.div
                      []
                      [ Html.text "Id: "
                      , Html.strong
                          []
                          [ Html.text post.id ]
                      ]

                  , Html.div
                      []
                      [ Html.text "Title: "
                      , Html.strong
                          []
                          [ Html.text post.title ]
                      ]

                  , Html.div
                      []
                      [ Html.text "Status: "
                      , Html.strong
                          []
                          [ Html.text <| fromPostStatusToString post.status ]
                      ]

                  , Html.div
                      [ Html.Attributes.class "post-show-remove" ]
                      [ Html.input
                          [ Html.Events.onClick
                              ( Utils.Types.PromptResponseYes post
                                  |> PromptingRemoval
                              )
                          , Html.Attributes.class "btn-danger"
                          , Html.Attributes.type_ "button"
                          , Html.Attributes.value "Yes"
                          ]
                          []

                      , Html.input
                          [ Html.Events.onClick
                              ( PromptingRemoval
                                  Utils.Types.PromptResponseNo
                              )
                          , Html.Attributes.type_ "button"
                          , Html.Attributes.value "No"
                          ]
                          []
                      ]
                  ]
              ]
          ]

        Nothing ->
          [ Html.div
              []
              [ Html.input
                  [ Err Http.NetworkError
                      |> GotRemovedPostResponse
                      |> Html.Events.onClick
                  , Html.Attributes.type_ "button"
                  , Html.Attributes.value "Something went wrong... Go back!"
                  ]
                  []
              ]
          ]

  in
    ( thead, tbody )


viewReviewingPostPrompt : Model -> ( List ( Html.Html Msg ), List ( Html.Html Msg ) )
viewReviewingPostPrompt model =
  let
    thead =
      [ Html.tr
          []
          [ Html.th
              []
              [ Html.text "Send post to be reviewed?" ]
          ]
      ]

    tbody =
      case model.review_post of
        Just post ->
          [ Html.tr
              []
              [ Html.td
                  []
                  [ Html.text "If accepted your post will be published" ]
              ]

          , Html.tr
              []
              [ Html.td
                  []
                  [ Html.text "Otherwise there will be info in the notes" ]
              ]

          , Html.tr
              []
              [ Html.td
                  []
                  [ Html.div
                      []
                      [ Html.text "Id: "
                      , Html.strong
                          []
                          [ Html.text post.id ]
                      ]

                  , Html.div
                      []
                      [ Html.text "Title: "
                      , Html.strong
                          []
                          [ Html.text post.title ]
                      ]

                  , Html.div
                      []
                      [ Html.text "Status: "
                      , Html.strong
                          []
                          [ Html.text <| fromPostStatusToString post.status ]
                      ]

                  , Html.div
                      [ Html.Attributes.class "post-show-send-review" ]
                      [ Html.input
                          [ Html.Events.onClick
                              ( Utils.Types.PromptResponseYes post
                                  |> PromptingReview
                              )
                          , Html.Attributes.class "btn-create"
                          , Html.Attributes.type_ "button"
                          , Html.Attributes.value "Yes"
                          ]
                          []

                      , Html.input
                          [ Html.Events.onClick
                              ( PromptingReview
                                  Utils.Types.PromptResponseNo
                              )
                          , Html.Attributes.type_ "button"
                          , Html.Attributes.value "No"
                          ]
                          []
                      ]
                  ]
              ]
          ]

        Nothing ->
          [ Html.div
              []
              [ Html.input
                  [ Err Http.NetworkError
                      |> GotRemovedPostResponse
                      |> Html.Events.onClick
                  , Html.Attributes.type_ "button"
                  , Html.Attributes.value "Something went wrong... Go back!"
                  ]
                  []
              ]
          ]

  in
    ( thead, tbody )



-- MISC


-- MISC GETTERS


getMyPosts : String -> Cmd Msg
getMyPosts api =
  Utils.Api.getMyPosts
    api
    GotMyPostsResponse
    Utils.Decoders.privatePostsResponse



-- MISC CONVERTERS


fromPostStatusToString : Utils.Types.PostStatus -> String
fromPostStatusToString status =
  case status of
    Utils.Types.PostStatusDraft ->
      "Draft"

    Utils.Types.PostStatusCreated ->
      "Created"

    Utils.Types.PostStatusReviewing ->
      "Reviewing"

    Utils.Types.PostStatusPublished ->
      "Published"



-- CONSTANTS


loadingMessage : String
loadingMessage = "Loading your posts"


sendingToReviewMessage : String
sendingToReviewMessage = "Sending post to be reviewed"


removingPost : String
removingPost = "Removing the post"



-- MISC WORK


loadingPosts : Int
loadingPosts = 1


sendingToReview : Int
sendingToReview = 2


removingWork : Int
removingWork = 4



-- MISC DICT


insertHttpCmd : String -> Cmd Msg -> Model -> Model
insertHttpCmd name http_cmd model =
  { model
  | http_cmds = Dict.insert name http_cmd model.http_cmds
  }



