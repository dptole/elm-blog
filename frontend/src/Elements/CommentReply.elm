module Elements.CommentReply exposing (..)

import Utils.Api
import Utils.Decoders
import Utils.Encoders
import Utils.Funcs
import Utils.Routes
import Utils.Types
import Utils.Work

import Dict
import Html
import Html.Attributes
import Html.Events
import Http
import Json.Decode



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | OpenReplyComment Utils.Types.PostComment Int
  | CloseReplyComment
  | TypingReplyComment String
  | FetchReplies
  | GotFetchRepliesResponse ( Result Http.Error ( List Utils.Types.CommentsReplies ) )
  | SubmitReplyComment
  | GotSubmitReplyCommentResponse ( Result Http.Error () )



-- MODEL


type alias Model =
  { replies : List Utils.Types.CommentsReplies
  , work : Int
  , date_time : String
  , replying_to :
      Maybe
        { comment : Utils.Types.PostComment
        , index : Int
        }
  , replying_message : String
  , http_cmds : Dict.Dict String ( Cmd Msg )
  , flags : Utils.Types.MainModelFlags
  }


initModel : Utils.Types.MainModelFlags -> Model
initModel flags =
  Model
    []                    -- replies
    Utils.Work.notWorking -- work
    ""                    -- date_time
    Nothing               -- replying_to
    ""                    -- replying_message
    Utils.Funcs.emptyDict -- http_cmds
    flags                 -- flags



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SpecialMsg _ ->
      -- Handled by the module that owns Browser.application
      ( model, Cmd.none )

    FetchReplies ->
      let
        http_cmd =
          Utils.Api.getCommentsReplies
            model.flags.api
            GotFetchRepliesResponse
            Utils.Decoders.commentReplies

      in
        ( { model
          | work = Utils.Work.addWork fetchingReplies model.work
          , http_cmds = Dict.insert "FetchReplies" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotFetchRepliesResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork fetchingReplies model.work
          , http_cmds = Dict.remove "FetchReplies" model.http_cmds
          }

      in
        case response of
          Ok replies ->
            ( { model2
              | replies = replies
              }
            , Cmd.none
            )

          Err _ ->
            ( model2
            , Cmd.none
            )

    CloseReplyComment ->
      ( { model
        | replying_to = Nothing
        }
      , Cmd.none
      )

    OpenReplyComment comment index ->
      ( { model
        | replying_to = Just { comment = comment, index = index }
        }
      , Cmd.none
      )

    TypingReplyComment message ->
      ( { model
        | replying_message = message
        }
      , Cmd.none
      )

    SubmitReplyComment ->
      case model.replying_to of
        Just { comment } ->
          let
            http_cmd =
              Utils.Api.justReplyComment
                model.flags.api
                comment.id
                ( Utils.Encoders.replyComment model.replying_message )
                GotSubmitReplyCommentResponse

          in
            ( { model
              | work = Utils.Work.addWork submittingReply model.work
              , http_cmds = Dict.insert "SubmitReplyComment" http_cmd model.http_cmds
              }
            , http_cmd
            )

        Nothing ->
          ( model, Cmd.none )

    GotSubmitReplyCommentResponse _ ->
      update
        FetchReplies
        ( initModel model.flags )



-- VIEW


view : Model -> Html.Html Msg
view model =
  Html.div
    []
    [ Html.h1
        []
        [ Html.text "Replies" ]

    , Html.text "Replies to your comments"

    , Html.hr [] []

    , if Utils.Work.isWorkingOn fetchingReplies model.work then
        Html.div
          [ Html.Attributes.class "loadingdotsafter" ]
          [ Html.text "Fetching replies" ]

      else
        viewPostsList model

    ]


viewPostsList : Model -> Html.Html Msg
viewPostsList model =
  Html.div
    []
    ( List.indexedMap ( viewPostItem model ) model.replies
        |> List.intersperse ( Html.hr [] [] )
    )


viewPostItem : Model -> Int -> Utils.Types.CommentsReplies -> Html.Html Msg
viewPostItem model index item =
  let
    total_threads =
      List.length item.comments
        |> String.fromInt

    replies_html =
      viewCommentsList model item.comments

    link =
      Utils.Routes.buildRoute
        [ item.post.id ]
        Utils.Routes.readPost

  in
    Html.div
      [ Html.Attributes.class "comment-replies-container" ]
      [ Html.h3
          []
          [ Html.span
              []
              [ Html.text "Post: " ]

          , Html.a
              [ Html.Attributes.href link ]
              [ Html.text item.post.title ]

          , Html.span
              []
              [ Html.text <| " (" ++ total_threads ++ ")" ]
          ]

      , Html.div
          []
          [ Html.input
              [ Html.Attributes.type_ "checkbox"
              , Html.Attributes.id <| "comment_reply_expand_" ++ ( String.fromInt index )
              , Html.Attributes.class "comment-reply-expand"
              ]
              []

          , replies_html
          ]
      ]


viewCommentsList : Model -> List Utils.Types.PostComment -> Html.Html Msg
viewCommentsList model comments =
  Html.div
    [ Html.Attributes.class "comment-reply-container" ]
    ( List.indexedMap ( viewCommentItem model ) comments )


viewCommentItem : Model -> Int -> Utils.Types.PostComment -> Html.Html Msg
viewCommentItem model index comment =
  let
    replies =
      case comment.replies of
        Utils.Types.PostCommentReplies r ->
          r

    published =
      Utils.Funcs.iso8601HumanDateDiff
        model.date_time
        comment.created_at

  in
    Html.fieldset
      [ Html.Attributes.class "comment-reply-recursive" ]
      [ Html.legend
          []
          [ Html.text <|
              "Author: " ++ comment.author.username ++
              ", published " ++ published
          ]

      , Html.div
          []
          [ Html.text <| "Comment: " ++ comment.message ]

      , viewReplySection model index comment

      , viewCommentsList model replies
      ]


viewReplySection : Model -> Int -> Utils.Types.PostComment -> Html.Html Msg
viewReplySection model comment_index comment_to_render =
  let
    is_submitting_reply = Utils.Work.isWorkingOn submittingReply model.work

  in
    case model.replying_to of
      Just { comment, index } ->
        if comment_to_render.id == comment.id && index == comment_index then
          Html.div
            []
            [ Html.div
                []
                [ Html.textarea
                    [ Html.Events.onInput TypingReplyComment
                    , Html.Attributes.disabled is_submitting_reply
                    ]
                    []

                ]

            , if is_submitting_reply then
                Html.div
                  [ Html.Attributes.class "loadingdotsafter" ]
                  [ Html.text "Submitting reply to review" ]

              else
                Html.div
                  [ Html.Attributes.class "comment-reply-control" ]
                  [ Html.input
                      [ Html.Attributes.type_ "button"
                      , Html.Attributes.class "btn-create"
                      , Html.Attributes.value "Submit"
                      , Html.Events.onClick SubmitReplyComment
                      ]
                      []

                  , Html.input
                      [ Html.Attributes.type_ "button"
                      , Html.Attributes.value "Cancel"
                      , Html.Events.onClick CloseReplyComment
                      ]
                      []
                  ]
            ]

        else
          if is_submitting_reply then
            Html.div
              []
              []

          else
            viewReplyButton comment_to_render comment_index

      Nothing ->
        if is_submitting_reply then
          Html.div
            []
            []

        else
          viewReplyButton comment_to_render comment_index


viewReplyButton : Utils.Types.PostComment -> Int -> Html.Html Msg
viewReplyButton comment index =
  Html.div
    []
    [ Html.input
        [ Html.Attributes.type_ "button"
        , Html.Attributes.class "btn-create"
        , Html.Attributes.value "Reply"
        , Html.Events.onClick <| OpenReplyComment comment index
        ]
        []
    ]



-- MISC

-- MISC WORK


fetchingReplies : Int
fetchingReplies = 1


submittingReply : Int
submittingReply = 2





