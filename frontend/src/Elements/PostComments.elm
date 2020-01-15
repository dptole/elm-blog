module Elements.PostComments exposing (..)

import Elements.Profile
import Langs.Avatar
import Svg.Comments

import Utils.Api
import Utils.Css
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
import Svg



-- ACTIONS


type Msg
  = SpecialMsg Utils.Types.SpecialMsg
  | TypingComment String
  | SubmitReplyComment
  | GotSubmitReplyComment ( Result Http.Error Utils.Types.PostComment )
  | SubmitComment
  | GotSubmittedCommentResponse ( Result Http.Error Utils.Types.PostComment )
  | LoadComments
  | GotLoadCommentsResponse ( Result Http.Error ( List Utils.Types.PostComment ) )
  | ViewReplies Int String
  | PromptReplyComment
  | TypingReply String
  | CancelPromptReply
  | ShowAvatar
  | GotShowAvatarResponse ( Result Http.Error Utils.Types.UserAvatar )
  | HideAvatar

  -- Svg/Comments
  | SvgCommentsMsg Svg.Comments.Msg

  -- Elements/Profile
  | ProfileMsg Elements.Profile.Msg



-- MODEL


type alias CommentBlock =
  { close_expanded_comment : List ( Html.Html Msg )
  , arrow_up : List ( Html.Html Msg )
  , load_comments : List ( Html.Html Msg )
  , arrow_left : List ( Html.Html Msg )
  , content : List ( Html.Html Msg )
  , arrow_right : List ( Html.Html Msg )
  , cancel_reply : List ( Html.Html Msg )
  , arrow_down : List ( Html.Html Msg )
  , reply_to_comment : List ( Html.Html Msg )
  }


type alias Model =
  { comments : Utils.Types.CommentsForPost
  , new_comment : String
  , svg_comments : Utils.Types.SvgCommentsModel
  , post_id : String
  , page_index : Int
  , work : Int
  , reply_comment : String
  , is_logged_in : Bool
  , avatar : Maybe ( List Utils.Types.AvatarDrawingCmd )
  , http_cmds : Dict.Dict String ( Cmd Msg )
  , date_time : String
  }



-- INIT


initModel : Model
initModel =
  Model
    Utils.Types.CommentsForPostNotReady -- comments
    ""                                  -- new_comment
    Svg.Comments.initModel              -- svg_comments
    ""                                  -- post_id
    0                                   -- page_index
    Utils.Work.notWorking               -- work
    ""                                  -- reply_comment
    False                               -- is_logged_in
    Nothing                             -- avatar
    Utils.Funcs.emptyDict               -- http_cmds
    ""                                  -- date_time


initModelToCommentReview : List Utils.Types.PostComment -> Model
initModelToCommentReview post_comments =
  Model
    ( Utils.Types.CommentsForPostLoaded
        post_comments
    )                                       -- comments
    ""                                      -- new_comment
    ( Svg.Comments.initModelToCommentReview
        post_comments
    )                                       -- svg_comments
    ""                                      -- post_id
    0                                       -- page_index
    Utils.Work.notWorking                   -- work
    ""                                      -- reply_comment
    False                                   -- is_logged_in
    Nothing                                 -- avatar
    Utils.Funcs.emptyDict                   -- http_cmds
    ""                                      -- date_time


initModelFromPostIdPageIndex : String -> Int -> Model -> Model
initModelFromPostIdPageIndex post_id page_index model =
  let
    model2 = initModel
  in
    { model2
    | post_id = post_id
    , page_index = page_index
    , is_logged_in = model.is_logged_in
    }


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

    LoadComments ->
      ( { model
        | comments =
            Utils.Types.CommentsForPostLoading
              model.post_id
              model.page_index
        }
      , Utils.Api.getPostComment
          model.post_id
          model.page_index
          GotLoadCommentsResponse
          Utils.Decoders.postComments
      )

    GotLoadCommentsResponse response ->
      case response of
        Ok post_comments ->
          ( { model
            | comments = Utils.Types.CommentsForPostLoaded post_comments
            , svg_comments =
                Svg.Comments.initModelFromPostComment post_comments
            }
          , Cmd.none
          )

        Err _ ->
          case model.comments of
            Utils.Types.CommentsForPostLoading post_id page_index ->
              ( resetComments post_id page_index model
              , Cmd.none
              )

            Utils.Types.CommentsForPostReady post_id page_index ->
              ( resetComments post_id page_index model
              , Cmd.none
              )

            _ ->
              ( { model
                | comments = Utils.Types.CommentsForPostNotReady
                }
              , Cmd.none
              )

    TypingComment comment ->
      ( { model | new_comment = comment }, Cmd.none )

    TypingReply reply ->
      ( { model | reply_comment = reply }, Cmd.none )

    SubmitComment ->
      let
        http_cmd =
          Utils.Api.createComment
            model.post_id
            model.page_index
            ( Utils.Encoders.createComment model.new_comment )
            GotSubmittedCommentResponse
            Utils.Decoders.postComment

      in
        ( { model
          | work = Utils.Work.addWork submittingComment model.work
          , http_cmds = Dict.insert "SubmitComment" http_cmd model.http_cmds
          }
        , http_cmd
        )

    GotSubmittedCommentResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork submittingComment model.work
          , http_cmds = Dict.remove "SubmitComment" model.http_cmds
          }
      in
        case response of
          Ok _ ->
            ( { model2
              | new_comment = ""
              }
            , Cmd.none
            )

          Err _ ->
            ( model2
            , Cmd.none
            )

    ViewReplies index comment_id ->
      ( model, Cmd.none )

    PromptReplyComment ->
      ( { model
        | work = Utils.Work.addWork promptAnswering model.work
        }
      , Cmd.none
      )

    CancelPromptReply ->
      ( { model
        | work = Utils.Work.removeWork promptAnswering model.work
        , reply_comment = ""
        }
      , Cmd.none
      )

    SubmitReplyComment ->
      case getFocusedComment model of
        Just focused_comment ->
          let
            http_cmd =
              Utils.Api.replyComment
                focused_comment.id
                ( Utils.Encoders.replyComment model.reply_comment )
                GotSubmitReplyComment
                Utils.Decoders.postComment

          in
            ( { model
              | work = Utils.Work.addWork replyingComment model.work
              , http_cmds = Dict.insert "SubmitReplyComment" http_cmd model.http_cmds
              }
            , http_cmd
            )

        Nothing ->
          ( model, Cmd.none )

    GotSubmitReplyComment response ->
      update
        ( SvgCommentsMsg Svg.Comments.HideExpandedComment )
        { model
        | work = Utils.Work.removeWork replyingComment model.work
        , reply_comment = ""
        , http_cmds = Dict.remove "SubmitReplyComment" model.http_cmds
        }

    HideAvatar ->
      ( { model
        | avatar = Nothing
        }
      , Cmd.none
      )

    ShowAvatar ->
      case getFocusedComment model of
        Just focused_comment ->
          ( { model
            | work = Utils.Work.addWork gettingAvatar model.work
            , avatar = Nothing
            }
          , Utils.Api.getAvatar
              focused_comment.author.id
              GotShowAvatarResponse
              Utils.Decoders.userAvatar
          )

        Nothing ->
          ( model, Cmd.none )

    GotShowAvatarResponse response ->
      let
        model2 =
          { model
          | work = Utils.Work.removeWork gettingAvatar model.work
          }
      in
        case response of
          Ok av ->
            case Langs.Avatar.decode av.avatar of
              Ok drawing_cmds ->
                ( { model2
                  | avatar = Just drawing_cmds
                  }
                , Cmd.none
                )

              Err _ ->
                ( model2, Cmd.none )

          Err _ ->
            ( model2, Cmd.none )

    -- Svg/Comments
    SvgCommentsMsg svg_comments_msg ->
      let
        defaultBehavior : Model -> ( Model, Cmd Msg )
        defaultBehavior =
          Utils.Funcs.redirectMsgToSubModule
            svg_comments_msg
            model.svg_comments
            Svg.Comments.update
            updateModelSvgCommentsModel
            SvgCommentsMsg

      in
        case svg_comments_msg of
          Svg.Comments.GotCommentsAfterResponse response ->
            let
              ( model2, cmd2 ) = defaultBehavior model
            in
              case response of
                Ok post_comments ->
                  ( appendPostCommentsAfter post_comments model2
                  , cmd2
                  )

                Err _ ->
                  ( model2, cmd2 )

          Svg.Comments.GotCommentRepliesResponse response ->
            let
              ( model2, cmd2 ) = defaultBehavior model
            in
              case response of
                Ok post_comments ->
                  ( appendPostCommentsReplies post_comments model2
                  , cmd2
                  )

                Err _ ->
                  ( model2, cmd2 )

          Svg.Comments.HideExpandedComment ->
            defaultBehavior
              { model
              | work = Utils.Work.removeWork promptAnswering model.work
              , reply_comment = ""
              }

          Svg.Comments.ExpandComment _ ->
            defaultBehavior
              { model
              | avatar = Nothing
              }

          _ ->
            defaultBehavior model

    -- Elements/Profile
    ProfileMsg profile_msg ->
      ( model, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
  case model.comments of
    Utils.Types.CommentsForPostNotReady ->
      createCommentsForPostReadyBlock model model.post_id model.page_index

    Utils.Types.CommentsForPostReady post_id page_index ->
      createCommentsForPostReadyBlock model post_id page_index

    Utils.Types.CommentsForPostLoading post_id page_index ->
      createCommentsForPostLoadingBlock model

    Utils.Types.CommentsForPostLoaded post_comments ->
      createCommentsForPostLoadedBlock model post_comments


viewCommentsHeader : Model -> Html.Html Msg
viewCommentsHeader model =
  case model.comments of
    Utils.Types.CommentsForPostLoaded post_comments ->
      let
        total_comments = countAllComments post_comments |> String.fromInt
      in
        Html.h1
          []
          [ Html.text ( "Comments (" ++ total_comments ++ ")" ) ]

    _ ->
      Html.h1
        []
        [ Html.text "Comments" ]


viewNewCommentArea : Model -> Html.Html Msg
viewNewCommentArea model =
  let
    is_submitting_comment =
      Utils.Work.isWorkingOn submittingComment model.work

    loading_html =
      if is_submitting_comment then 
        Html.span
          [ Html.Attributes.class "loadingdotsafter" ]
          [ Html.text " Submitting for review" ]

      else
        Html.span
          []
          []

  in
    if model.is_logged_in then
      Html.div
        [ Html.Attributes.class "post-comment-textarea-container" ]
        [ Html.div
            []
            [ Html.textarea
                [ Html.Attributes.value model.new_comment
                , Html.Attributes.class "post-comment-textarea"
                , Html.Attributes.placeholder "New comment"
                , Html.Attributes.disabled is_submitting_comment
                , Html.Events.onInput TypingComment
                ]
                []
            ]

        , Html.div
            []
            [ Html.input
                [ Html.Attributes.type_ "button"
                , Html.Attributes.class "btn-create"
                , Html.Attributes.value "Submit"
                , Html.Attributes.disabled is_submitting_comment
                , Html.Events.onClick SubmitComment
                ]
                []

            , loading_html
            ]
        ]

    else
      Html.div
        []
        [ Html.a
            [ Html.Attributes.href Utils.Routes.signIn ]
            [ Html.text "Sign in to comment" ]
        ]



-- MISC

-- MISC VIEW


createCommentsForPostLoadingBlock : Model -> Html.Html Msg
createCommentsForPostLoadingBlock model =
  createCommentsBlock
  model
  ( Html.span
      [ Html.Attributes.class "loadingdotsafter" ]
      [ Html.text "Loading comments" ]
  )


createCommentsBlock : Model -> Html.Html Msg -> Html.Html Msg
createCommentsBlock model html =
  let
    comment_area =
      if Utils.Work.isWorkingOn reviewingComment model.work then
        []
      else
        [ viewNewCommentArea model ]

  in
    Html.div
      []
      ( List.concat
          [ [ viewCommentsHeader model
            , Utils.Css.svgStyles model.svg_comments
            ]

          , comment_area

          , [ Html.hr [] []
            , html
            ]
          ]
      )


createCommentsForPostReadyBlock : Model -> String -> Int -> Html.Html Msg
createCommentsForPostReadyBlock model post_id page_index =
  createCommentsBlock
    model
    ( Html.input
        [ Html.Attributes.type_ "button"
        , Html.Attributes.value "Load comments"
        , Html.Events.onClick LoadComments
        ]
        []
    )


createCommentsForPostLoadedBlock : Model -> List Utils.Types.PostComment -> Html.Html Msg
createCommentsForPostLoadedBlock model post_comments =
  if 0 < List.length post_comments then
    Html.div
      []
      [ createFullCommentsBlock model ]

  else
    createEmptyCommentsBlock model


createFullCommentsBlock : Model -> Html.Html Msg
createFullCommentsBlock model =
  let
    focused_comment_index =
      Svg.Comments.getFocusedCommentIndex model.svg_comments.focused_comment

    is_root_axis = 1 == List.length model.svg_comments.focused_comment

    is_horizontal =
      model.svg_comments.orientation ==
        Utils.Types.SvgCommentsOrientationHorizontal

    is_vertical = not is_horizontal

    is_sqm_top_corner =
      model.svg_comments.confs.sqm_y == 0 ||
      is_horizontal

    is_sqm_left_corner =
      model.svg_comments.confs.sqm_x == 0 ||
      is_vertical

    is_prompting_reply = Utils.Work.isWorkingOn promptAnswering model.work

    is_replying_comment = Utils.Work.isWorkingOn replyingComment model.work

    svg_comments_loading = Utils.Work.isWorking model.svg_comments.work

    is_reviewing_comment = Utils.Work.isWorkingOn reviewingComment model.work

    is_getting_avatar = Utils.Work.isWorkingOn gettingAvatar model.work

    arrow_up_placeholder =
      if is_vertical then
        if is_root_axis then
          if focused_comment_index == 0 then
            ""
          else
            "Previous comment"
        else
          if focused_comment_index == 0 then
            "Parent comment"
          else
            "Previous comment"
      else
        ""

    arrow_right_placeholder =
      if is_vertical then
        "Next reply to comment"
      else
        "Next comment"

    arrow_down_placeholder =
      if is_vertical then
        "Next comment"
      else
        "Next reply to comment"

    arrow_left_placeholder =
      if is_vertical then
        ""
      else if focused_comment_index == 0 then
        "Parent comment"
      else
        "Previous comment"

    comment_block =
      case model.svg_comments.expanded_comment of
        Just comment ->
          CommentBlock
            -- close_expanded_comment
            [ Html.input
              [ Html.Attributes.type_ "button"
              , Html.Attributes.value "X"
              , Html.Attributes.title "Hide comment"
              , Html.Attributes.class "btn-danger"
              , Html.Attributes.disabled
                  ( is_replying_comment || is_getting_avatar )
              , Html.Events.onClick
                  ( SvgCommentsMsg Svg.Comments.HideExpandedComment )
              ]
              []
            ]
            -- arrow_up
            [ Html.div
                []
                [ Html.text comment.author_name ]
            ]
            -- load_comments
            [ if Utils.Funcs.isNothing model.avatar then
                Html.input
                  [ Html.Attributes.type_ "button"
                  , Html.Attributes.value "A"
                  , Html.Attributes.title "Show avatar"
                  , Html.Attributes.disabled
                      ( is_replying_comment || is_getting_avatar )
                  , Html.Events.onClick ShowAvatar
                  ]
                  []

              else
                Html.input
                  [ Html.Attributes.type_ "button"
                  , Html.Attributes.value "H"
                  , Html.Attributes.title "Hide avatar"
                  , Html.Events.onClick HideAvatar
                  ]
                  []
            ]
            -- arrow_left
            []
            -- content
            ( if is_getting_avatar then
                [ Html.div
                    [ Html.Attributes.class "loadingdotsafter" ]
                    [ Html.text "Fetching avatar" ]
                ]
              else
                case model.avatar of
                  Just drawing_cmds ->
                    let
                      profile_model = Elements.Profile.initModel
                    in
                      [ Elements.Profile.viewWebGlAvatarProfile
                          { profile_model
                          | final_avatar = drawing_cmds
                          }
                        |> Html.map ProfileMsg
                      ]

                  Nothing ->
                    [ Html.div
                        [ Html.Attributes.class "expanded-comment" ]
                        [ Html.text comment.message ]
                    , Svg.Comments.view model.svg_comments
                        |> Html.map SvgCommentsMsg
                    ]
            )
            -- arrow_right
            []
            -- cancel_reply
            (
              if is_prompting_reply then
                [ Html.input
                    [ Html.Attributes.value "C"
                    , Html.Attributes.type_ "button"
                    , Html.Attributes.title "Cancel reply"
                    , Html.Attributes.disabled
                        ( is_replying_comment || is_getting_avatar )
                    , Html.Events.onClick CancelPromptReply
                    ]
                    []
                ]
              else
                []
            )
            -- arrow_down
            (
              if is_replying_comment then
                [ Html.div
                    [ Html.Attributes.class "loadingdotsafter" ]
                    [ Html.text "Submitting to review" ]
                ]
              else if is_prompting_reply then
                [ Html.textarea
                    [ Html.Attributes.value model.reply_comment
                    , Html.Attributes.class "post-comment-textarea"
                    , Html.Attributes.disabled
                        ( is_replying_comment || is_getting_avatar )
                    , Html.Events.onInput TypingReply
                    ]
                    []
                ]
              else
                [ Html.div
                    []
                    [ Html.text "Posted "
                    , Utils.Funcs.iso8601HumanDateDiff
                        model.date_time
                        comment.created_at
                          |> Html.text
                    ]
                ]
            )
            -- reply_to_comment
            (
              if is_prompting_reply then
                [ Html.input
                    [ Html.Attributes.value "S"
                    , Html.Attributes.title "Send reply"
                    , Html.Attributes.class "btn-create"
                    , Html.Attributes.type_ "button"
                    , Html.Attributes.disabled
                        ( is_replying_comment || is_getting_avatar )
                    , Html.Events.onClick SubmitReplyComment
                    ]
                    []
                ]
              else if model.is_logged_in && Utils.Funcs.isNothing model.avatar then
                [ Html.input
                    [ Html.Attributes.value "R"
                    , Html.Attributes.title "Reply"
                    , Html.Attributes.type_ "button"
                    , Html.Attributes.disabled
                        ( is_replying_comment || is_getting_avatar )
                    , Html.Events.onClick PromptReplyComment
                    ]
                    []
                ]
              else
                []
            )

        Nothing ->
          CommentBlock
            -- close_expanded_comment
            []
            -- arrow_up
            [ Html.input
                [ Html.Attributes.value "↑"
                , Html.Attributes.type_ "button"
                , Html.Attributes.title arrow_up_placeholder
                , Html.Attributes.disabled is_sqm_top_corner
                , Html.Events.onClick
                    <| SvgCommentsMsg ( Svg.Comments.SetViewport 0 1 )
                ]
                []
            ]
            -- load_comments
            ( if svg_comments_loading || is_reviewing_comment then
                []
              else
                [ Html.input
                  [ Html.Attributes.value "L"
                  , Html.Attributes.title "Load comments"
                  , Html.Attributes.type_ "button"
                  , Html.Events.onClick LoadComments
                  ]
                  []
                ]
            )
            -- arrow_left
            [ Html.input
                [ Html.Attributes.value "←"
                , Html.Attributes.title arrow_left_placeholder
                , Html.Attributes.type_ "button"
                , Html.Attributes.disabled is_sqm_left_corner
                , Html.Events.onClick
                    <| SvgCommentsMsg ( Svg.Comments.SetViewport -1 0 )
                ]
                []
            ]
            -- content
            [ Svg.Comments.view model.svg_comments
                |> Html.map SvgCommentsMsg
            ]
            -- arrow_right
            [ Html.input
                [ Html.Attributes.value "→"
                , Html.Attributes.title arrow_right_placeholder
                , Html.Attributes.type_ "button"
                , Html.Events.onClick
                    <| SvgCommentsMsg ( Svg.Comments.SetViewport 1 0 )
                ]
                []
            ]
            -- cancel_reply
            []
            -- arrow_down
            [ Html.input
                [ Html.Attributes.value "↓"
                , Html.Attributes.title arrow_down_placeholder
                , Html.Attributes.type_ "button"
                , Html.Events.onClick
                    <| SvgCommentsMsg ( Svg.Comments.SetViewport 0 -1 )
                ]
                []
            ]
            -- reply_to_comment
            []

  in
    createCommentsBlock
      model
      ( Html.table
          [ Html.Attributes.class "postcomments"
          ]
          [ Html.thead [] []
          , Html.tbody
              []
              [ Html.tr
                  []
                  [ Html.td
                      []
                      comment_block.close_expanded_comment

                  , Html.td
                      [ Html.Attributes.class "postcomments-author" ]
                      comment_block.arrow_up

                  , Html.td
                      []
                      comment_block.load_comments
                  ]
              , Html.tr
                  []
                  [ Html.td
                      []
                      comment_block.arrow_left

                  , Html.td
                      [ Html.Attributes.class "postcomments-message" ]
                      comment_block.content

                  , Html.td
                      []
                      comment_block.arrow_right
                  ]
              , Html.tr
                  []
                  [ Html.td
                      []
                      comment_block.cancel_reply

                  , Html.td
                      [ Html.Attributes.class "postcomments-replies" ]
                      comment_block.arrow_down

                  , Html.td
                      []
                      comment_block.reply_to_comment
                  ]
              ]
          , Html.tfoot [] []
          ]
      )


createEmptyCommentsBlock : Model -> Html.Html Msg
createEmptyCommentsBlock model =
  createCommentsBlock
    model
    ( Html.text "List.isEmpty, be the List.head" )



-- MISC MODEL


resetComments : String -> Int -> Model -> Model
resetComments post_id page_index model =
  { model
  | comments = Utils.Types.CommentsForPostReady post_id page_index
  }


updateModelSvgCommentsModel : Utils.Types.SvgCommentsModel -> Model -> Model
updateModelSvgCommentsModel new_svg_comments model =
  { model | svg_comments = new_svg_comments }



-- MISC RECURSIVE UPDATE


getFocusedComment : Model -> Maybe Utils.Types.PostComment
getFocusedComment model =
  let
    iter : List Int -> List Utils.Types.PostComment -> Maybe Utils.Types.PostComment
    iter track comments =
      case track of
        index :: thead :: ttail ->
          case List.drop thead comments |> List.head of
            Just comment ->
              case comment.replies of
                Utils.Types.PostCommentReplies replies ->
                  iter
                    ( index :: ttail )
                    replies

            Nothing ->
              Nothing

        index :: [] ->
          List.drop index comments |> List.head

        [] ->
          Nothing

  in
    case model.comments of
      Utils.Types.CommentsForPostLoaded comments ->
        iter model.svg_comments.focused_comment comments

      _ ->
        Nothing


appendPostCommentsAfter : List Utils.Types.PostComment -> Model -> Model
appendPostCommentsAfter post_comments_ model =
  let
    iter : List Int -> Utils.Types.CommentsForPost -> List Utils.Types.PostComment -> Utils.Types.CommentsForPost
    iter track comments_for_post post_comments =
      case comments_for_post of
        Utils.Types.CommentsForPostLoaded comments ->
          case track of
            index :: thead :: ttail ->
              case List.drop thead comments |> List.head of
                Just comment ->
                  case comment.replies of
                    Utils.Types.PostCommentReplies replies_ ->
                      let
                        new_pc =
                          iter
                            ( index :: ttail )
                            ( Utils.Types.CommentsForPostLoaded replies_ )
                            post_comments

                      in
                        case new_pc of
                          Utils.Types.CommentsForPostLoaded new_replies ->
                            Utils.Types.CommentsForPostLoaded
                              ( List.concat
                                  [ List.take thead comments
                                  , [ { comment
                                      | replies =
                                          Utils.Types.PostCommentReplies
                                            new_replies
                                      }
                                    ]
                                  , List.drop ( 1 + thead ) comments
                                  ]
                              )

                          _ ->
                            new_pc

                Nothing ->
                  comments_for_post

            _ :: [] ->
              Utils.Types.CommentsForPostLoaded 
                ( List.append comments post_comments )

            [] ->
              comments_for_post

        _ ->
          comments_for_post

  in
    if List.length post_comments_ > 0 then
      { model
      | comments =
          iter
            model.svg_comments.focused_comment
            model.comments
            post_comments_
      }
    else
      model


appendPostCommentsReplies : List Utils.Types.PostComment -> Model -> Model
appendPostCommentsReplies replies_ model =
  let
    iter : List Int -> Utils.Types.CommentsForPost -> List Utils.Types.PostComment -> Utils.Types.CommentsForPost
    iter track data replies =
      case data of
        Utils.Types.CommentsForPostLoaded post_comments ->
          case track of
            index :: thead :: ttail ->
              case List.drop thead post_comments |> List.head of
                Just post_comment ->
                  case post_comment.replies of
                    Utils.Types.PostCommentReplies pc_replies ->
                      let
                        new_d =
                          iter
                            ( index :: ttail )
                            ( Utils.Types.CommentsForPostLoaded pc_replies )
                            replies

                      in
                        case new_d of
                          Utils.Types.CommentsForPostLoaded new_replies ->
                            Utils.Types.CommentsForPostLoaded
                              ( List.concat
                                  [ List.take thead post_comments
                                  , [ { post_comment
                                      | replies =
                                          Utils.Types.PostCommentReplies
                                            new_replies
                                      }
                                    ]
                                  , List.drop ( 1 + thead ) post_comments
                                  ]
                              )

                          _ ->
                            new_d

                Nothing ->
                  data

            index :: [] ->
              case List.drop index post_comments |> List.head of
                Just post_comment ->
                  case post_comment.replies of
                    Utils.Types.PostCommentReplies pc_replies ->
                      let
                        post_comment2 =
                          { post_comment
                          | replies =
                              Utils.Types.PostCommentReplies
                                ( List.append pc_replies replies )
                          }

                      in
                        Utils.Types.CommentsForPostLoaded
                          ( List.concat
                              [ List.take index post_comments
                              , [ post_comment2 ]
                              , List.drop ( 1 + index ) post_comments
                              ]
                          )

                Nothing ->
                  data

            _ ->
              data

        _ ->
          data

  in
    { model
    | comments =
        iter model.svg_comments.focused_comment model.comments replies_
    }



-- MISC WORK


promptAnswering : Int
promptAnswering = 1


submittingComment : Int
submittingComment = 2


replyingComment : Int
replyingComment = 4


reviewingComment : Int
reviewingComment = 8


gettingAvatar : Int
gettingAvatar = 16



-- MISC COUNTERS


countAllComments : List Utils.Types.PostComment -> Int 
countAllComments post_comments =
  case List.head post_comments of
    Just post_comment ->
      case post_comment.replies of
        Utils.Types.PostCommentReplies replies ->
          1 +
          ( List.drop 1 post_comments |> countAllComments ) + 
          ( countAllComments replies )

    Nothing ->
      0



-- MISC SVG/COMMENTS WORK


addWorkToSvgComments : Int -> Model -> Model
addWorkToSvgComments work model =
  let
    old_svg_comments = model.svg_comments
    new_svg_comments =
      { old_svg_comments
      | work = Utils.Work.addWork work old_svg_comments.work
      }
  in
    { model | svg_comments = new_svg_comments }


removeWorkFromSvgComments : Int -> Model -> Model
removeWorkFromSvgComments work model =
  let
    old_svg_comments = model.svg_comments
    new_svg_comments =
      { old_svg_comments
      | work = Utils.Work.removeWork work old_svg_comments.work
      }
  in
    { model | svg_comments = new_svg_comments }



