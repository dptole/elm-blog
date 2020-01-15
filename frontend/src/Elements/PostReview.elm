module Elements.PostReview exposing (..)

import Elements.PostPreview
import Elements.PostShowPrivate

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
  | GotPostsToReviewResponse ( Result Http.Error ( List Utils.Types.Post ) )
  | HidePostDetails
  | AddNote Utils.Types.Post
  | CancelNote
  | TypingNote String
  | PromptPostRejection
  | CancelPostRejection
  | PromptPostPublication
  | ShowPostDetails Utils.Types.Post
  | GotShowPostDetailsResponse ( Result Http.Error Utils.Types.Post )
  | SubmitNewNote Utils.Types.Post
  | GotSubmitNewNoteResponse ( Result Http.Error Utils.Types.Post )
  | PublishPost Utils.Types.Post
  | GotPublishPostResponse ( Result Http.Error Utils.Types.Post )
  | RejectPost Utils.Types.Post
  | GotRejectPostResponse ( Result Http.Error Utils.Types.Post )
  | CancelPostPublication

  -- Elements/PostPreview
  | PostPreviewMsg Elements.PostPreview.Msg



-- MODEL


type alias Model =
  { posts : List Utils.Types.Post
  , work : Int
  , post_details : Maybe Utils.Types.Post
  , new_notes : String
  , error_response : String
  , post_preview : Maybe Elements.PostPreview.Model
  , http_cmds : Dict.Dict String ( Cmd Msg )
  }



-- INIT


initModel : Model
initModel =
  Model
    []                    -- posts
    Utils.Work.notWorking -- work
    Nothing               -- post_details
    ""                    -- new_notes
    ""                    -- error
    Nothing               -- post_preview
    Utils.Funcs.emptyDict -- http_cmds


initModelLoading : Model
initModelLoading =
  Model
    []                    -- posts
    loadingMessage        -- work
    Nothing               -- post_details
    ""                    -- new_notes
    ""                    -- error
    Nothing               -- post_preview
    Utils.Funcs.emptyDict -- http_cmds



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    PromptPostPublication ->
      ( { model
        | work = Utils.Work.addWork promptingPostPublication model.work
        }
      , Cmd.none
      )
    
    PublishPost post ->
      let
        http_cmd = publishPost post.id

        model2 =
          { model
          | work = Utils.Work.addWork publishingPost model.work
          }
      in
        ( { model2
          | work = Utils.Work.removeWork promptingPostPublication model2.work
          , http_cmds = Dict.insert "PublishPost" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotPublishPostResponse _ ->
      let
        http_cmd = getPostsToReview

        model2 = initModelLoading

      in
        ( { model2
          | http_cmds = Dict.insert "PostsToReview" http_cmd model2.http_cmds
          }
        , http_cmd
        )

    RejectPost post ->
      let
        http_cmd = rejectPost post.id

        model2 =
          { model
          | work = Utils.Work.addWork rejectingPost model.work
          }

      in
        ( { model2
          | work = Utils.Work.removeWork promptingPostRejection model2.work
          , http_cmds = Dict.insert "RejectPost" http_cmd model2.http_cmds
          }
        , http_cmd
        )

    GotRejectPostResponse _ ->
      let
        http_cmd = getPostsToReview

        model2 = initModelLoading

      in
        ( { model2
          | http_cmds = Dict.insert "PostsToReview" http_cmd model2.http_cmds
          }
        , http_cmd
        )

    GotPostsToReviewResponse response ->
      let
        new_model =
          { model
          | work = Utils.Work.removeWork loadingMessage model.work
          , http_cmds = Dict.remove "PostsToReview" model.http_cmds
          }
      in
        case response of
          Ok posts ->
            ( { new_model | posts = posts }
            , Cmd.none
            )

          Err _ ->
            ( { new_model | error_response = "Unable to fetch the posts" }
            , Cmd.none
            )

    CancelPostPublication ->
      ( { model
        | work = Utils.Work.removeWork promptingPostPublication model.work
        }
      , Cmd.none
      )

    PromptPostRejection ->
      ( { model
        | work = Utils.Work.addWork promptingPostRejection model.work
        }
      , Cmd.none
      )

    CancelPostRejection ->
      ( { model
        | work = Utils.Work.removeWork promptingPostRejection model.work
        }
      , Cmd.none
      )

    ShowPostDetails post ->
      let
        http_cmd = getPostDetails post.id

      in
        ( { model
          | new_notes = ""
          , work = Utils.Work.addWork fetchingPost model.work
          , http_cmds = Dict.insert "ShowPostDetails" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotShowPostDetailsResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork fetchingPost model.work
          , http_cmds = Dict.remove "ShowPostDetails" model.http_cmds
          }

      in
        case response of
          Ok post ->
            ( { model2
              | post_details = Just post
              , post_preview = Just <| fromPostDetailsToPublishedPost post
              , posts =
                  List.map(\p ->
                    if p.id == post.id then
                      post
                    else
                      p
                  ) model2.posts
              }
            , Cmd.none
            )

          Err _ ->
            ( model2, Cmd.none )

    HidePostDetails ->
      ( { model
        | post_details = Nothing
        , post_preview = Nothing
        }
      , Cmd.none
      )

    AddNote post ->
      ( { model
        | work = Utils.Work.addWork addingNote model.work
        , new_notes = post.notes
        }
      , Cmd.none
      )

    SubmitNewNote post ->
      let
        http_cmd = addPostNotes post.id model.new_notes

      in
      ( { model
        | work = Utils.Work.addWork savingNote model.work
        , http_cmds = Dict.insert "SubmitNewNote" http_cmd model.http_cmds
        }
      , http_cmd
      )

    GotSubmitNewNoteResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork savingNote model.work
          , http_cmds = Dict.remove "SubmitNewNote" model.http_cmds
          }

      in
        case response of
          Ok post ->
            ( { model2
              | post_details = Just post
              , work = Utils.Work.removeWork addingNote model2.work
              }
            , Cmd.none
            )

          Err _ ->
            ( model2, Cmd.none )

    CancelNote ->
      ( { model
        | work = Utils.Work.removeWork addingNote model.work
        , new_notes = ""
        }
      , Cmd.none
      )

    TypingNote note ->
      ( { model | new_notes = note }
      , Cmd.none
      )

    -- Elements/PostPreview
    PostPreviewMsg post_preview_msg ->
      case model.post_preview of
        Just pp_model ->
          let
            ( pp_model2, pp_msg ) =
              Elements.PostPreview.update post_preview_msg pp_model
          in
            ( { model
              | post_preview = Just pp_model2
              }
            , Cmd.map PostPreviewMsg pp_msg
            )

        Nothing ->
          ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
  Html.div
    []
    [ Html.h1
        []
        [ Html.text "Review posts" ]

    , Html.div
        []
        [ Html.text "Review posts created by your editors" ]

    , Html.hr [] []

    , viewPostList model
    ]


viewPostList : Model -> Html.Html Msg
viewPostList model =
  if String.length model.error_response > 0 then
    Html.div
      []
      [ Html.text model.error_response ]

  else if Utils.Work.isWorkingOn loadingMessage model.work then
    Html.div
      [ Html.Attributes.class "loadingdotsafter" ]
      [ Html.text "Loading posts to review" ]

  else if Utils.Work.isWorkingOn fetchingPost model.work then
    Html.div
      [ Html.Attributes.class "loadingdotsafter" ]
      [ Html.text "Fetching post to review" ]

  else if List.length model.posts < 1 then
    Html.div
      []
      [ Html.text "No posts to review!" ]

  else
      Html.table
        ( case model.post_details of
            Just _ ->
              [ Html.Attributes.class "width-100" ]

            Nothing ->
              [ Html.Attributes.class "width-100 hoverable"
              , Html.Attributes.attribute "rules" "rows"
              ]
        )
        [ Html.thead
            []
            ( viewPostsHeader model )

        , Html.tbody
            []
            ( viewPostsList model )

        , Html.tfoot
            []
            ( viewPostsFooter model )
        ]


viewPostsHeader : Model -> List ( Html.Html Msg )
viewPostsHeader model =
  case model.post_details of
    Just post ->
      if Utils.Work.isWorkingOn addingNote model.work then
        [ Html.tr
            []
            [ Html.th
                [ Html.Attributes.colspan 2 ]
                [ Html.text "Post details (Adding note)" ]
            ]
        ]

      else if
        Utils.Work.isWorkingOn rejectingPost model.work ||
        Utils.Work.isWorkingOn promptingPostRejection model.work
      then
        [ Html.tr
            []
            [ Html.th
                [ Html.Attributes.colspan 2 ]
                [ Html.text "Rejecting post..." ]
            ]
        ]

      else if
        Utils.Work.isWorkingOn promptingPostPublication model.work ||
        Utils.Work.isWorkingOn publishingPost model.work
      then
        [ Html.tr
            []
            [ Html.th
                [ Html.Attributes.colspan 2 ]
                [ Html.text "Publishing post..." ]
            ]
        ]

      else
        [ Html.tr
            []
            [ Html.th
                []
                [ Html.text "Post details" ]

            , Html.th
                [ Html.Attributes.align "right" ]
                [ Html.input
                    [ Html.Events.onClick HidePostDetails
                    , Html.Attributes.type_ "button"
                    , Html.Attributes.value "Go back"
                    ]
                    []
                ]
            ]
        ]

    Nothing ->
      if List.length model.posts > 0 then
        [ Html.tr
            []
            [ Html.th
                []
                [ Html.text "Title" ]

            , Html.th
                []
                [ Html.text "Pages" ]

            , Html.th
                []
                [ Html.text "Tags" ]
            ]
        ]

      else
        []


viewPostsList : Model -> List ( Html.Html Msg )
viewPostsList model =
  case model.post_details of
    Just post ->
      let
        is_adding_notes = Utils.Work.isWorkingOn addingNote model.work
        is_saving_note = Utils.Work.isWorkingOn savingNote model.work

        notes =
          if String.length post.notes > 0 then
            post.notes
          else
            "<No notes>"

        add_note_html =
          if is_adding_notes then
            [ Html.text "Notes: "
            , Html.input
                [ Html.Attributes.type_ "input"
                , Html.Attributes.value model.new_notes
                , Html.Attributes.autofocus True
                , Html.Attributes.disabled is_saving_note
                , Html.Events.onInput TypingNote
                ]
                []

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Submit"
                , Html.Attributes.class "btn-create"
                , Html.Attributes.disabled is_saving_note
                , Html.Events.onClick <| SubmitNewNote post
                ]
                []

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Cancel"
                , Html.Attributes.disabled is_saving_note
                , Html.Events.onClick <| CancelNote
                ]
                []
            ]
          else
            [ Html.text <| "Notes: " ++ notes ]

        tags =
          case post.tags of
            x :: xs -> String.join ", " post.tags
            _ -> "<No tags>"

        post_preview_model =
          Maybe.withDefault
          ( fromPostDetailsToPublishedPost post )
          model.post_preview

      in
        [ Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2 ]
                [ "Id: " ++ post.id |> Html.text ]
            ]

        , Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2 ]
                [ "Author id: " ++ post.author_id |> Html.text ]
            ]

        , Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2
                , Html.Attributes.class "post-review-add-note"
                ]
                add_note_html
            ]

        , Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2 ]
                [ "Title: " ++ post.title |> Html.text ]
            ]

        , Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2 ]
                [ Elements.PostShowPrivate.fromPostStatusToString post.status
                    |> (++) "Status: "
                    |> Html.text
                ]
            ]

        , Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2 ]
                [ Html.text <| "Tags: " ++ tags ]
            ]

        , Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2 ]
                [ viewPageCount post_preview_model post |> Html.text ]
            ]

        , Html.tr
            []
            [ Html.td
                [ Html.Attributes.colspan 2 ]
                [ Elements.PostPreview.view post_preview_model
                    |> Html.map PostPreviewMsg
                ]
            ]
        ]

    Nothing ->
      List.concatMap (\post ->
        let
          tags =
            case post.tags of
              x :: xs -> String.join ", " post.tags
              _ -> "<No tags>"

          remove_button =
            Html.input
              [ Html.Events.onClick <| ShowPostDetails post
              , Html.Attributes.type_ "button"
              , Html.Attributes.value "Details"
              ]
              []

          buttons = [ remove_button ]

        in
          [ Html.tr
              [ Html.Attributes.class "post-review-details-post" ]
              [ Html.td
                  []
                  [ Html.text post.title ]

              , Html.td
                  []
                  [ List.length post.pages
                      |> (+) 1
                      |> String.fromInt
                      |> Html.text
                  ]

              , Html.td
                  []
                  [ Html.text tags ]
              ]

          , Html.tr
              [ Html.Attributes.class "post-review-actions" ]
              [ Html.td
                  [ Html.Attributes.colspan 3 ]
                  buttons
              ]
          ]
      ) model.posts


viewPostsFooter : Model -> List ( Html.Html Msg )
viewPostsFooter model =
  let
    is_rejecting_post = Utils.Work.isWorkingOn rejectingPost model.work

    is_adding_note = Utils.Work.isWorkingOn addingNote model.work

    is_prompting_post_rejection =
      Utils.Work.isWorkingOn promptingPostRejection model.work

    is_prompting_post_publication =
      Utils.Work.isWorkingOn promptingPostPublication model.work

    is_publishing_post =
      Utils.Work.isWorkingOn publishingPost model.work

  in
    if is_rejecting_post || is_adding_note || is_publishing_post then
      []

    else if is_prompting_post_rejection then
      case model.post_details of
        Just post ->
          [ Html.tr
              []
              [ Html.td
                  [ Html.Attributes.colspan 2 ]
                  [ Html.text "Are you sure?" ]
              ]

          , Html.tr
              []
              [ Html.td
                  [ Html.Attributes.colspan 2
                  , Html.Attributes.class "post-review-prompt-rejection"
                  ]
                  [ Html.input
                      [ Html.Attributes.value "Yes"
                      , Html.Attributes.type_ "button"
                      , Html.Attributes.class "btn-danger"
                      , Html.Events.onClick <| RejectPost post
                      ]
                      []

                  , Html.input
                      [ Html.Attributes.value "No"
                      , Html.Attributes.type_ "button"
                      , Html.Events.onClick CancelPostRejection
                      ]
                      []
                  ]
              ]
          ]

        Nothing ->
          []

    else if is_prompting_post_publication then
      case model.post_details of
        Just post ->
          [ Html.tr
              []
              [ Html.td
                  [ Html.Attributes.colspan 2 ]
                  [ Html.text "Are you sure?" ]
              ]

          , Html.tr
              []
              [ Html.td
                  [ Html.Attributes.colspan 2
                  , Html.Attributes.class "post-review-prompt-publication"
                  ]
                  [ Html.input
                      [ Html.Attributes.value "Yes"
                      , Html.Attributes.class "btn-create"
                      , Html.Attributes.type_ "button"
                      , Html.Events.onClick <| PublishPost post
                      ]
                      []

                  , Html.input
                      [ Html.Attributes.value "No"
                      , Html.Attributes.type_ "button"
                      , Html.Events.onClick CancelPostPublication
                      ]
                      []
                  ]
              ]
          ]

        Nothing ->
          []

    else
      case model.post_details of
        Just post ->
          [ Html.tr
              []
              [ Html.td
                  [ Html.Attributes.colspan 2
                  , Html.Attributes.class "post-review-control"
                  ]
                  [ Html.input
                      [ Html.Attributes.value "Add note"
                      , Html.Attributes.type_ "button"
                      , Html.Events.onClick <| AddNote post
                      ]
                      []

                  , Html.input
                      [ Html.Attributes.value "Send back to the editor"
                      , Html.Attributes.class "btn-create"
                      , Html.Events.onClick PromptPostRejection
                      , Html.Attributes.type_ "button"
                      ]
                      []

                  , Html.input
                      [ Html.Attributes.value "Publish"
                      , Html.Attributes.class "btn-danger"
                      , Html.Events.onClick PromptPostPublication
                      , Html.Attributes.type_ "button"
                      ]
                      []
                  ]
              ]
          ]

        Nothing ->
          []


viewPageCount : Elements.PostPreview.Model -> Utils.Types.Post -> String
viewPageCount post_preview_model post =
  let
    current_page = post_preview_model.preview_page + 1 |> String.fromInt
    total_pages = List.length post.pages |> String.fromInt
  in
    "Page: " ++ current_page ++ "/" ++ total_pages



-- MISC


-- MISC GETTERS


getPostsToReview : Cmd Msg
getPostsToReview =
  Utils.Api.getPostsToReview
    GotPostsToReviewResponse
    Utils.Decoders.postsForReviewResponse


addPostNotes : String -> String -> Cmd Msg
addPostNotes post_id notes =
  Utils.Api.addPostNotes
    post_id
    ( Utils.Encoders.postNotes notes )
    GotSubmitNewNoteResponse
    Utils.Decoders.post


rejectPost : String -> Cmd Msg
rejectPost post_id =
  Utils.Api.updatePostStatus
    post_id
    ( Utils.Encoders.postStatus Utils.Types.PostStatusDraft )
    GotRejectPostResponse
    Utils.Decoders.post


publishPost : String -> Cmd Msg
publishPost post_id =
  Utils.Api.updatePostStatus
    post_id
    ( Utils.Encoders.postStatus Utils.Types.PostStatusPublished )
    GotPublishPostResponse
    Utils.Decoders.post


getPostDetails : String -> Cmd Msg
getPostDetails post_id =
  Utils.Api.getPostToReview
    post_id
    GotShowPostDetailsResponse
    Utils.Decoders.post



-- MISC WORK


loadingMessage : Int
loadingMessage = 1


addingNote : Int
addingNote = 2


savingNote : Int
savingNote = 4


rejectingPost : Int
rejectingPost = 8


promptingPostRejection : Int
promptingPostRejection = 16


promptingPostPublication : Int
promptingPostPublication = 32


publishingPost : Int
publishingPost = 64


fetchingPost : Int
fetchingPost = 128



-- MISC ELEMENTS POST CREATE


fromPostDetailsToPublishedPost : Utils.Types.Post -> Elements.PostPreview.Model
fromPostDetailsToPublishedPost post =
  Elements.PostPreview.initModelFromPublishedPost
    ( Utils.Types.PublishedPost
        post.id
        "YYYY-MM-DDTHH:II:SS.XXXZ"
        post.title
        post.status
        post.tags
        post.pages
        ( Utils.Types.AuthUser
            post.author_id
            ""
        )
    )




