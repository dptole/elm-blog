module Elements.CommentReview exposing (..)

import Elements.PostComments
import Elements.PostPreview

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
  | PublishComment
  | GotPublishCommentResponse ( Result Http.Error Utils.Types.PostComment )
  | FetchReviewComments
  | GotFetchReviewCommentsResponse ( Result Http.Error ( List Utils.Types.PostComment ) )
  | CommentDetails Utils.Types.PostComment
  | GotCommentDetailsResponse ( Result Http.Error Utils.Types.PostCommentReviewDetails )
  | RejectComment
  | GotRejectCommentResponse ( Result Http.Error Utils.Types.PostComment )
  | ReturnToReviewList
  | PromptPublishComment ( Utils.Types.PromptResponse Utils.Types.PostCommentReviewDetails )
  | PromptRejectComment ( Utils.Types.PromptResponse Utils.Types.PostCommentReviewDetails )

  -- Elements/PostPreview
  | PostPreviewMsg Elements.PostPreview.Msg

  -- Elements/PostComments
  | PostCommentsMsg Elements.PostComments.Msg



-- MODEL


type alias Model =
  { work : Int
  , comments : List Utils.Types.PostComment
  , comment_details : Maybe Utils.Types.PostCommentReviewDetails
  , post_preview : Elements.PostPreview.Model
  , post_comments : Elements.PostComments.Model
  , comment_id_detail : Maybe String
  , http_cmds : Dict.Dict String ( Cmd Msg )
  , flags : Utils.Types.MainModelFlags
  }


initModel : Utils.Types.MainModelFlags -> Model
initModel flags =
  Model
    Utils.Work.notWorking                     -- work
    []                                        -- comments
    Nothing                                   -- comment_details
    Elements.PostPreview.initModel            -- post_preview
    ( Elements.PostComments.initModel flags ) -- post_comments
    Nothing                                   -- comment_id_detail
    Utils.Funcs.emptyDict                     -- http_cmds
    flags                                     -- flags


initModelFetchingReviewComments : Utils.Types.MainModelFlags -> Model
initModelFetchingReviewComments flags =
  Model
    fetchingReviewComments                    -- work
    []                                        -- comments
    Nothing                                   -- comment_details
    Elements.PostPreview.initModel            -- post_preview
    ( Elements.PostComments.initModel flags ) -- post_comments
    Nothing                                   -- comment_id_detail
    Utils.Funcs.emptyDict                     -- http_cmds
    flags                                     -- flags



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    FetchReviewComments ->
      let
        http_cmd =
          Utils.Api.getCommentsReviews
            model.flags.api
            GotFetchReviewCommentsResponse
            Utils.Decoders.postComments

        model2 = initModelFetchingReviewComments model.flags

      in
        ( { model2
          | http_cmds = Dict.insert "FetchReviewComments" http_cmd model2.http_cmds
          }
        , http_cmd
        )

    GotFetchReviewCommentsResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork fetchingReviewComments model.work
          , http_cmds = Dict.remove "FetchReviewComments" model.http_cmds
          }

      in
        case response of
          Ok post_comments ->
            ( { model2
              | comments = post_comments
              }
            , Cmd.none
            )

          Err _ ->
            ( model2, Cmd.none )

    CommentDetails comment ->
      let
        http_cmd =
          Utils.Api.getCommentsReviewDetails
            model.flags.api
            comment.id
            GotCommentDetailsResponse
            Utils.Decoders.postCommentReviewDetails

      in
        ( { model
          | work = Utils.Work.addWork fetchingCommentDetails model.work
          , comment_id_detail = Just comment.id
          , http_cmds = Dict.insert "CommentDetails" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotCommentDetailsResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork fetchingCommentDetails model.work
          , http_cmds = Dict.remove "CommentDetails" model.http_cmds
          }

      in
        case response of
          Ok comment_details ->
            let
              post_preview =
                Elements.PostPreview.initModelFromPublishedPost
                  comment_details.post

              post_preview2 =
                { post_preview
                | preview_page = comment_details.comment.page_index
                , work =
                    Utils.Work.addWork
                      Elements.PostPreview.reviewingComment
                      post_preview.work
                }

              post_comments =
                Elements.PostComments.initModelToCommentReview
                  model.flags
                  [comment_details.comment]

              post_comments2 =
                { post_comments
                | page_index = comment_details.comment.page_index
                , work =
                    Utils.Work.addWork
                      Elements.PostComments.reviewingComment
                      post_comments.work
                }

            in
              ( { model2
                | comment_details = Just comment_details
                , post_preview = post_preview2
                , post_comments = post_comments2
                }
              , Cmd.none
              )

          Err _ ->
            ( model2, Cmd.none )

    ReturnToReviewList ->
      {-
        This action is here so that the module that controls
        Browser.application can be notified of such event and take
        appropriate action
      -}
      ( model, Cmd.none )

    PublishComment ->
      ( { model
        | work = Utils.Work.addWork publishComment model.work
        }
      , Cmd.none
      )

    GotPublishCommentResponse response ->
      update
        FetchReviewComments
        { model
        | http_cmds = Dict.remove "PromptPublishComment" model.http_cmds
        }

    PromptPublishComment prompt_response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork publishComment model.work
          }

      in
        case prompt_response of
          Utils.Types.PromptResponseNo ->
            ( model2
            , Cmd.none
            )

          Utils.Types.PromptResponseYes comment_details ->
            case model2.comment_id_detail of
              Just comment_id ->
                let
                  http_cmd =
                    Utils.Api.publishComment
                      model.flags.api
                      comment_id
                      GotPublishCommentResponse
                      Utils.Decoders.postComment

                in
                  ( { model2
                    | work = Utils.Work.addWork publishingComment model2.work
                    , http_cmds = Dict.insert "PromptPublishComment" http_cmd model2.http_cmds
                    }
                  , http_cmd
                  )

              Nothing ->
                ( model2
                , Cmd.none
                )

    RejectComment ->
      ( { model
        | work = Utils.Work.addWork rejectComment model.work
        }
      , Cmd.none
      )

    GotRejectCommentResponse response ->
      update
        FetchReviewComments
        { model
        | http_cmds = Dict.remove "PromptRejectComment" model.http_cmds
        }

    PromptRejectComment prompt_response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork rejectComment model.work
          }

      in
        case prompt_response of
          Utils.Types.PromptResponseNo ->
            ( model2
            , Cmd.none
            )

          Utils.Types.PromptResponseYes comment_details ->
            case model2.comment_id_detail of
              Just comment_id ->
                let
                  http_cmd =
                    Utils.Api.rejectComment
                      model.flags.api
                      comment_id
                      GotRejectCommentResponse
                      Utils.Decoders.postComment

                in
                  ( { model2
                    | work = Utils.Work.addWork rejectingComment model2.work
                    , http_cmds = Dict.insert "PromptRejectComment" http_cmd model2.http_cmds
                    }
                  , http_cmd
                  )

              Nothing ->
                ( model2
                , Cmd.none
                )

    -- Elements/PostPreview
    PostPreviewMsg post_preview_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            post_preview_msg
            model.post_preview
            Elements.PostPreview.update
            updatePostPreviewModel
            PostPreviewMsg

      in
        defaultBehavior model

    -- Elements/PostComments
    PostCommentsMsg post_comments_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            post_comments_msg
            model.post_comments
            Elements.PostComments.update
            updatePostCommentsModel
            PostCommentsMsg

      in
        defaultBehavior model



-- VIEW


view : Model -> Html.Html Msg
view model =
  let
    content =
      case model.comment_details of
        Nothing ->
          viewCommentList model

        _ ->
          viewCommentDetails model

    total_comments = List.length model.comments

    total_in_title =
      if total_comments > 0 then
        " (" ++ ( String.fromInt total_comments ) ++ ")"
      else
        ""

  in
    Html.div
      []
      [ Html.h1 [] [ Html.text ( "Review comments" ++ total_in_title ) ]
      , Html.div [] [ Html.text "Comments for you to review" ]
      , Html.hr [] []
      , content
      ]


viewCommentList : Model -> Html.Html Msg
viewCommentList model =
  if Utils.Work.isWorkingOn fetchingCommentDetails model.work then
    Html.div
      [ Html.Attributes.class "loadingdotsafter" ]
      [ Html.text "Fetching comment details" ]

  else if Utils.Work.isWorkingOn fetchingReviewComments model.work then
    Html.div
      [ Html.Attributes.class "loadingdotsafter" ]
      [ Html.text "Fetching comments" ]

  else
    viewCommentsTable model


viewCommentDetails : Model -> Html.Html Msg
viewCommentDetails model =
  let
    buttons =
      case model.comment_details of
        Just comment_details ->
          if Utils.Work.isWorkingOn publishingComment model.work then
            [ Html.div
                [ Html.Attributes.class "loadingdotsafter" ]
                [ Html.text "Publishing comment" ]
            ]

          else if Utils.Work.isWorkingOn rejectingComment model.work then
            [ Html.div
                [ Html.Attributes.class "loadingdotsafter" ]
                [ Html.text "Rejecting comment" ]
            ]

          else if Utils.Work.isWorkingOn publishComment model.work then
            [ Html.div
                []
                [ Html.text "Publish the comment?" ]

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Yes"
                , Html.Attributes.class "btn-create"
                , Html.Events.onClick
                    <| PromptPublishComment
                    <| Utils.Types.PromptResponseYes comment_details
                ]
                []

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "No"
                , Html.Events.onClick
                    <| PromptPublishComment Utils.Types.PromptResponseNo
                ]
                []
            ]

          else if Utils.Work.isWorkingOn rejectComment model.work then
            [ Html.div
                []
                [ Html.text "Reject the comment?" ]

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Yes"
                , Html.Attributes.class "btn-danger"
                , Html.Events.onClick
                    <| PromptRejectComment
                    <| Utils.Types.PromptResponseYes comment_details
                ]
                []

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "No"
                , Html.Events.onClick
                    <| PromptRejectComment Utils.Types.PromptResponseNo
                ]
                []
            ]

          else
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Publish comment"
                , Html.Attributes.class "btn-create"
                , Html.Events.onClick PublishComment
                ]
                []

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Reject comment"
                , Html.Attributes.class "btn-danger"
                , Html.Events.onClick RejectComment
                ]
                []

            , Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Return"
                , Html.Events.onClick ReturnToReviewList
                ]
                []

            ]

        Nothing ->
          []

  in
    Html.div
      []
      [ Html.map PostPreviewMsg
          ( Elements.PostPreview.view model.post_preview )

      , Html.hr [] []

      , Html.map PostCommentsMsg
          ( Elements.PostComments.view model.post_comments )

      , Html.hr [] []

      , Html.div
          [ Html.Attributes.class "comment-review-control" ]
          buttons
      ]


viewCommentsTable : Model -> Html.Html Msg
viewCommentsTable model =
  if List.length model.comments < 1 then
    Html.div
      []
      [ Html.text "No comments to review!" ]

  else
    Html.table
      [ Html.Attributes.attribute "rules" "rows"
      , Html.Attributes.class "hoverable comment-review"
      ]
      [ Html.thead
          []
          [ Html.tr
              []
              [ Html.th
                  []
                  [ Html.text "Author" ]

              , Html.th
                  []
                  [ Html.text "Message" ]

              , Html.th
                  []
                  [ Html.text "Is a reply?" ]

              , Html.th
                  []
                  [ Html.text "Created at" ]
              ]
          ]

      , Html.tbody
          []
          ( List.concatMap viewComment model.comments )

      , Html.tfoot
          []
          []
      ]


viewComment : Utils.Types.PostComment -> List ( Html.Html Msg )
viewComment comment =
  let
    is_a_reply =
      case comment.reply_to_comment_id of
        Nothing -> "No"
        _ -> "Yes"

  in
    [ Html.tr
        [ Html.Attributes.class "comment-review-content" ]
        [ Html.td
            []
            [ Html.text comment.author.username ]

        , Html.td
            []
            [ Html.text comment.message ]

        , Html.td
            []
            [ Html.text is_a_reply ]

        , Html.td
            []
            [ Html.text comment.created_at ]
        ]

    , Html.tr
        [ Html.Attributes.class "comment-review-actions" ]
        [ Html.td
            [ Html.Attributes.colspan 4 ]
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.value "Details"
                , Html.Events.onClick <| CommentDetails comment
                ]
                []
            ]
        ]
    ]



-- MISC


-- MISC WORK


fetchingReviewComments : Int
fetchingReviewComments = 1


fetchingCommentDetails : Int
fetchingCommentDetails = 2


publishComment : Int
publishComment = 4


rejectComment : Int
rejectComment = 8


publishingComment : Int
publishingComment = 16


rejectingComment : Int
rejectingComment = 32



-- MISC UPDATE MODEL


updatePostPreviewModel : Elements.PostPreview.Model -> Model -> Model
updatePostPreviewModel new_post_preview model =
  { model | post_preview = new_post_preview }


updatePostCommentsModel : Elements.PostComments.Model -> Model -> Model
updatePostCommentsModel new_post_comments model =
  { model | post_comments = new_post_comments }





